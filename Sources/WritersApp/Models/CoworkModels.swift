import Foundation

// MARK: - Prospect

/// A writing prospect — publisher, agent, client, or collaborator tracked by the solo founder.
public struct Prospect: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var email: String
    public var company: String?
    public var role: String?
    public var status: ProspectStatus
    public var notes: String
    public var tags: [String]
    public var lastContactedAt: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        company: String? = nil,
        role: String? = nil,
        status: ProspectStatus = .new,
        notes: String = "",
        tags: [String] = [],
        lastContactedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.company = company
        self.role = role
        self.status = status
        self.notes = notes
        self.tags = tags
        self.lastContactedAt = lastContactedAt
        self.createdAt = createdAt
    }
}

/// The current relationship status of a prospect
public enum ProspectStatus: String, Codable, CaseIterable {
    case new
    case contacted
    case replied
    case meeting
    case declined
    case converted

    public var displayName: String {
        switch self {
        case .new:       return "New"
        case .contacted: return "Contacted"
        case .replied:   return "Replied"
        case .meeting:   return "Meeting Scheduled"
        case .declined:  return "Declined"
        case .converted: return "Converted"
        }
    }
}

// MARK: - Gmail

/// A Gmail message fetched via the Gmail REST API.
public struct GmailMessage: Codable, Identifiable {
    public var id: String
    public var threadId: String
    public var subject: String
    public var from: String
    public var to: [String]
    public var snippet: String
    public var body: String
    public var date: Date
    public var isRead: Bool
    public var labels: [String]

    public init(
        id: String,
        threadId: String,
        subject: String,
        from: String,
        to: [String],
        snippet: String,
        body: String,
        date: Date,
        isRead: Bool = false,
        labels: [String] = []
    ) {
        self.id = id
        self.threadId = threadId
        self.subject = subject
        self.from = from
        self.to = to
        self.snippet = snippet
        self.body = body
        self.date = date
        self.isRead = isRead
        self.labels = labels
    }
}

/// A composed email ready to send via Gmail.
public struct GmailDraft: Codable, Identifiable {
    public var id: UUID
    public var to: String
    public var subject: String
    public var body: String
    public var inReplyTo: String?

    public init(
        id: UUID = UUID(),
        to: String,
        subject: String,
        body: String,
        inReplyTo: String? = nil
    ) {
        self.id = id
        self.to = to
        self.subject = subject
        self.body = body
        self.inReplyTo = inReplyTo
    }
}

// MARK: - Browser

/// A web page fetched and stripped to plain text for writing research.
public struct BrowsedPage: Codable, Identifiable {
    public var id: UUID
    public var url: String
    public var title: String
    public var textContent: String
    public var fetchedAt: Date

    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        textContent: String,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.textContent = textContent
        self.fetchedAt = fetchedAt
    }
}

// MARK: - Cowork Session

/// Tracks a single cowork session — a focused block where the founder works
/// across Gmail, prospects, and browser research.
public struct CoworkSession: Codable, Identifiable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var emailsSent: Int
    public var prospectsAdded: Int
    public var prospectsContacted: Int
    public var pagesResearched: Int

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        emailsSent: Int = 0,
        prospectsAdded: Int = 0,
        prospectsContacted: Int = 0,
        pagesResearched: Int = 0
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.emailsSent = emailsSent
        self.prospectsAdded = prospectsAdded
        self.prospectsContacted = prospectsContacted
        self.pagesResearched = pagesResearched
    }

    /// Duration in minutes if the session has ended.
    public var durationMinutes: Double? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt) / 60.0
    }
}

// MARK: - Errors

/// Errors thrown by the cowork service
public enum CoworkError: Error, LocalizedError {
    case gmailNotEnabled
    case invalidOAuthToken
    case prospectNotFound(UUID)
    case browserFetchFailed(String)
    case networkError(String)
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .gmailNotEnabled:
            return "Gmail is not enabled. Set GMAIL_OAUTH_TOKEN to activate."
        case .invalidOAuthToken:
            return "Gmail OAuth token is invalid or expired."
        case .prospectNotFound:
            return "Prospect not found."
        case .browserFetchFailed(let reason):
            return "Browser fetch failed: \(reason)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL:
            return "The URL is invalid."
        }
    }
}
