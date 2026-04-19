import XCTest
@testable import WritersApp

/// Tests for the PR change: expirationDays validation changed from `> 0` to `>= 0`,
/// making zero-day expiration (instant-access bundles) valid.
final class GiftCardExpirationTests: XCTestCase {

    var giftCardManager: GiftCardManager!

    override func setUp() {
        super.setUp()
        giftCardManager = GiftCardManager()
    }

    override func tearDown() {
        giftCardManager = nil
        super.tearDown()
    }

    // MARK: - Boundary: expirationDays == 0 (PR change: now valid)

    func testCreateBundleWithZeroExpirationDaysSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Instant Bundle",
            description: "No waiting period",
            price: 9.99,
            bundleType: .starter,
            aiCredits: 10,
            expirationDays: 0
        )
        XCTAssertEqual(bundle.expirationDays, 0)
        XCTAssertEqual(bundle.name, "Instant Bundle")
    }

    func testCreateBundleWithZeroExpirationDaysIsStored() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Zero Days",
            description: "Expires immediately",
            price: 1.00,
            bundleType: .starter,
            aiCredits: 5,
            expirationDays: 0
        )
        let retrieved = giftCardManager.getBundle(id: bundle.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.expirationDays, 0)
    }

    // MARK: - Boundary: expirationDays == -1 (still invalid)

    func testCreateBundleWithNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Negative Days",
                description: "Should fail",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -1
            )
        ) { error in
            guard case GiftCardError.invalidInput(let message) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertTrue(message.contains("greater than or equal to 0"), "Error message should reference >= 0")
        }
    }

    func testCreateBundleWithLargeNegativeExpirationDaysThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "Very Negative",
                description: "Very negative days",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: -365
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }
    }

    // MARK: - Valid positive expirationDays still work

    func testCreateBundleWithPositiveExpirationDaysSucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Annual Bundle",
            description: "Valid for a year",
            price: 99.99,
            bundleType: .professional,
            aiCredits: 500,
            expirationDays: 365
        )
        XCTAssertEqual(bundle.expirationDays, 365)
    }

    func testCreateBundleWithOneExpirationDaySucceeds() throws {
        let bundle = try giftCardManager.createBundle(
            name: "One Day Bundle",
            description: "Expires in 24h",
            price: 4.99,
            bundleType: .starter,
            aiCredits: 1,
            expirationDays: 1
        )
        XCTAssertEqual(bundle.expirationDays, 1)
    }

    // MARK: - Error message content (PR change updated the message)

    func testNegativeExpirationErrorMessageContent() {
        do {
            _ = try giftCardManager.createBundle(
                name: "Test",
                description: "Test",
                price: 1.0,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: -1
            )
            XCTFail("Expected error to be thrown")
        } catch GiftCardError.invalidInput(let message) {
            // PR changed message from "must be greater than 0" to "must be greater than or equal to 0"
            XCTAssertFalse(message.contains("must be greater than 0") && !message.contains("equal"),
                           "Old error message should not be used")
            XCTAssertTrue(message.contains("greater than or equal to 0"))
        } catch {
            XCTFail("Expected GiftCardError.invalidInput, got \(error)")
        }
    }

    // MARK: - Other validations still enforced

    func testCreateBundleWithZeroAICreditsThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "No Credits",
                description: "Zero AI credits",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 0,
                expirationDays: 0
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }
    }

    func testCreateBundleWithEmptyNameThrows() {
        XCTAssertThrowsError(
            try giftCardManager.createBundle(
                name: "",
                description: "No name",
                price: 9.99,
                bundleType: .starter,
                aiCredits: 10,
                expirationDays: 0
            )
        ) { error in
            XCTAssertTrue(error is GiftCardError)
        }
    }

    // MARK: - Gift card created from zero-day bundle

    func testGiftCardCreatedFromZeroDayBundleIsImmediatelyExpired() throws {
        let bundle = try giftCardManager.createBundle(
            name: "Instant",
            description: "Zero days",
            price: 0.99,
            bundleType: .starter,
            aiCredits: 1,
            expirationDays: 0
        )
        let card = try giftCardManager.createGiftCard(bundleId: bundle.id)
        // A 0-day expiry means the card expires at creation time (or immediately after)
        // The expiry should be very close to now
        if let expiresAt = card.metadata.expiresAt {
            let secondsSinceExpiry = Date().timeIntervalSince(expiresAt)
            // Should be expired or expire within a few seconds of creation
            XCTAssertGreaterThanOrEqual(secondsSinceExpiry, -5.0,
                "Zero-day bundle card should expire nearly immediately")
        } else {
            XCTFail("Gift card from zero-day bundle should have an expiration date")
        }
    }
}