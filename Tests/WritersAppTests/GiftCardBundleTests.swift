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

    // MARK: - Expiration Days Boundary Tests (PR change: expirationDays must be > 0)

    func testCreateBundleWithZeroExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Test Bundle",
                description: "Test",
                price: 29.99,
                bundleType: .starter,
                aiCredits: 100,
                expirationDays: 0
            )
        ) { error in
            guard case .invalidInput(let message) = error as? GiftCardError else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("greater than 0"), "Error message should mention 'greater than 0', got: \(message)")
        }
    }

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Test Bundle",
                description: "Test",
                price: 29.99,
                bundleType: .starter,
                aiCredits: 100,
                expirationDays: -1
            )
        ) { error in
            guard case .invalidInput = error as? GiftCardError else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
        }
    }

    func testCreateBundleWithOneExpirationDayIsMinimumValid() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Minimum Expiry Bundle",
            description: "Expires in exactly 1 day",
            price: 9.99,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    func testCreateBundleExpirationDaysErrorMessageChanged() {
        // Regression: error message should say "greater than 0", not "greater than or equal to 0"
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Test",
                description: "Test",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            )
        ) { error in
            if let giftCardError = error as? GiftCardError,
               let description = giftCardError.errorDescription {
                XCTAssertTrue(
                    description.contains("greater than 0"),
                    "Expected error message to say 'greater than 0', got: \(description)"
                )
                XCTAssertFalse(
                    description.contains("greater than or equal to 0"),
                    "Error message should not say 'greater than or equal to 0'"
                )
            } else {
                XCTFail("Expected a GiftCardError with errorDescription")
            }
        }
    }

    // MARK: - GiftCardError Non-Equatable Tests (PR change: Equatable conformance removed)

    func testGiftCardErrorCasePatternMatching() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Test",
            description: "Test",
            price: 10.0,
            bundleType: .starter,
            aiCredits: 50,
            expirationDays: 30
        )
        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)

        // Verify invalidCode via pattern matching (not ==)
        do {
            try giftCardManager.redeemGiftCard(code: "INVALID-CODE", userId: UUID())
            XCTFail("Expected GiftCardError.invalidCode to be thrown")
        } catch let error as GiftCardError {
            guard case .invalidCode = error else {
                XCTFail("Expected .invalidCode, got \(error)")
                return
            }
        }

        // Verify alreadyRedeemed via pattern matching (not ==)
        let userId = UUID()
        try giftCardManager.redeemGiftCard(code: card.code, userId: userId)
        do {
            try giftCardManager.redeemGiftCard(code: card.code, userId: UUID())
            XCTFail("Expected GiftCardError.alreadyRedeemed to be thrown")
        } catch let error as GiftCardError {
            guard case .alreadyRedeemed = error else {
                XCTFail("Expected .alreadyRedeemed, got \(error)")
                return
            }
        }
    }

    func testGiftCardErrorBundleNotFoundPatternMatching() {
        do {
            try giftCardManager.createGiftCard(bundleId: UUID())
            XCTFail("Expected GiftCardError.bundleNotFound to be thrown")
        } catch let error as GiftCardError {
            guard case .bundleNotFound = error else {
                XCTFail("Expected .bundleNotFound, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected GiftCardError, got \(error)")
        }
    }

    func testGiftCardErrorInvalidInputPatternMatching() {
        do {
            try giftCardManager.createBundle(
                name: "",
                description: "Test",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: 30
            )
            XCTFail("Expected GiftCardError.invalidInput to be thrown")
        } catch let error as GiftCardError {
            guard case .invalidInput(let message) = error else {
                XCTFail("Expected .invalidInput, got \(error)")
                return
            }
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Expected GiftCardError, got \(error)")
        }
    }

    func testGiftCardErrorDescriptions() {
        let cases: [(GiftCardError, String, String)] = [
            (.invalidCode, "invalid or not found", "check the gift card code"),
            (.bundleExpired, "expired", "expired and can no longer"),
            (.alreadyRedeemed, "already been redeemed", "already been redeemed"),
            (.bundleNotFound, "not found", "no longer exists"),
            (.invalidInput("bad data"), "bad data", "valid input"),
            (.databaseError("connection failed"), "connection failed", "try again later"),
        ]

        for (error, expectedDescriptionSubstring, expectedRecoverySubstring) in cases {
            let description = error.errorDescription ?? ""
            let recovery = error.recoverySuggestion ?? ""

            XCTAssertTrue(
                description.lowercased().contains(expectedDescriptionSubstring.lowercased()),
                "errorDescription for \(error) should contain '\(expectedDescriptionSubstring)', got: \(description)"
            )
            XCTAssertTrue(
                recovery.lowercased().contains(expectedRecoverySubstring.lowercased()),
                "recoverySuggestion for \(error) should contain '\(expectedRecoverySubstring)', got: \(recovery)"
            )
        }
    }

    func testGiftCardErrorIsNotEquatable() {
        // GiftCardError no longer conforms to Equatable; verify we can still inspect cases
        let error1: GiftCardError = .invalidCode
        let error2: GiftCardError = .invalidCode

        // Pattern matching must be used instead of ==
        if case .invalidCode = error1 { } else { XCTFail("error1 should be .invalidCode") }
        if case .invalidCode = error2 { } else { XCTFail("error2 should be .invalidCode") }

        // Verify invalidInput carries its associated message
        let inputError: GiftCardError = .invalidInput("test message")
        if case .invalidInput(let msg) = inputError {
            XCTAssertEqual(msg, "test message")
        } else {
            XCTFail("inputError should be .invalidInput")
        }
    }

    // MARK: - DatabaseManager TemplateIds Parsing Tests (PR change: nil-safety for templateIdsText)

    func testBundlePersistenceWithEmptyTemplateIds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "No Templates",
            description: "Bundle without template IDs",
            price: 19.99,
            bundleType: .starter,
            aiCredits: 100,
            expirationDays: 90,
            includedTemplateIds: []
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds.count, 0)
        XCTAssertEqual(retrieved?.name, "No Templates")
    }

    func testBundlePersistenceWithMultipleTemplateIds() throws {
        let templateId1 = UUID()
        let templateId2 = UUID()
        let templateId3 = UUID()

        let bundle = try giftCardManager.createBundle(
            name: "With Templates",
            description: "Bundle with template IDs",
            price: 49.99,
            bundleType: .professional,
            aiCredits: 250,
            expirationDays: 180,
            includedTemplateIds: [templateId1, templateId2, templateId3]
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.includedTemplateIds.count, 3)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId1) ?? false)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId2) ?? false)
        XCTAssertTrue(retrieved?.includedTemplateIds.contains(templateId3) ?? false)
    }

    func testBundlePersistenceTemplateIdsRoundtrip() throws {
        let templateIds = (0..<5).map { _ in UUID() }

        let bundle = try giftCardManager.createBundle(
            name: "Template Roundtrip",
            description: "Test JSON encode/decode of template IDs",
            price: 79.99,
            bundleType: .enterprise,
            aiCredits: 500,
            expirationDays: 365,
            includedTemplateIds: templateIds
        )

        let retrieved = try databaseManager.getGiftCardBundle(id: bundle.id)
        let retrievedIds = Set(retrieved?.includedTemplateIds ?? [])
        let originalIds = Set(templateIds)
        XCTAssertEqual(retrievedIds, originalIds, "All template IDs should survive a database roundtrip")
    }
}