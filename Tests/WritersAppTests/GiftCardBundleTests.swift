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
            guard case GiftCardError.invalidCode = error else {
                XCTFail("Expected GiftCardError.invalidCode, got \(error)")
                return
            }
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
            guard case GiftCardError.alreadyRedeemed = error else {
                XCTFail("Expected GiftCardError.alreadyRedeemed, got \(error)")
                return
            }
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
            expirationDays: 1
        )

        // Create a normal card then override its expiry to the past to simulate an expired card.
        var card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let pastDate = Date().addingTimeInterval(-86400)
        card.metadata = GiftCardMetadata(createdAt: card.metadata.createdAt, expiresAt: pastDate)

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
            expirationDays: 1
        )

        // Create a normal card then update its expiry to the past so redeemGiftCard sees it as expired.
        var card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        let pastDate = Date().addingTimeInterval(-86400)
        card.metadata = GiftCardMetadata(createdAt: card.metadata.createdAt, expiresAt: pastDate)
        try giftCardManager.updateGiftCard(card)

        XCTAssertThrowsError(
            try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())
        ) { error in
            guard case GiftCardError.bundleExpired = error else {
                XCTFail("Expected GiftCardError.bundleExpired, got \(error)")
                return
            }
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
            guard case GiftCardError.invalidCode = error else {
                XCTFail("Expected GiftCardError.invalidCode, got \(error)")
                return
            }
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

    // MARK: - Expiration Days Boundary Tests (PR Change: > 0 → >= 0)

    func testCreateBundleWithZeroExpirationDaysSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Zero Days",
            description: "Expires immediately",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 0
        )
        XCTAssertEqual(bundle.expirationDays, 0)
    }

    func testCreateBundleWithOneExpirationDaySucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "One Day",
            description: "Minimum valid expiration",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Negative Days",
                description: "Should fail",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: -1
            )
        ) { error in
            guard case GiftCardError.invalidInput(_) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
        }
    }

    func testCreateBundleExpirationDaysErrorMessageIsDescriptive() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Test",
                description: "Test",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: -1
            )
        ) { error in
            XCTAssertNotNil((error as? GiftCardError)?.errorDescription)
            let description = (error as? GiftCardError)?.errorDescription ?? ""
            XCTAssertFalse(description.isEmpty)
        }
    }

    // MARK: - Template IDs Persistence Tests (PR Change: DatabaseManager)

    func testBundleWithTemplateIdsPersistsAndLoadsCorrectly() throws {
        let templateId1 = UUID()
        let templateId2 = UUID()
        let bundle = try giftCardManager.createBundle(
            name: "Template Bundle",
            description: "Has templates",
            price: 49.99,
            bundleType: .professional,
            includedTemplateIds: [templateId1, templateId2],
            aiCredits: 200,
            expirationDays: 365
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds.count, 2)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId1) ?? false)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId2) ?? false)
    }

    func testBundleWithEmptyTemplateIdsPersistsAndLoadsCorrectly() throws {
        let bundle = try giftCardManager.createBundle(
            name: "No Templates",
            description: "No templates included",
            price: 29.99,
            bundleType: .starter,
            includedTemplateIds: [],
            aiCredits: 100,
            expirationDays: 180
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds.count, 0)
    }

    // MARK: - PR Change: expirationDays validation changed from >= 0 to > 0

    /// After the PR, expirationDays=1 (minimum valid value) must succeed.
    func testCreateBundleWithExpirationDaysOneSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Short Expiry Bundle",
            description: "Expires in 1 day",
            price: 5.0,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 1
        )
        XCTAssertNotNil(bundle.id,
            "expirationDays=1 is the minimum valid value after the PR change and must not throw")
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    /// expirationDays=0 must now be rejected (changed from >= 0 to > 0).
    func testCreateBundleWithExpirationDaysZeroThrowsInvalidInput() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Zero Expiry",
                description: "Zero days",
                price: 5.0,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertEqual(message, "Expiration days must be greater than 0",
                "Error message must use 'greater than 0' wording matching the updated validation")
        }
    }

    /// Negative expirationDays must also be rejected.
    func testCreateBundleWithNegativeExpirationDaysThrowsInvalidInput() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Negative Expiry",
                description: "Negative days",
                price: 5.0,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -5
            )
        ) { error in
            guard case GiftCardError.invalidInput = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
        }
    }

    /// Large expirationDays value must be accepted without error.
    func testCreateBundleWithLargeExpirationDaysSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Long Expiry Bundle",
            description: "Expires in 10 years",
            price: 99.0,
            bundleType: .enterprise,
            aiCredits: 1000,
            expirationDays: 3650
        )
        XCTAssertEqual(bundle.expirationDays, 3650,
            "Large expirationDays value (e.g., 3650) must be accepted and stored without error")
    }

    /// Boundary: expirationDays=2 (one above minimum) must succeed.
    func testCreateBundleWithExpirationDaysTwoSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Two Day Bundle",
            description: "Short window",
            price: 9.99,
            bundleType: .starter,
            aiCredits: 5,
            expirationDays: 2
        )
        XCTAssertEqual(bundle.expirationDays, 2)
    }

    /// expirationDays=-1 (one below zero) must be rejected.
    func testCreateBundleWithNegativeOneExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Minus One",
                description: "Negative",
                price: 1.0,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: -1
            )
        ) { error in
            guard case GiftCardError.invalidInput = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
        }
    }
}