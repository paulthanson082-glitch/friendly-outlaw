import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - ProspectDatabase

/// In-memory database for tracking writing prospects: publishers, agents, clients, collaborators.
public class ProspectDatabase {
    private var prospects: [UUID: Prospect] = [:]

    public init() {}

    /// Adds or replaces a prospect in the in-memory store keyed by its `id`.
    /// - Parameter prospect: The `Prospect` to store; if an entry with the same `id` exists it will be overwritten.

    public func addProspect(_ prospect: Prospect) {
        prospects[prospect.id] = prospect
    }

    /// Retrieves a prospect by its identifier.
    /// - Parameter id: The UUID of the prospect to retrieve.
    /// - Returns: The `Prospect` with the given identifier, or `nil` if no matching prospect exists.
    public func getProspect(id: UUID) -> Prospect? {
        return prospects[id]
    }

    /// Retrieve all stored prospects sorted by creation date, newest first.
    /// - Returns: An array of `Prospect` objects sorted by `createdAt` in descending order (newest first).
    public func getAllProspects() -> [Prospect] {
        return Array(prospects.values).sorted { $0.createdAt > $1.createdAt }
    }

    /// Retrieve all prospects with the given status, sorted by creation date descending.
    /// - Parameter status: The prospect status to filter by.
    /// - Returns: An array of `Prospect` objects whose `status` equals `status`, ordered by `createdAt` descending.
    public func getProspects(withStatus status: ProspectStatus) -> [Prospect] {
        return getAllProspects().filter { $0.status == status }
    }

    /// Inserts or replaces a prospect in the in-memory store using the prospect's `id`.
    /// - Parameter prospect: The `Prospect` to store; if a prospect with the same `id` exists it will be overwritten.
    public func updateProspect(_ prospect: Prospect) {
        prospects[prospect.id] = prospect
    }

    /// Update the status of the prospect identified by `id`.
    /// 
    /// If the new `status` is `.contacted`, `.replied`, or `.meeting`, the prospect's `lastContactedAt` is set to the current date. The updated prospect is written back to the in-memory store.
    /// - Throws: `CoworkError.prospectNotFound(id)` if no prospect exists with the provided `id`.
    public func updateProspectStatus(id: UUID, status: ProspectStatus) throws {
        guard var prospect = prospects[id] else {
            throw CoworkError.prospectNotFound(id)
        }
        prospect.status = status
        if status == .contacted || status == .replied || status == .meeting {
            prospect.lastContactedAt = Date()
        }
        prospects[id] = prospect
    }

    /// Removes the prospect with the specified identifier from the in-memory store.
    /// - Parameter id: The UUID of the prospect to remove.
    public func deleteProspect(id: UUID) {
        prospects.removeValue(forKey: id)
    }

