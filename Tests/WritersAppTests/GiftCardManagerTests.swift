import XCTest
@testable import WritersApp

// MARK: - GiftCardManager Tests
// Tests focused on the PR change: expirationDays validation changed from > 0 to >= 0,
// allowing bundles that expire immediately (0 days = expires at creation time).

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

    // MARK: - expirationDays Validation (PR Change: >= 0 instead of > 0)

    /// PR change: expirationDays == 0 must now succeed (previously threw).
    func testCreateBundleWithZeroExpirationDaysSucceeds() throws {
        let bundle = try manager.createBundle(
            name: "Zero-Day Bundle",
            description: "Expires immediately",
            price: 9.99,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 0
        )
        XCTAssertEqual(bundle.expirationDays, 0)
        XCTAssertEqual(bundle.name, "Zero-Day Bundle")
    }

    /// Regression: negative expirationDays must still be rejected after the PR.
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

    /// Boundary: expirationDays == 1 (minimum previously-valid value) still works.
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

    /// A bundle with expirationDays == 0 is stored in the manager.
    func testCreateBundleWithZeroExpirationDaysIsRetrievable() throws {
        let bundle = try manager.createBundle(
            name: "Instant-Expiry",
            description: "Expires on creation",
            price: 0.99,
            bundleType: .starter,
            aiCredits: 1,
            expirationDays: 0
        )
        let retrieved = manager.getBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.expirationDays, 0)
    }

    /// Creating a gift card from a 0-expirationDays bundle sets expiry at approximately the current time.
    func testGiftCardFromZeroExpirationDaysBundleExpiresImmediately() throws {
        let bundle = try manager.createBundle(
            name: "Instant Bundle",
            description: "No grace period",
            price: 0.00,
            bundleType: .custom,
            aiCredits: 1,
            expirationDays: 0
        )
        let card = try manager.createGiftCard(bundleId: bundle.id)

        // The card should expire at approximately now (within a few seconds of creation)
        let expiresAt = card.metadata.expiresAt
        XCTAssertNotNil(expiresAt, "Gift card from 0-day bundle must have an expiry date")
        if let expiresAt {
            let secondsUntilExpiry = expiresAt.timeIntervalSinceNow
            // Should be at or very near 0 (0 days * 86400 seconds)
            XCTAssertLessThanOrEqual(abs(secondsUntilExpiry), 5.0,
                "Gift card from 0-day bundle should expire within 5 seconds of now, got \(secondsUntilExpiry)s")
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
        // Test that zero, positive values all succeed together
        let _ = try manager.createBundle(name: "Zero", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 0)
        let _ = try manager.createBundle(name: "One", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 1)
        let _ = try manager.createBundle(name: "Thirty", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 30)
        let _ = try manager.createBundle(name: "Year", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 365)

        XCTAssertEqual(manager.getAllBundles().count, 4)
    }
}