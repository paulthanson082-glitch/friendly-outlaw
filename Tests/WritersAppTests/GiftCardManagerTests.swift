import XCTest
@testable import WritersApp

// MARK: - GiftCardManager Tests
// Tests focused on the PR change: expirationDays validation changed back to > 0
// (bundles with 0 expiration days are now rejected).

final class GiftCardManagerTests: XCTestCase {

    var manager: GiftCardManager!

    override func setUp() {
        super.setUp()
        manager = GiftCardManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - expirationDays Validation (PR Change: > 0, zero is now rejected)

    /// PR change: expirationDays == 0 must now throw (changed from >= 0 to > 0).
    func testCreateBundleWithZeroExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Zero-Day Bundle",
                description: "Expires immediately",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput, got \(error)")
            }
            XCTAssertTrue(
                message.lowercased().contains("expiration"),
                "Error message should mention expiration days, got: \(message)"
            )
        }
    }

    /// Zero expirationDays must not create a bundle in the manager.
    func testCreateBundleWithZeroExpirationDaysDoesNotStorBundle() {
        _ = try? manager.createBundle(
            name: "Zero-Day Bundle",
            description: "Should not be stored",
            price: 9.99,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 0
        )
        XCTAssertTrue(manager.getAllBundles().isEmpty,
            "A bundle with expirationDays=0 must not be persisted after the PR")
    }

    /// Negative expirationDays must still be rejected.
    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Invalid Bundle",
                description: "Should fail",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -1
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput, got \(error)")
            }
            XCTAssertTrue(
                message.lowercased().contains("expiration"),
                "Error message should mention expiration days, got: \(message)"
            )
        }
    }

    /// Negative expirationDays = -100 must also be rejected.
    func testCreateBundleWithLargeNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Very Invalid",
                description: "Deeply negative",
                price: 5.00,
                bundleType: .custom,
                aiCredits: 5,
                expirationDays: -100
            )
        )
    }

    /// Positive expirationDays must continue to work.
    func testCreateBundleWithPositiveExpirationDaysSucceeds() throws {
        let bundle = try manager.createBundle(
            name: "30-Day Bundle",
            description: "Standard month bundle",
            price: 19.99,
            bundleType: .professional,
            aiCredits: 100,
            expirationDays: 30
        )
        XCTAssertEqual(bundle.expirationDays, 30)
    }

    /// Boundary: expirationDays == 1 is the minimum valid value after the PR.
    func testCreateBundleWithOneExpirationDaySucceeds() throws {
        let bundle = try manager.createBundle(
            name: "One-Day Bundle",
            description: "Expires tomorrow",
            price: 1.99,
            bundleType: .starter,
            aiCredits: 5,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    /// Boundary: expirationDays == 1 is retrievable.
    func testCreateBundleWithOneExpirationDayIsRetrievable() throws {
        let bundle = try manager.createBundle(
            name: "Min-Expiry",
            description: "Minimum valid expiration",
            price: 0.99,
            bundleType: .starter,
            aiCredits: 1,
            expirationDays: 1
        )
        let retrieved = manager.getBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.expirationDays, 1)
    }

    /// Creating a gift card from a 1-day bundle sets expiry near 24 hours from now.
    func testGiftCardFromOneExpirationDayBundleExpiresInAboutOneDay() throws {
        let bundle = try manager.createBundle(
            name: "One-Day Bundle",
            description: "Expires in a day",
            price: 0.00,
            bundleType: .custom,
            aiCredits: 1,
            expirationDays: 1
        )
        let card = try manager.createGiftCard(bundleId: bundle.id)
        let expiresAt = card.metadata.expiresAt
        XCTAssertNotNil(expiresAt, "Gift card from 1-day bundle must have an expiry date")
        if let expiresAt {
            let secondsUntilExpiry = expiresAt.timeIntervalSinceNow
            // Should be approximately 86400 seconds (1 day)
            XCTAssertGreaterThan(secondsUntilExpiry, 86390,
                "Gift card should expire in approximately 1 day, got \(secondsUntilExpiry)s")
            XCTAssertLessThan(secondsUntilExpiry, 86410,
                "Gift card should expire in approximately 1 day, got \(secondsUntilExpiry)s")
        }
    }

    // MARK: - AI Credits Validation (unchanged guard, confirm still works)

    func testCreateBundleWithZeroAICreditsThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "No-Credits Bundle",
                description: "Zero AI credits",
                price: 0.00,
                bundleType: .starter,
                aiCredits: 0,
                expirationDays: 30
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput")
            }
            XCTAssertTrue(message.lowercased().contains("credit"))
        }
    }

    func testCreateBundleWithNegativeAICreditsThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Negative Credits",
                description: "Should fail",
                price: 5.00,
                bundleType: .starter,
                aiCredits: -5,
                expirationDays: 10
            )
        )
    }

    // MARK: - Bundle Name Validation (unchanged, regression)

    func testCreateBundleWithEmptyNameThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "",
                description: "No name",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 30
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                return XCTFail("Expected GiftCardError.invalidInput")
            }
            XCTAssertTrue(message.lowercased().contains("name"))
        }
    }

    func testCreateBundleWithWhitespaceOnlyNameThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "   ",
                description: "Whitespace-only name",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 7
            )
        )
    }

    // MARK: - Valid Bundle Creation (regression, broad coverage)

    func testCreateBundleStoresInManager() throws {
        let bundle = try manager.createBundle(
            name: "Enterprise Bundle",
            description: "Full suite",
            price: 99.99,
            bundleType: .enterprise,
            aiCredits: 1000,
            expirationDays: 365
        )
        XCTAssertFalse(manager.getAllBundles().isEmpty)
        XCTAssertEqual(manager.getAllBundles().first?.id, bundle.id)
    }

    func testMultipleBundlesWithVariousExpirationDays() throws {
        // PR change: zero is now rejected; only positive values succeed
        let _ = try manager.createBundle(name: "One", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 1)
        let _ = try manager.createBundle(name: "Thirty", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 30)
        let _ = try manager.createBundle(name: "Year", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 365)

        XCTAssertEqual(manager.getAllBundles().count, 3,
            "Only positive expirationDays bundles should be stored after the PR change")
    }

    /// Regression: zero expirationDays among a mix must not succeed.
    func testZeroExpirationDaysMixedWithValid() throws {
        XCTAssertThrowsError(
            try manager.createBundle(name: "Zero", description: "", price: 0,
                                     bundleType: .starter, aiCredits: 1, expirationDays: 0)
        )
        // Other bundles with positive expiry should still succeed
        let _ = try manager.createBundle(name: "Valid", description: "", price: 0,
                                          bundleType: .starter, aiCredits: 1, expirationDays: 7)
        XCTAssertEqual(manager.getAllBundles().count, 1)
    }
}