import Foundation

// MARK: - Enums

public enum GiftCardStatus: String, Codable, CaseIterable {
    case unused
    case redeemed
    case expired

    public var displayName: String {
        switch self {
        case .unused:
            return "Unused"
        case .redeemed:
            return "Redeemed"
        case .expired:
            return "Expired"
        }
    }
}

public enum BundleType: String, Codable, CaseIterable {
    case starter
    case professional
    case enterprise
    case custom

    public var displayName: String {
        switch self {
        case .starter:
            return "Starter"
        case .professional:
            return "Professional"
        case .enterprise:
            return "Enterprise"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Metadata Structures

public struct BundleMetadata: Codable {
    public let created: Date
    public let modified: Date

    public init(created: Date = Date(), modified: Date = Date()) {
        self.created = created
        self.modified = modified
    }
}

public struct GiftCardMetadata: Codable {
    public let createdAt: Date
    public let expiresAt: Date?

    public init(createdAt: Date = Date(), expiresAt: Date? = nil) {
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Gift Card Bundle

public struct GiftCardBundle: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var description: String
    public var price: Decimal
    public var bundleType: BundleType
    public var includedTemplateIds: [UUID]
    public var aiCredits: Int
    public var expirationDays: Int
    public var metadata: BundleMetadata

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        price: Decimal,
        bundleType: BundleType,
        includedTemplateIds: [UUID] = [],
        aiCredits: Int,
        expirationDays: Int,
        metadata: BundleMetadata = BundleMetadata()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.bundleType = bundleType
        self.includedTemplateIds = includedTemplateIds
        self.aiCredits = aiCredits
        self.expirationDays = expirationDays
        self.metadata = metadata
    }
}

// MARK: - Gift Card

public struct GiftCard: Codable, Identifiable {
    public let id: UUID
    public var code: String
    public var bundleId: UUID
    public var status: GiftCardStatus
    public var redeemedByUserId: UUID?
    public var redeemedAt: Date?
    public var metadata: GiftCardMetadata

    public init(
        id: UUID = UUID(),
        code: String,
        bundleId: UUID,
        status: GiftCardStatus = .unused,
        redeemedByUserId: UUID? = nil,
        redeemedAt: Date? = nil,
        metadata: GiftCardMetadata = GiftCardMetadata()
    ) {
        self.id = id
        self.code = code
        self.bundleId = bundleId
        self.status = status
        self.redeemedByUserId = redeemedByUserId
        self.redeemedAt = redeemedAt
        self.metadata = metadata
    }
}

// MARK: - Statistics

public struct GiftCardStats: Codable {
    public let totalCards: Int
    public let redeemedCards: Int
    public let expiredCards: Int
    public let unusedCards: Int
    public let redeemRate: Double

    public init(
        totalCards: Int = 0,
        redeemedCards: Int = 0,
        expiredCards: Int = 0,
        unusedCards: Int = 0
    ) {
        self.totalCards = totalCards
        self.redeemedCards = redeemedCards
        self.expiredCards = expiredCards
        self.unusedCards = unusedCards
        self.redeemRate = totalCards > 0 ? Double(redeemedCards) / Double(totalCards) : 0.0
    }
}

public struct BundleStats: Codable {
    public let totalBundles: Int
    public let totalRevenue: Decimal
    public let bundlesByType: [String: Int]
    public let averageAiCredits: Int

    public init(
        totalBundles: Int = 0,
        totalRevenue: Decimal = 0,
        bundlesByType: [String: Int] = [:],
        averageAiCredits: Int = 0
    ) {
        self.totalBundles = totalBundles
        self.totalRevenue = totalRevenue
        self.bundlesByType = bundlesByType
        self.averageAiCredits = averageAiCredits
    }
}
