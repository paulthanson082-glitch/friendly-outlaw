import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - ProspectDatabase

/// In-memory database for tracking writing prospects: publishers, agents, clients, collaborators.
public class ProspectDatabase {
    private var prospects: [UUID: Prospect] = [:]

    public init() {}

    // MARK: CRUD

    public func addProspect(_ prospect: Prospect) {
        prospects[prospect.id] = prospect
    }

    public func getProspect(id: UUID) -> Prospect? {
        return prospects[id]
    }

    public func getAllProspects() -> [Prospect] {
        return Array(prospects.values).sorted { $0.createdAt > $1.createdAt }
    }

    public func getProspects(withStatus status: ProspectStatus) -> [Prospect] {
        return getAllProspects().filter { $0.status == status }
    }

    public func updateProspect(_ prospect: Prospect) {
        prospects[prospect.id] = prospect
    }

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

    public func deleteProspect(id: UUID) {
        prospects.removeValue(forKey: id)
    }

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

    // MARK: Statistics

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
    ///   - query: Optional Gmail search query (e.g. `"from:agent@example.com"`).
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

    /// Fetch the full content of a specific message.
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
    /// - Returns: The sent message ID.
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

    /// Mark a message as read by removing the UNREAD label.
    public func markAsRead(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/messages/\(id)/modify") else {
            throw CoworkError.invalidURL
        }
        let body: [String: Any] = ["removeLabelIds": ["UNREAD"]]
        _ = try await performRequest(url: url, method: "POST", body: body)
    }

    // MARK: - Private helpers

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
    /// - Parameter urlString: The URL to fetch (must begin with http:// or https://).
    public func fetch(urlString: String) async throws -> BrowsedPage {
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            throw CoworkError.invalidURL
        }

        // Validate URL for SSRF safety
        let ssrfResult = NetworkSecurity.validateSSRFSafety(url: url)
        guard ssrfResult.isAllowed else {
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

    /// Clear the in-session browsing history.
    public func clearHistory() {
        history.removeAll()
    }

    // MARK: - HTML parsing helpers

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