    /// Searches stored prospects for records matching the given query across name, email, company, notes, and tags.
    /// - Parameters:
    ///   - query: The search term matched case-insensitively against name, email, optional company, notes, and each tag.
    /// - Returns: An array of `Prospect` objects whose fields contain `query` (case-insensitive). Results preserve the aggregate ordering from `getAllProspects()` (createdAt descending).
    public func searchProspects(query: String) -> [Prospect] {
        let q = query.lowercased()
        return getAllProspects().filter {
            $0.name.lowercased().contains(q) ||
            $0.email.lowercased().contains(q) ||
            ($0.company?.lowercased().contains(q) ?? false) ||
            $0.notes.lowercased().contains(q) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    /// Computes the number of stored prospects grouped by their status.
    /// - Returns: A dictionary mapping each `ProspectStatus` (every case from `ProspectStatus.allCases`) to the number of prospects currently in that status; statuses with no matching prospects have a value of `0`.

    public func getStats() -> [ProspectStatus: Int] {
        var counts: [ProspectStatus: Int] = [:]
        for status in ProspectStatus.allCases {
            counts[status] = 0
        }
        for prospect in prospects.values {
            counts[prospect.status, default: 0] += 1
        }
        return counts
    }
}

// MARK: - GmailService

/// Gmail API client. Authenticates via OAuth 2.0 bearer token supplied at init time.
/// Token must come from the caller (e.g. read from an environment variable in the CLI layer).
public class GmailService {
    private let oauthToken: String
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me"

    public init(oauthToken: String) {
        self.oauthToken = oauthToken
    }

    // MARK: List messages

    /// Fetch a list of messages from the inbox.
    /// - Parameters:
    ///   - maxResults: Maximum number of messages to fetch (default 20).
    /// Fetches a list of Gmail messages from the authenticated user's mailbox.
    /// - Parameters:
    ///   - maxResults: Maximum number of message metadata entries to request (also bounds how many full messages are fetched).
    ///   - query: Optional Gmail search query string (percent-encoded); when provided, the server filters messages by this query.
    /// - Returns: An array of `GmailMessage` objects for messages found (up to `maxResults`); individual messages that fail to fetch are skipped.
    /// - Throws: `CoworkError.invalidURL` if the request URL cannot be constructed; propagates errors thrown by the network request and message fetch operations.
    public func listMessages(maxResults: Int = 20, query: String? = nil) async throws -> [GmailMessage] {
        var urlString = "\(baseURL)/messages?maxResults=\(maxResults)"
        if let q = query, !q.isEmpty {
            let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
            urlString += "&q=\(encoded)"
        }
        guard let url = URL(string: urlString) else { throw CoworkError.invalidURL }

        let listData = try await performRequest(url: url, method: "GET")
        guard let json = try JSONSerialization.jsonObject(with: listData) as? [String: Any],
              let messageList = json["messages"] as? [[String: Any]] else {
            return []
        }

        var messages: [GmailMessage] = []
        for item in messageList.prefix(maxResults) {
            if let msgId = item["id"] as? String,
               let msg = try? await getMessage(id: msgId) {
                messages.append(msg)
            }
        }
        return messages
    }

    // MARK: Get single message

    /// Fetches a full Gmail message for the given message ID and returns it as a parsed `GmailMessage`.
    /// - Parameter id: The Gmail message identifier to retrieve.
    /// - Returns: The parsed `GmailMessage` corresponding to `id`.
    /// - Throws: `CoworkError.invalidURL` if the request URL cannot be constructed; `CoworkError.invalidOAuthToken` on a 401 response; `CoworkError.networkError` for other HTTP/network failures; or an error if the response cannot be parsed into a `GmailMessage`.
    public func getMessage(id: String) async throws -> GmailMessage {
        guard let url = URL(string: "\(baseURL)/messages/\(id)?format=full") else {
            throw CoworkError.invalidURL
        }
        let data = try await performRequest(url: url, method: "GET")
        return try parseMessage(data: data)
    }

    // MARK: Send message

    /// Send an email via Gmail.
    /// - Parameter draft: The composed email to send.
    /// Sends the provided draft via the Gmail API and returns the resulting message ID.
    /// - Parameter draft: The `GmailDraft` to send. If `draft.inReplyTo` is set, the sent message will include that thread ID.
    /// - Returns: The Gmail message ID of the sent message.
    /// - Throws: `CoworkError.invalidURL` if the send endpoint URL cannot be constructed.
    ///           `CoworkError.networkError` if the response format is unexpected or if the request fails with an HTTP/network error.
    @discardableResult
    public func sendMessage(draft: GmailDraft) async throws -> String {
        let rawMessage = buildRFC2822(draft: draft)
        var base64 = Data(rawMessage.utf8).base64EncodedString()
        base64 = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        var body: [String: Any] = ["raw": base64]
        if let replyTo = draft.inReplyTo {
            body["threadId"] = replyTo
        }

        guard let url = URL(string: "\(baseURL)/messages/send") else {
            throw CoworkError.invalidURL
        }
        let responseData = try await performRequest(url: url, method: "POST", body: body)
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let sentId = json["id"] as? String else {
            throw CoworkError.networkError("Unexpected send response format")
        }
        return sentId
    }

    // MARK: Mark as read

    /// Marks a Gmail message as read by removing the `UNREAD` label.
    /// - Parameter id: The Gmail message identifier to mark as read.
    /// - Throws: `CoworkError.invalidURL` if the modify endpoint URL cannot be constructed.
    ///           Propagates errors from the network request (e.g., authentication failures or HTTP errors).
    public func markAsRead(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/messages/\(id)/modify") else {
            throw CoworkError.invalidURL
        }
        let body: [String: Any] = ["removeLabelIds": ["UNREAD"]]
        _ = try await performRequest(url: url, method: "POST", body: body)
    }

    /// Constructs an RFC 2822-compliant message string from a `GmailDraft`.
    /// - Parameter draft: The draft containing `to`, `subject`, `body`, and optional `inReplyTo` to include as reply headers.
    /// - Returns: A CRLF-separated string containing the message headers followed by a blank line and the message body.

    private func buildRFC2822(draft: GmailDraft) -> String {
        var headers = [
            "To: \(draft.to)",
            "Subject: \(draft.subject)",
            "Content-Type: text/plain; charset=UTF-8"
        ]
        if let replyTo = draft.inReplyTo {
            headers.append("In-Reply-To: \(replyTo)")
            headers.append("References: \(replyTo)")
        }
        return (headers + ["", draft.body]).joined(separator: "\r\n")
    }

    /// Parses Gmail message JSON data and constructs a `GmailMessage`.
    /// - Returns: A `GmailMessage` populated from the JSON (id, threadId, subject, from, to, snippet, body, date, isRead, labels).
    /// - Throws: `CoworkError.networkError` if the provided data is not valid message JSON.
    private func parseMessage(data: Data) throws -> GmailMessage {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoworkError.networkError("Invalid message JSON")
        }

        let id = json["id"] as? String ?? ""
        let threadId = json["threadId"] as? String ?? ""
        let snippet = json["snippet"] as? String ?? ""
        let internalDate = (json["internalDate"] as? String).flatMap { Double($0) }
        let date = internalDate.map { Date(timeIntervalSince1970: $0 / 1000.0) } ?? Date()
        let labelIds = json["labelIds"] as? [String] ?? []
        let isRead = !labelIds.contains("UNREAD")

        var subject = ""
        var from = ""
        var to: [String] = []
        var body = ""

        if let payload = json["payload"] as? [String: Any] {
            if let headers = payload["headers"] as? [[String: Any]] {
                for header in headers {
                    let name = (header["name"] as? String ?? "").lowercased()
                    let value = header["value"] as? String ?? ""
                    switch name {
                    case "subject": subject = value
                    case "from":    from = value
                    case "to":      to = value.components(separatedBy: ",")
                                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    default: break
                    }
                }
            }
            body = extractBody(payload: payload)
        }

        return GmailMessage(
            id: id,
            threadId: threadId,
            subject: subject,
            from: from,
            to: to,
            snippet: snippet,
            body: body,
            date: date,
            isRead: isRead,
            labels: labelIds
        )
    }

