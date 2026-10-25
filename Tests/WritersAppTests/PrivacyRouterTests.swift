import XCTest
@testable import WritersApp

final class PrivacyRouterTests: XCTestCase {

    private var router: PrivacyRouter!

    override func setUp() {
        super.setUp()
        router = PrivacyRouter()
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    func testCleanTextRoutesToCloud() {
        let route = router.route("Give me five plot twists for a heist story.")
        XCTAssertEqual(route, .cloud)
    }

    func testPersonalDataIsBlocked() {
        let route = router.route("Client email is jane.doe@example.com")
        guard case .blocked = route else {
            return XCTFail("Expected personal data to be blocked, got \(route)")
        }
    }

    func testBlockedReasonNamesPatternButNotValue() {
        let route = router.route("SSN 123-45-6789 for the file")
        guard case .blocked(let reason) = route else {
            return XCTFail("Expected block")
        }
        XCTAssertTrue(reason.contains("ssn"))
        XCTAssertFalse(reason.contains("123-45-6789"))
    }

    func testAnySingleMatchBlocks() {
        // Medium severity still blocks, per the fail-closed threshold.
        let route = router.route("Call 555-867-5309")
        XCTAssertNotEqual(route, .cloud)
    }

    func testEmptyTextRoutesToCloud() {
        XCTAssertEqual(router.route(""), .cloud)
    }
}
