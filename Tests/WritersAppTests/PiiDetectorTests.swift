import XCTest
@testable import WritersApp

final class PiiDetectorTests: XCTestCase {

    private var detector: PiiDetector!

    override func setUp() {
        super.setUp()
        detector = PiiDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    private func names(_ text: String) -> Set<String> {
        Set(detector.scan(text).map { $0.patternName })
    }

    // MARK: - Clean Text

    func testCleanCreativeTextHasNoMatches() {
        let text = "The lighthouse keeper watched the storm roll in over the grey water."
        XCTAssertTrue(detector.scan(text).isEmpty)
    }

    func testEmptyStringHasNoMatches() {
        XCTAssertTrue(detector.scan("").isEmpty)
    }

    // MARK: - Standard Patterns

    func testDetectsSSN() {
        XCTAssertTrue(names("My number is 123-45-6789.").contains("ssn"))
    }

    func testSSNIsHighSeverity() {
        let match = detector.scan("123-45-6789").first { $0.patternName == "ssn" }
        XCTAssertEqual(match?.severity, .high)
    }

    func testDetectsValidCreditCard() {
        // 4111 1111 1111 1111 passes the Luhn check.
        XCTAssertTrue(names("Card: 4111 1111 1111 1111").contains("credit_card"))
    }

    func testDetectsFifteenDigitAmexCard() {
        // 378282246310005 is a standard test number that passes Luhn.
        XCTAssertTrue(names("Amex 3782 822463 10005").contains("credit_card"))
    }

    func testDetectsCardNumberAfterLeadingDigits() {
        // Regression: a greedy match once swallowed "124" and failed Luhn on the whole run.
        XCTAssertTrue(names("Order 124 4111 1111 1111 1111").contains("credit_card"))
    }

    func testIgnoresDigitRunThatFailsLuhn() {
        // Same digits with the last one changed fail the Luhn check.
        XCTAssertFalse(names("Ref 4111 1111 1111 1112").contains("credit_card"))
    }

    func testDetectsEmail() {
        XCTAssertTrue(names("Reach me at jane.doe@example.com today").contains("email"))
    }

    func testDetectsPhone() {
        XCTAssertTrue(names("Call 555-867-5309 after six").contains("phone"))
    }

    func testDetectsDateOfBirth() {
        XCTAssertTrue(names("Born 04/12/1987 in Ohio").contains("date_of_birth"))
        XCTAssertTrue(names("DOB: 4/12/1987").contains("date_of_birth"))
    }

    func testPlainDateIsNotDateOfBirth() {
        // A dated letter in a manuscript is not personal data.
        XCTAssertFalse(names("The letter is dated 10/25/2026.").contains("date_of_birth"))
    }

    // MARK: - Multiple Matches

    func testReportsEachPatternOnce() {
        let text = "a@b.com and c@d.org"
        let emailMatches = detector.scan(text).filter { $0.patternName == "email" }
        XCTAssertEqual(emailMatches.count, 1)
    }

    func testMatchResultsCarryNameNotMatchedText() {
        // The match type exposes only the pattern name and severity, never the value.
        let match = detector.scan("123-45-6789").first
        XCTAssertNotNil(match)
        XCTAssertFalse(String(describing: match!).contains("123-45-6789"))
    }

    // MARK: - Luhn Helper

    func testLuhnAcceptsKnownValidNumber() {
        XCTAssertTrue(PiiDetector.luhnValid("4111111111111111"))
    }

    func testLuhnRejectsTooShortNumber() {
        XCTAssertFalse(PiiDetector.luhnValid("411111"))
    }
}