    /// Extracts the plain-text message body from a Gmail message payload dictionary.
    /// 
    /// Attempts to read and base64url-decode the top-level `body.data`. If that is absent,
    /// iterates `parts` and returns the first part whose `mimeType` is `"text/plain"` and
    /// contains decodable `body.data`. If no decodable plain-text body is found, returns an empty string.
    /// - Parameter payload: A JSON-like payload dictionary from a Gmail message.
    /// - Returns: The decoded plain-text body, or an empty string if none is available.
    private func extractBody(payload: [String: Any]) -> String {
        if let bodySection = payload["body"] as? [String: Any],
           let encoded = bodySection["data"] as? String,
           let text = decodeBase64URL(encoded) {
            return text
        }
        if let parts = payload["parts"] as? [[String: Any]] {
            for part in parts {
                let mimeType = part["mimeType"] as? String ?? ""
                guard mimeType == "text/plain" else { continue }
                if let bodySection = part["body"] as? [String: Any],
                   let encoded = bodySection["data"] as? String,
                   let text = decodeBase64URL(encoded) {
                    return text
                }
            }
        }
        return ""
    }

    /// Decodes a base64url-encoded string into a UTF-8 string.
    /// - Parameter encoded: The input string using base64url encoding ( '-' and '_' variants, may be missing padding).
    /// - Returns: The decoded UTF-8 string, or `nil` if the input is not valid base64url or cannot be decoded as UTF-8.
    private func decodeBase64URL(_ encoded: String) -> String? {
        var padded = encoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = padded.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: padded) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Sends an HTTP request with the stored OAuth bearer token and returns the raw response data.
    /// - Parameters:
    ///   - url: The destination URL for the request.
    ///   - method: The HTTP method to use (for example, `"GET"` or `"POST"`).
    ///   - body: Optional JSON-serializable dictionary to include as the request body.
    /// - Returns: The response body as `Data`.
    /// - Throws:
    ///   - `CoworkError.invalidOAuthToken` if the server responds with HTTP 401.
    ///   - `CoworkError.networkError` with a message describing HTTP status and response body for any status code >= 400.
    private func performRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(oauthToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                throw CoworkError.invalidOAuthToken
            }
            if httpResponse.statusCode >= 400 {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CoworkError.networkError("HTTP \(httpResponse.statusCode): \(message)")
            }
        }
        return data
    }
}

