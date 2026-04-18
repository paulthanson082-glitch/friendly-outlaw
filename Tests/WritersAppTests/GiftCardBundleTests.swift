import XCTest
@testable import WritersApp

final class GiftCardBundleTests: XCTestCase {
    var giftCardManager: GiftCardManager!
    var databaseManager: DatabaseManager!
    var testDatabasePath: String!

    override func setUp() {
        super.setUp()
        testDatabasePath = "/tmp/test_giftcard_\(UUID().uuidString).db"
        try? FileManager.default.removeItem(atPath: testDatabasePath)
        databaseManager = DatabaseManager(databasePath: testDatabasePath)
        try? databaseManager.initialize()
        giftCardManager = GiftCardManager(databaseManager: databaseManager)
    }

    override func tearDown() {
        super.tearDown()
        databaseManager.close()
        try? FileManager.default.removeItem(atPath: testDatabasePath)
    }

    // MARK: - Bundle CRUD Tests

    func testCreateGiftCardBundle() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Starter Pack",
            description: "Get started with WritersApp",
            price: 29.99,
            bundleType: .starter,
            aiCredits: 100,
            expirationDays: 365
        )

        XCTAssertEqual(bundle.name, "Starter Pack")
        XCTAssertEqual(bundle.bundleType, .starter)
        XCTAssertEqual(bundle.aiCredits, 100)
        XCTAssertEqual(bundle.expirationDays, 365)
    }

    func testCreateBundleInvalidInput() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "",
                description: "Invalid",
                price: 29.99,
                bundleType: .starter,
                aiCredits: 100,
                expirationDays: 365
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }

        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Valid",
                description: "Invalid",
                price: 29.99,
                bundleType: .starter,
                aiCredits: 0,
                expirationDays: 365
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }
    }

    func testGetBundle() throws {
        let created = try giftCardManager.createBundle(
            name: "Professional",
            description: "For professionals",
            price: 99.99,
            bundleType: .professional,
            aiCredits: 500,
            expirationDays: 365
        )

        let retrieved = giftCardManager.getBundle(id: created.id)
        XCTAssertEqual(retrieved?.id, created.id)
        XCTAssertEqual(retrieved?.name, "Professional")
    }

    func testUpdateBundle() throws {
        var bundle = try giftCardManager.createBundle(
            name: "Original",
            description: "Original description",
            price: 50.0,
            bundleType: .starter,
            aiCredits: 100,
            expirationDays: 365
        )

        bundle.name = "Updated"
        bundle.aiCredits = 200
        try giftCardManager.updateBundle(bundle)

        let updated = giftCardManager.getBundle(id: bundle.id)
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.aiCredits, 200)
    }

    func testDeleteBundle() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Deletable",
            description: "To be deleted",
            price: 10.0,
            bundleType: .custom,
            aiCredits: 50,
            expirationDays: 30
        )

        try giftCardManager.deleteBundle(id: bundle.id)
        let deleted = giftCardManager.getBundle(id: bundle.id)
        XCTAssertNil(deleted)
    }

    // MARK: - Gift Card CRUD Tests

    func testCreateGiftCard() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test Bundle",
            description: "Test",
            price: 29.99,
            bundleType: .starter,
            aiCredits: 100,
            expirationDays: 365
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)

        XCTAssertEqual(card.status, .unused)
        XCTAssertTrue(card.code.contains("GC-"))
        XCTAssertNil(card.redeemedByUserId)
        XCTAssertNotNil(card.metadata.expiresAt)
    }

    func testCreateGiftCardInvalidBundle() {
        XCTAssertThrowsError(
            try giftCardManager.createGiftCard(bundleId: UUID())
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }
    }

    func testGetGiftCard() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let created = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let retrieved = giftCardManager.getGiftCard(id: created.id)

        XCTAssertEqual(retrieved?.id, created.id)
        XCTAssertEqual(retrieved?.code, created.code)
    }

    func testGetGiftCardByCode() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let created = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let retrieved = giftCardManager.getGiftCardByCode(created.code)

        XCTAssertEqual(retrieved?.code, created.code)
    }

    func testGiftCardCodeUniqueness() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card1 = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let card2 = try giftCardManager.createGiftCard(bundleId: bundle.id)

        XCTAssertNotEqual(card1.code, card2.code)
    }

    // MARK: - Redemption Tests

    func testRedeemGiftCard() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Redemption Test",
            description: "Test redemption",
            price: 50.0,
            bundleType: .professional,
            aiCredits: 200,
            expirationDays: 30
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let userId = UUID()

        let redeemed = try giftCardManager.redeemGiftCard(code: card.code, userId: userId)

        XCTAssertEqual(redeemed.id, bundle.id)

        let updated = giftCardManager.getGiftCardByCode(card.code)
        XCTAssertEqual(updated?.status, .redeemed)
        XCTAssertEqual(updated?.redeemedByUserId, userId)
        XCTAssertNotNil(updated?.redeemedAt)
    }

    func testRedeemInvalidCode() {
        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: "INVALID", userId: UUID())
        ) { error in
            XCTAssertEqual(error as? GiftCardError, .invalidCode)
        }
    }

    func testRedeemAlreadyRedeemedCard() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let userId = UUID()

        try giftCardManager.redeemGiftCard(code: card.code, userId: userId)

        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())
        ) { error in
            XCTAssertEqual(error as? GiftCardError, .alreadyRedeemed)
        }
    }

    // MARK: - Expiration Tests

    func testGiftCardExpiration() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Expiration Test",
            description: "Test expiration",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 0
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let isExpired = giftCardManager.isGiftCardExpired(card)

        XCTAssertTrue(isExpired)
    }

    func testRedeemExpiredCard() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Expired",
            description: "Already expired",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 0
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)

        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())
        ) { error in
            XCTAssertEqual(error as? GiftCardError, .bundleExpired)
        }
    }

    // MARK: - Statistics Tests

    func testGiftCardStats() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card1 = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let card2 = try giftCardManager.createGiftCard(bundleId: bundle.id)

        try giftCardManager.redeemGiftCard(code: card1.code, userId: UUID())

        let stats = giftCardManager.getGiftCardStats()

        XCTAssertEqual(stats.totalCards, 2)
        XCTAssertEqual(stats.redeemedCards, 1)
        XCTAssertEqual(stats.unusedCards, 1)
    }

    func testBundleStats() throws {
        let starterBundle = try giftCardManager.createBundle(
            name: "Starter",
            description: "Starter",
            price: 29.99,
            bundleType: .starter,
            aiCredits: 100,
            expirationDays: 365
        )

        let proBundle = try giftCardManager.createBundle(
            name: "Professional",
            description: "Professional",
            price: 99.99,
            bundleType: .professional,
            aiCredits: 500,
            expirationDays: 365
        )

        let stats = giftCardManager.getBundleStats()

        XCTAssertEqual(stats.totalBundles, 2)
        XCTAssertEqual(stats.totalRevenue, 129.98)
        XCTAssertEqual(stats.bundlesByType["Starter"], 1)
        XCTAssertEqual(stats.bundlesByType["Professional"], 1)
    }

    func testValidateCode() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)

        XCTAssertNoThrow(try giftCardManager.validateCode(card.code))

        XCTAssertThrowsError(
            try giftCardManager.validateCode("")
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }

        XCTAssertThrowsError(
            try giftCardManager.validateCode("NONEXISTENT")
        ) { error in
            XCTAssertEqual(error as? GiftCardError, .invalidCode)
        }
    }

    // MARK: - Database Integration Tests

    func testBundlePersistence() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Persistent",
            description: "Should persist",
            price: 99.99,
            bundleType: .enterprise,
            aiCredits: 1000,
            expirationDays: 730
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertEqual(retrieved?.name, "Persistent")
        XCTAssertEqual(retrieved?.bundleType, .enterprise)
    }

    func testGiftCardPersistence() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)

        let retrieved = try databaseManager.getGiftCard(id: card.id)
        XCTAssertEqual(retrieved?.code, card.code)
        XCTAssertEqual(retrieved?.status, .unused)
    }

    func testRedemptiondAuditTrail() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )

        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let userId = UUID()

        try giftCardManager.redeemGiftCard(code: card.code, userId: userId)

        let retrieved = try databaseManager.getGiftCard(id: card.id)
        XCTAssertEqual(retrieved?.redeemedByUserId, userId)
        XCTAssertNotNil(retrieved?.redeemedAt)
    }

    // MARK: - Expiration Days Boundary Tests (expirationDays > 0 enforcement)

    func testCreateBundleWithZeroExpirationDaysThrows() {
        // expirationDays == 0 was previously allowed (>= 0) but is now rejected (> 0)
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Zero Expiry",
                description: "Should fail",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: 0
            )
        ) { error in
            guard case GiftCardError.invalidInput(let msg) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertTrue(msg.contains("Expiration days must be greater than 0"))
        }
    }

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Negative Expiry",
                description: "Should fail",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: -1
            )
        ) { error in
            guard case GiftCardError.invalidInput(let msg) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertTrue(msg.contains("Expiration days must be greater than 0"))
        }
    }

    func testCreateBundleWithOneExpirationDaySucceeds() throws {
        // 1 is the minimum valid value after the > 0 change
        let bundle = try giftCardManager.createBundle(
            name: "Min Expiry",
            description: "One day expiry",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    func testCreateBundleWithLargeExpirationDaysSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Long Expiry",
            description: "Multi-year expiry",
            price: 99.99,
            bundleType: .enterprise,
            aiCredits: 1000,
            expirationDays: 3650
        )
        XCTAssertEqual(bundle.expirationDays, 3650)
    }

    // MARK: - GiftCardError Pattern Matching Tests (Equatable removed)

    func testGiftCardErrorInvalidCodePatternMatch() {
        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: "DOES-NOT-EXIST", userId: UUID())
        ) { error in
            guard case GiftCardError.invalidCode = error else {
                XCTFail("Expected GiftCardError.invalidCode, got \(error)")
                return
            }
        }
    }

    func testGiftCardErrorAlreadyRedeemedPatternMatch() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Double Redeem",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )
        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())

        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())
        ) { error in
            guard case GiftCardError.alreadyRedeemed = error else {
                XCTFail("Expected GiftCardError.alreadyRedeemed, got \(error)")
                return
            }
        }
    }

    func testGiftCardErrorBundleNotFoundPatternMatch() {
        XCTAssertThrowsError(
            try giftCardManager.createGiftCard(bundleId: UUID())
        ) { error in
            guard case GiftCardError.bundleNotFound = error else {
                XCTFail("Expected GiftCardError.bundleNotFound, got \(error)")
                return
            }
        }
    }

    func testGiftCardErrorInvalidCodeDescription() {
        let error = GiftCardError.invalidCode
        XCTAssertEqual(error.errorDescription, "Gift card code is invalid or not found")
        XCTAssertEqual(error.recoverySuggestion, "Please check the gift card code and try again")
    }

    func testGiftCardErrorBundleExpiredDescription() {
        let error = GiftCardError.bundleExpired
        XCTAssertEqual(error.errorDescription, "Gift card bundle has expired")
        XCTAssertEqual(error.recoverySuggestion, "This gift card bundle has expired and can no longer be redeemed")
    }

    func testGiftCardErrorAlreadyRedeemedDescription() {
        let error = GiftCardError.alreadyRedeemed
        XCTAssertEqual(error.errorDescription, "Gift card has already been redeemed")
        XCTAssertEqual(error.recoverySuggestion, "This gift card has already been redeemed")
    }

    func testGiftCardErrorBundleNotFoundDescription() {
        let error = GiftCardError.bundleNotFound
        XCTAssertEqual(error.errorDescription, "Bundle associated with this gift card was not found")
        XCTAssertEqual(error.recoverySuggestion, "The bundle associated with this gift card no longer exists")
    }

    func testGiftCardErrorInvalidInputDescription() {
        let message = "AI credits must be greater than 0"
        let error = GiftCardError.invalidInput(message)
        XCTAssertEqual(error.errorDescription, "Invalid input: \(message)")
        XCTAssertEqual(error.recoverySuggestion, "Please provide valid input")
    }

    func testGiftCardErrorDatabaseErrorDescription() {
        let message = "Connection failed"
        let error = GiftCardError.databaseError(message)
        XCTAssertEqual(error.errorDescription, "Database error: \(message)")
        XCTAssertEqual(error.recoverySuggestion, "Please try again later")
    }

    func testGiftCardErrorIsError() {
        // Verify GiftCardError conforms to Error and LocalizedError
        let error: Error = GiftCardError.invalidCode
        XCTAssertNotNil(error as? LocalizedError)
        XCTAssertNotNil((error as? LocalizedError)?.errorDescription)
    }

    // MARK: - DatabaseManager templateIds Parsing Tests

    func testBundleWithIncludedTemplatesRoundTrips() throws {
        let templateId1 = UUID()
        let templateId2 = UUID()

        let bundle = try giftCardManager.createBundle(
            name: "Template Bundle",
            description: "Includes templates",
            price: 49.99,
            bundleType: .professional,
            includedTemplateIds: [templateId1, templateId2],
            aiCredits: 200,
            expirationDays: 180
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds.count, 2)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId1) ?? false)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId2) ?? false)
    }

    func testBundleWithEmptyIncludedTemplatesRoundTrips() throws {
        // Empty templateIds must survive the JSON encode/decode path in DatabaseManager
        let bundle = try giftCardManager.createBundle(
            name: "No Templates",
            description: "No included templates",
            price: 19.99,
            bundleType: .starter,
            includedTemplateIds: [],
            aiCredits: 100,
            expirationDays: 90
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds, [])
    }

    func testBundleWithSingleTemplateRoundTrips() throws {
        let templateId = UUID()

        let bundle = try giftCardManager.createBundle(
            name: "Single Template",
            description: "One template",
            price: 29.99,
            bundleType: .custom,
            includedTemplateIds: [templateId],
            aiCredits: 75,
            expirationDays: 60
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertEqual(retrieved?.includedTemplateIds, [templateId])
    }
}