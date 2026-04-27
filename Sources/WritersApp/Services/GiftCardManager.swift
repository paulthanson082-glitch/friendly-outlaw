import Foundation

public class GiftCardManager {
    private var bundles: [UUID: GiftCardBundle] = [:]
    private var giftCards: [UUID: GiftCard] = [:]
    private let databaseManager: DatabaseManager?

    public init(databaseManager: DatabaseManager? = nil) {
        self.databaseManager = databaseManager
    }

    // MARK: - Bundle CRUD

    /// Creates and stores a new gift card bundle.
    /// - Throws: `GiftCardError.invalidInput` if name is empty, aiCredits ≤ 0, or expirationDays ≤ 0.
    /// - Returns: The newly created `GiftCardBundle`.
    @discardableResult
    public func createBundle(
        name: String,
        description: String,
        price: Decimal,
        bundleType: BundleType,
        includedTemplateIds: [UUID] = [],
        aiCredits: Int,
        expirationDays: Int
    ) throws -> GiftCardBundle {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GiftCardError.invalidInput("Bundle name cannot be empty")
        }
        guard aiCredits > 0 else {
            throw GiftCardError.invalidInput("AI credits must be greater than 0")
        }
        guard expirationDays >= 0 else {
            throw GiftCardError.invalidInput("Expiration days must be greater than or equal to 0")
        }

        let bundle = GiftCardBundle(
            name: name,
            description: description,
            price: price,
            bundleType: bundleType,
            includedTemplateIds: includedTemplateIds,
            aiCredits: aiCredits,
            expirationDays: expirationDays
        )

        bundles[bundle.id] = bundle

        if let db = databaseManager {
            try db.insertGiftCardBundle(bundle)
        }

        return bundle
    }

    /// Returns the bundle matching `id`, or `nil` if none exists.
    public func getBundle(id: UUID) -> GiftCardBundle? {
        bundles[id]
    }

    /// Returns all bundles sorted newest-first by creation date.
    public func getAllBundles() -> [GiftCardBundle] {
        Array(bundles.values).sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Replaces the stored bundle and updates its modification timestamp.
    public func updateBundle(_ bundle: GiftCardBundle) throws {
        var updated = bundle
        updated.metadata = BundleMetadata(created: bundle.metadata.created, modified: Date())
        bundles[bundle.id] = updated

        if let db = databaseManager {
            try db.updateGiftCardBundle(updated)
        }
    }

    public func deleteBundle(id: UUID) throws {
        bundles.removeValue(forKey: id)
        let cardsToDelete = giftCards.values.filter { $0.bundleId == id }
        for card in cardsToDelete {
            giftCards.removeValue(forKey: card.id)
        }

        if let db = databaseManager {
            try db.deleteGiftCardBundle(id: id)
        }
    }

    // MARK: - Gift Card CRUD

    @discardableResult
    public func createGiftCard(bundleId: UUID) throws -> GiftCard {
        guard bundles[bundleId] != nil else {
            throw GiftCardError.bundleNotFound
        }

        let bundle = bundles[bundleId]!
        let code = generateUniqueCode()
        let expiresAt = Date().addingTimeInterval(Double(bundle.expirationDays) * 86400)
        let metadata = GiftCardMetadata(createdAt: Date(), expiresAt: expiresAt)

        let giftCard = GiftCard(
            code: code,
            bundleId: bundleId,
            status: .unused,
            metadata: metadata
        )

        giftCards[giftCard.id] = giftCard

        if let db = databaseManager {
            try db.insertGiftCard(giftCard)
        }

        return giftCard
    }

    public func getGiftCard(id: UUID) -> GiftCard? {
        giftCards[id]
    }

    public func getGiftCardByCode(_ code: String) -> GiftCard? {
        giftCards.values.first { $0.code == code }
    }

    public func getAllGiftCards() -> [GiftCard] {
        Array(giftCards.values).sorted { $0.metadata.createdAt > $1.metadata.createdAt }
    }

    public func updateGiftCard(_ card: GiftCard) throws {
        giftCards[card.id] = card

        if let db = databaseManager {
            try db.updateGiftCard(card)
        }
    }

    public func deleteGiftCard(id: UUID) throws {
        giftCards.removeValue(forKey: id)

        if let db = databaseManager {
            try db.deleteGiftCard(id: id)
        }
    }

    // MARK: - Redemption & Business Logic

    public func redeemGiftCard(code: String, userId: UUID) throws -> GiftCardBundle {
        guard let giftCard = getGiftCardByCode(code) else {
            throw GiftCardError.invalidCode
        }

        guard giftCard.status == .unused else {
            throw GiftCardError.alreadyRedeemed
        }

        guard let bundle = getBundle(id: giftCard.bundleId) else {
            throw GiftCardError.bundleNotFound
        }

        if isGiftCardExpired(giftCard) {
            throw GiftCardError.bundleExpired
        }

        var updatedCard = giftCard
        updatedCard.status = .redeemed
        updatedCard.redeemedByUserId = userId
        updatedCard.redeemedAt = Date()

        try updateGiftCard(updatedCard)

        return bundle
    }

    public func isGiftCardExpired(_ card: GiftCard) -> Bool {
        guard let expiresAt = card.metadata.expiresAt else {
            return false
        }
        return Date() > expiresAt
    }

    public func validateCode(_ code: String) throws {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw GiftCardError.invalidInput("Code cannot be empty")
        }

        guard getGiftCardByCode(code) != nil else {
            throw GiftCardError.invalidCode
        }
    }

    // MARK: - Statistics

    public func getGiftCardStats() -> GiftCardStats {
        let total = giftCards.count
        let redeemed = giftCards.values.filter { $0.status == .redeemed }.count
        let expired = giftCards.values.filter { isGiftCardExpired($0) }.count
        let unused = total - redeemed - expired

        return GiftCardStats(
            totalCards: total,
            redeemedCards: redeemed,
            expiredCards: expired,
            unusedCards: unused
        )
    }

    public func getBundleStats() -> BundleStats {
        let total = bundles.count
        var totalRevenue: Decimal = 0
        var bundlesByType: [String: Int] = [:]
        var totalAiCredits = 0

        for bundle in bundles.values {
            totalRevenue += bundle.price
            let typeKey = bundle.bundleType.displayName
            bundlesByType[typeKey, default: 0] += 1
            totalAiCredits += bundle.aiCredits
        }

        let avgCredits = total > 0 ? totalAiCredits / total : 0

        return BundleStats(
            totalBundles: total,
            totalRevenue: totalRevenue,
            bundlesByType: bundlesByType,
            averageAiCredits: avgCredits
        )
    }

    // MARK: - Private Helpers

    private func generateUniqueCode() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").uppercased()
        let prefix = String(uuid.prefix(3))
        let middle = String(uuid.dropFirst(3).prefix(6))
        let suffix = String(uuid.dropFirst(9).prefix(3))
        let code = "GC-\(prefix)\(middle)\(suffix)"

        if getGiftCardByCode(code) != nil {
            return generateUniqueCode()
        }

        return code
    }
}