// MARK: - BrowserService

/// Fetches web pages and extracts readable plain-text content for research.
public class BrowserService {
    private(set) public var history: [BrowsedPage] = []

    public init() {}

    // MARK: Fetch

    /// Fetch a URL and return its text content.
    /// Fetches a web page, extracts a readable title and plain-text content, and appends the result to the service history.
    ///
    /// The `urlString` must be a valid `http` or `https` URL. The response body is decoded into text (falling back from UTF-8 to ISO Latin-1 if needed), a title and stripped text content are produced, and a `BrowsedPage` is created and stored in `history`.
    /// - Parameter urlString: The URL to fetch as a string; must use the `http` or `https` scheme.
    /// - Returns: A `BrowsedPage` containing the requested URL, the extracted title, and the plain-text page content.
    /// - Throws: `CoworkError.invalidURL` if `urlString` is not a valid `http`/`https` URL; `CoworkError.browserFetchFailed(_)` if the HTTP response indicates a failure (status code >= 400).
    public func fetch(urlString: String) async throws -> BrowsedPage {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            throw CoworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (compatible; WritersApp/1.0)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw CoworkError.browserFetchFailed("HTTP \(httpResponse.statusCode)")
        }

        let rawHTML = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
        let title = extractHTMLTitle(from: rawHTML)
        let text = stripHTML(rawHTML)

        let page = BrowsedPage(url: urlString, title: title, textContent: text)
        history.append(page)
        return page
    }

    /// Clears the service's browsing history by removing all stored entries from `history`.
    public func clearHistory() {
        history.removeAll()
    }

    /// Extracts the content of the first <title>...</title> tag from the provided HTML string.
    /// - Parameter html: The raw HTML to search for a <title> tag.
    /// - Returns: The trimmed title text if found, otherwise "Untitled".

    private func extractHTMLTitle(from html: String) -> String {
        guard let titleStart = html.range(of: "<title", options: .caseInsensitive),
              let tagEnd = html.range(of: ">", range: titleStart.upperBound..<html.endIndex),
              let titleEnd = html.range(
                  of: "</title>",
                  options: .caseInsensitive,
                  range: tagEnd.upperBound..<html.endIndex
              ) else {
            return "Untitled"
        }
        return String(html[tagEnd.upperBound..<titleEnd.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Converts an HTML string into readable plain text by removing markup and normalizing whitespace.
    /// 
    /// The result preserves meaningful block breaks as newline-separated lines, decodes common HTML entities (e.g. `&amp;`, `&nbsp;`), and omits empty lines.
    /// - Parameter html: The HTML input to convert.
    /// - Returns: A plain-text string with tags removed, entities decoded, and consecutive whitespace collapsed into non-empty newline-separated lines.
    private func stripHTML(_ html: String) -> String {
        var text = html

        // Remove script, style, and head blocks entirely
        for tag in ["script", "style", "head"] {
            while let start = text.range(of: "<\(tag)", options: .caseInsensitive),
                  let end = text.range(
                      of: "</\(tag)>",
                      options: .caseInsensitive,
                      range: start.lowerBound..<text.endIndex
                  ) {
                text.removeSubrange(start.lowerBound...end.upperBound)
            }
        }

        // Replace block-level tags with newlines
        for tag in ["p", "div", "br", "h1", "h2", "h3", "h4", "h5", "h6", "li", "tr", "td", "th"] {
            text = text.replacingOccurrences(
                of: "<\(tag)[^>]*>", with: "\n", options: .regularExpression)
            text = text.replacingOccurrences(of: "</\(tag)>", with: "\n")
        }

        // Strip all remaining tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&nbsp;", " "),
            ("&mdash;", "—"), ("&ndash;", "–"), ("&hellip;", "…")
        ]
        for (entity, replacement) in entities {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        // Collapse whitespace — keep only non-empty lines
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: "\n")
    }
}
