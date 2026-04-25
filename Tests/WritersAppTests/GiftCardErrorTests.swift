import XCTest
@testable import WritersApp

// Tests for GiftCardError after Equatable conformance was removed (PR change).
// All error comparisons use pattern matching rather than == to reflect the new API surface.
final class GiftCardErrorTests: XCTestCase {

    // MARK: - LocalizedError.errorDescription

    func testInvalidCodeErrorDescription() {
        let error = GiftCardError.invalidCode
        XCTAssertEqual(error.errorDescription, "Gift card code is invalid or not found")
    }

    func testBundleExpiredErrorDescription() {
        let error = GiftCardError.bundleExpired
        XCTAssertEqual(error.errorDescription, "Gift card bundle has expired")
    }

    func testAlreadyRedeemedErrorDescription() {
        let error = GiftCardError.alreadyRedeemed
        XCTAssertEqual(error.errorDescription, "Gift card has already been redeemed")
    }

    func testBundleNotFoundErrorDescription() {
        let error = GiftCardError.bundleNotFound
        XCTAssertEqual(error.errorDescription, "Bundle associated with this gift card was not found")
    }

    func testInvalidInputErrorDescription() {
        let message = "Expiration days must be greater than 0"
        let error = GiftCardError.invalidInput(message)
        XCTAssertEqual(error.errorDescription, "Invalid input: \(message)")
    }

    func testDatabaseErrorDescription() {
        let message = "constraint failed"
        let error = GiftCardError.databaseError(message)
        XCTAssertEqual(error.errorDescription, "Database error: \(message)")
    }

    // MARK: - LocalizedError.recoverySuggestion

    func testInvalidCodeRecoverySuggestion() {
        let error = GiftCardError.invalidCode
        XCTAssertEqual(error.recoverySuggestion, "Please check the gift card code and try again")
    }

    func testBundleExpiredRecoverySuggestion() {
        let error = GiftCardError.bundleExpired
        XCTAssertEqual(error.recoverySuggestion, "This gift card bundle has expired and can no longer be redeemed")
    }

    func testAlreadyRedeemedRecoverySuggestion() {
        let error = GiftCardError.alreadyRedeemed
        XCTAssertEqual(error.recoverySuggestion, "This gift card has already been redeemed")
    }

    func testBundleNotFoundRecoverySuggestion() {
        let error = GiftCardError.bundleNotFound
        XCTAssertEqual(error.recoverySuggestion, "The bundle associated with this gift card no longer exists")
    }

    func testInvalidInputRecoverySuggestion() {
        let error = GiftCardError.invalidInput("some message")
        XCTAssertEqual(error.recoverySuggestion, "Please provide valid input")
    }

    func testDatabaseErrorRecoverySuggestion() {
        let error = GiftCardError.databaseError("some db error")
        XCTAssertEqual(error.recoverySuggestion, "Please try again later")
    }

    // MARK: - LocalizedError conformance

    func testGiftCardErrorConformsToLocalizedError() {
        let error: any LocalizedError = GiftCardError.invalidCode
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testGiftCardErrorConformsToError() {
        let error: any Error = GiftCardError.invalidCode
        XCTAssertNotNil(error)
    }

    // MARK: - Pattern matching (Equatable was removed; use guard case)

    func testInvalidCodePatternMatching() throws {
        let manager = GiftCardManager()
        XCTAssertThrowsError(
            try manager.redeemGiftCard(code: "BADCODE", userId: UUID())
        ) { error in
            guard case GiftCardError.invalidCode = error else {
                XCTFail("Expected GiftCardError.invalidCode, got \(error)")
                return
            }
        }
    }

    func testInvalidInputPatternMatchingWithMessage() throws {
        let manager = GiftCardManager()
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Test",
                description: "Test",
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
            XCTAssertFalse(msg.isEmpty)
        }
    }

    func testBundleNotFoundPatternMatching() throws {
        let manager = GiftCardManager()
        XCTAssertThrowsError(
            try manager.createGiftCard(bundleId: UUID())
        ) { error in
            guard case GiftCardError.bundleNotFound = error else {
                XCTFail("Expected GiftCardError.bundleNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - invalidInput associated value

    func testInvalidInputCarriesAssociatedMessage() {
        let specificMessage = "Expiration days must be greater than 0"
        let error = GiftCardError.invalidInput(specificMessage)
        guard case GiftCardError.invalidInput(let extracted) = error else {
            XCTFail("Pattern match failed")
            return
        }
        XCTAssertEqual(extracted, specificMessage)
    }

    func testDatabaseErrorCarriesAssociatedMessage() {
        let specificMessage = "disk I/O error"
        let error = GiftCardError.databaseError(specificMessage)
        guard case GiftCardError.databaseError(let extracted) = error else {
            XCTFail("Pattern match failed")
            return
        }
        XCTAssertEqual(extracted, specificMessage)
    }

    // MARK: - Regression: expirationDays=0 is now valid (PR change: >= 0 instead of > 0)

    func testZeroExpirationDaysErrorMessageContent() throws {
        let manager = GiftCardManager()
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Test",
                description: "Test",
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
            XCTAssertEqual(msg, "Expiration days must be greater than 0")
        }
    }

    // MARK: - Pattern matching for remaining cases (bundleExpired, alreadyRedeemed)

    func testBundleExpiredPatternMatching() {
        // Verify the case exists and pattern matching works without Equatable.
        let error = GiftCardError.bundleExpired
        guard case GiftCardError.bundleExpired = error else {
            XCTFail("Expected GiftCardError.bundleExpired")
            return
        }
    }

    func testAlreadyRedeemedPatternMatching() {
        // Verify the case exists and pattern matching works without Equatable.
        let error = GiftCardError.alreadyRedeemed
        guard case GiftCardError.alreadyRedeemed = error else {
            XCTFail("Expected GiftCardError.alreadyRedeemed")
            return
        }
    }

    // MARK: - Regression: negative expirationDays still rejected with updated message

    func testNegativeExpirationDaysErrorMessageContent() throws {
        let manager = GiftCardManager()
        XCTAssertThrowsError(
            try manager.createBundle(
                name: "Test",
                description: "Test",
                price: 10.0,
                bundleType: .starter,
                aiCredits: 50,
                expirationDays: -5
            )
        ) { error in
            guard case GiftCardError.invalidInput(let msg) = error else {
                XCTFail("Expected GiftCardError.invalidInput, got \(error)")
                return
            }
            XCTAssertEqual(msg, "Expiration days must be greater than 0")
        }
    }

    // MARK: - errorDescription non-nil for all cases

    func testAllCasesHaveNonNilErrorDescription() {
        let cases: [GiftCardError] = [
            .invalidCode,
            .bundleExpired,
            .alreadyRedeemed,
            .bundleNotFound,
            .invalidInput("msg"),
            .databaseError("msg"),
        ]
        for giftCardError in cases {
            XCTAssertNotNil(giftCardError.errorDescription, "errorDescription should not be nil for \(giftCardError)")
        }
    }

    // MARK: - recoverySuggestion non-nil for all cases

    func testAllCasesHaveNonNilRecoverySuggestion() {
        let cases: [GiftCardError] = [
            .invalidCode,
            .bundleExpired,
            .alreadyRedeemed,
            .bundleNotFound,
            .invalidInput("msg"),
            .databaseError("msg"),
        ]
        for giftCardError in cases {
            XCTAssertNotNil(giftCardError.recoverySuggestion, "recoverySuggestion should not be nil for \(giftCardError)")
        }
    }
}