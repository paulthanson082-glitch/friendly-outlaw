import XCTest
@testable import WritersApp

// MARK: - GiftCardManager Tests
// Tests focused on the PR change: expirationDays validation changed from >= 0 to > 0,
// so expirationDays == 0 now throws (previously it was allowed).

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

    // MARK: - expirationDays Validation (PR Change: changed from >= 0 to > 0)

    /// PR change: expirationDays == 0 must now throw (previously it was allowed with >= 0).
    func testCreateBundleWithZeroExpirationDaysThrows() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Zero-Day Bundle",
                description: "Should now fail",
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

    /// Regression: negative expirationDays must still be rejected.
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

    /// Boundary: expirationDays == 1 is the new minimum valid value.
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

    /// Boundary: verify 0 does NOT get stored (it throws before storing).
    func testCreateBundleWithZeroExpirationDaysIsNotStored() {
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Instant-Expiry",
                description: "Should not be stored",
                price: 0.99,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: 0
            )
        )
        XCTAssertTrue(manager.getAllBundles().isEmpty,
                      "No bundle should be stored when expirationDays == 0 throws")
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

    func testMultipleBundlesWithVariousValidExpirationDays() throws {
        // Test that positive expirationDays values all succeed together (0 no longer valid)
        let _ = try manager.createBundle(name: "One", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 1)
        let _ = try manager.createBundle(name: "Thirty", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 30)
        let _ = try manager.createBundle(name: "Year", description: "", price: 0, bundleType: .starter, aiCredits: 1, expirationDays: 365)

        XCTAssertEqual(manager.getAllBundles().count, 3)
    }

    /// Regression: boundary between invalid (0) and valid (1) expirationDays.
    func testCreateBundleExpirationDaysBoundary() {
        // 0 throws
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Boundary Zero",
                description: "",
                price: 0,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: 0
            )
        )
        // 1 succeeds
        XCTAssertNoThrow(
            try manager.createBundle(
                name: "Boundary One",
                description: "",
                price: 0,
                bundleType: .starter,
                aiCredits: 1,
                expirationDays: 1
            )
        )
    }
}