import Foundation

// MARK: - DealStage

/// The stage of a publishing deal in the submission pipeline
public enum DealStage: String, Codable, CaseIterable {
    case prospect     = "prospect"
    case queried      = "queried"
    case requested    = "requested"
    case submitted    = "submitted"
    case contracted   = "contracted"
    case rejected     = "rejected"

    public var displayName: String {
        switch self {
        case .prospect:    return "Prospect"
        case .queried:     return "Queried"
        case .requested:   return "Requested"
        case .submitted:   return "Submitted"
        case .contracted:  return "Contracted"
        case .rejected:    return "Rejected"
        }
    }

    /// Metal-themed section headers for the CRM dashboard
    public var metalName: String {
        switch self {
        case .prospect:    return "The Hunt"
        case .queried:     return "First Blood"
        case .requested:   return "Full Assault"
        case .submitted:   return "In the Pit"
        case .contracted:  return "Victory Lap"
        case .rejected:    return "Fallen"
        }
    }

    /// Returns the next active stage (does not advance past contracted or to rejected)
    public var next: DealStage? {
        switch self {
        case .prospect:   return .queried
        case .queried:    return .requested
        case .requested:  return .submitted
        case .submitted:  return .contracted
        case .contracted: return nil
        case .rejected:   return nil
        }
    }

    /// Whether this stage represents a terminal (won/lost) outcome
    public var isTerminal: Bool {
        self == .contracted || self == .rejected
    }
}

// MARK: - InteractionType

/// The type of a logged CRM interaction
public enum InteractionType: String, Codable, CaseIterable {
    case email      = "email"
    case call       = "call"
    case meeting    = "meeting"
    case submission = "submission"
    case note       = "note"

    public var displayName: String {
        switch self {
        case .email:      return "Email"
        case .call:       return "Call"
        case .meeting:    return "Meeting"
        case .submission: return "Submission"
        case .note:       return "Note"
        }
    }

    public var systemImageName: String {
        switch self {
        case .email:      return "envelope.fill"
        case .call:       return "phone.fill"
        case .meeting:    return "person.2.fill"
        case .submission: return "paperplane.fill"
        case .note:       return "note.text"
        }
    }
}

// MARK: - CRMContact

/// A contact in the publishing CRM — publishers, editors, agents, clients
public struct CRMContact: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var email: String?
    public var phone: String?
    public var company: String?
    /// Role in the publishing world, e.g. "Literary Agent", "Editor", "Publisher"
    public var role: String?
    public var tags: [String]
    public var notes: String
    public var metadata: CRMContactMetadata

    public init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        phone: String? = nil,
        company: String? = nil,
        role: String? = nil,
        tags: [String] = [],
        notes: String = "",
        metadata: CRMContactMetadata = CRMContactMetadata()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.company = company
        self.role = role
        self.tags = tags
        self.notes = notes
        self.metadata = metadata
    }
}

// MARK: - CRMContactMetadata

public struct CRMContactMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var lastContacted: Date?

    public init(
        created: Date = Date(),
        modified: Date = Date(),
        lastContacted: Date? = nil
    ) {
        self.created = created
        self.modified = modified
        self.lastContacted = lastContacted
    }
}

// MARK: - CRMDeal

/// A publishing opportunity — manuscript submission, pitch, or contract negotiation
public struct CRMDeal: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var contactId: UUID
    public var stage: DealStage
    /// Optional contract value (advance, fee, etc.)
    public var value: Double?
    /// Optional link to a document/manuscript in the app
    public var documentId: UUID?
    public var notes: String
    public var metadata: CRMDealMetadata

    public init(
        id: UUID = UUID(),
        title: String,
        contactId: UUID,
        stage: DealStage = .prospect,
        value: Double? = nil,
        documentId: UUID? = nil,
        notes: String = "",
        metadata: CRMDealMetadata = CRMDealMetadata()
    ) {
        self.id = id
        self.title = title
        self.contactId = contactId
        self.stage = stage
        self.value = value
        self.documentId = documentId
        self.notes = notes
        self.metadata = metadata
    }
}

// MARK: - CRMDealMetadata

public struct CRMDealMetadata: Codable {
    public var created: Date
    public var modified: Date
    public var closedAt: Date?
    public var expectedCloseDate: Date?

    public init(
        created: Date = Date(),
        modified: Date = Date(),
        closedAt: Date? = nil,
        expectedCloseDate: Date? = nil
    ) {
        self.created = created
        self.modified = modified
        self.closedAt = closedAt
        self.expectedCloseDate = expectedCloseDate
    }
}

// MARK: - CRMInteraction

/// A logged communication or touchpoint with a CRM contact
public struct CRMInteraction: Codable, Identifiable {
    public let id: UUID
    public var contactId: UUID
    public var dealId: UUID?
    public var type: InteractionType
    public var summary: String
    public var date: Date

    public init(
        id: UUID = UUID(),
        contactId: UUID,
        dealId: UUID? = nil,
        type: InteractionType,
        summary: String,
        date: Date = Date()
    ) {
        self.id = id
        self.contactId = contactId
        self.dealId = dealId
        self.type = type
        self.summary = summary
        self.date = date
    }
}

// MARK: - CRMStats

/// Aggregate statistics for the CRM dashboard
public struct CRMStats {
    public var totalContacts: Int
    public var totalDeals: Int
    public var activeDeals: Int
    public var contractedDeals: Int
    public var totalPipelineValue: Double
    public var dealsByStage: [DealStage: Int]
    public var recentInteractionCount: Int  // interactions in last 30 days

    public init(
        totalContacts: Int = 0,
        totalDeals: Int = 0,
        activeDeals: Int = 0,
        contractedDeals: Int = 0,
        totalPipelineValue: Double = 0,
        dealsByStage: [DealStage: Int] = [:],
        recentInteractionCount: Int = 0
    ) {
        self.totalContacts = totalContacts
        self.totalDeals = totalDeals
        self.activeDeals = activeDeals
        self.contractedDeals = contractedDeals
        self.totalPipelineValue = totalPipelineValue
        self.dealsByStage = dealsByStage
        self.recentInteractionCount = recentInteractionCount
    }
}
