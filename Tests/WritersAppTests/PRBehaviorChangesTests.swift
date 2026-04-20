import XCTest
@testable import WritersApp

// MARK: - PR Behavioral Change Tests
//
// Tests covering the specific behavioral changes introduced in this PR:
//
// 1. WritersApp.updateProspectStatus: No longer guards against double-counting.
//    Old behavior: prospectsContacted was incremented only on first transition
//    to a contact state (contacted/replied/meeting) from a non-contact state.
//    New behavior: prospectsContacted is ALWAYS incremented whenever the new
//    status is .contacted, .replied, or .meeting, regardless of previous status.
//
// 2. GmailService.listMessages: URL is now built via manual string interpolation
//    instead of URLComponents, with explicit percent encoding for the query param.
//    Fetch loop is now sequential instead of concurrent.
//
// 3. BrowserService.fetch: URL validation (invalidURL for non-http/https schemes)
//    remains; tests confirm the validation gate still works after the stripHTML
//    range-end change (exclusive → inclusive).

// MARK: - updateProspectStatus Always-Increment Behavior

final class UpdateProspectStatusAlwaysIncrementTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Core new behavior: counter increments unconditionally for contact statuses

    /// New behavior: updating a prospect from .new → .contacted increments the counter (baseline).
    func testNewToContactedIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "First Contact", email: "first@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
    }

    /// New behavior: updating a prospect from .contacted → .contacted again ALSO increments.
    /// Under the old implementation this would NOT have incremented (it only counted the
    /// initial transition from a non-contact state).
    func testContactedToContactedAgainIncrements() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Repeat Contact", email: "repeat@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        // Same contact status applied again — new code always increments
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2,
            "Setting .contacted on an already-contacted prospect should now increment the counter")
    }

    /// New behavior: .contacted → .replied increments even though both are contact statuses.
    func testContactedToRepliedIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Follow Up", email: "followup@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2,
            "Transitioning from .contacted to .replied should also increment because .replied is a contact status")
    }

    /// New behavior: .replied → .meeting increments even though both are contact statuses.
    func testRepliedToMeetingIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Meeting Candidate", email: "mtg@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .replied)
        try app.updateProspectStatus(id: prospect.id, status: .meeting)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2,
            "Each contact-status update must increment prospectsContacted under the new logic")
    }

    /// .declined → .meeting: under the new code this increments (as .meeting is a contact status).
    func testDeclinedToMeetingIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Second Chance", email: "sc@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)

        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
    }

    /// Non-contact statuses (.declined, .converted, .new) must never increment the counter.
    func testNonContactStatusesNeverIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Non-Contact", email: "nc@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .new)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)

        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)

        try app.updateProspectStatus(id: prospect.id, status: .converted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0,
            ".converted must not increment prospectsContacted")
    }

    /// Counter accumulates across multiple distinct prospects updated to contact statuses.
    func testCounterAccumulatesAcrossMultipleProspects() throws {
        app.startCoworkSession()
        let p1 = app.addProspect(name: "Prospect A", email: "a@example.com")
        let p2 = app.addProspect(name: "Prospect B", email: "b@example.com")
        let p3 = app.addProspect(name: "Prospect C", email: "c@example.com")

        try app.updateProspectStatus(id: p1.id, status: .contacted)
        try app.updateProspectStatus(id: p2.id, status: .replied)
        try app.updateProspectStatus(id: p3.id, status: .meeting)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3)
    }

    /// Counter survives a full session lifecycle: start → operations → end.
    func testCounterIsPreservedOnSessionEnd() throws {
        app.startCoworkSession()
        let p = app.addProspect(name: "Session Test", email: "st@example.com")
        try app.updateProspectStatus(id: p.id, status: .contacted)
        try app.updateProspectStatus(id: p.id, status: .replied)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 2,
            "Ended session must preserve the prospectsContacted count accumulated during the session")
    }

    /// Without an active session, updateProspectStatus must not crash even though
    /// activeCoworkSession is nil and there is no counter to increment.
    func testUpdateStatusWithoutActiveSessionDoesNotCrash() throws {
        XCTAssertNil(app.activeCoworkSession)
        let prospect = app.addProspect(name: "No Session", email: "nosession@example.com")
        // Must not crash or throw unexpectedly
        XCTAssertNoThrow(try app.updateProspectStatus(id: prospect.id, status: .contacted))
    }

    /// Updating a non-existent prospect must throw regardless of active session state.
    func testUpdateStatusForUnknownIdThrows() {
        app.startCoworkSession()
        XCTAssertThrowsError(
            try app.updateProspectStatus(id: UUID(), status: .contacted)
        ) { error in
            guard case CoworkError.prospectNotFound = error else {
                return XCTFail("Expected CoworkError.prospectNotFound, got \(error)")
            }
        }
    }

    /// Verify that .meeting status sets lastContactedAt (ProspectDatabase behaviour
    /// is unchanged; confirmed via the WritersApp facade).
    func testUpdateStatusToMeetingSetsLastContactedAt() throws {
        let prospect = app.addProspect(name: "Meeting Test", email: "mtg2@example.com")
        XCTAssertNil(prospect.lastContactedAt)

        try app.updateProspectStatus(id: prospect.id, status: .meeting)

        let updated = app.prospectDatabase.getProspect(id: prospect.id)
        XCTAssertNotNil(updated?.lastContactedAt,
            "lastContactedAt must be set when status becomes .meeting")
    }

    /// Verify that .declined status does NOT set lastContactedAt (regression).
    func testUpdateStatusToDeclinedDoesNotSetLastContactedAt() throws {
        let prospect = app.addProspect(name: "Declined Test", email: "dec@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .declined)

        let updated = app.prospectDatabase.getProspect(id: prospect.id)
        XCTAssertNil(updated?.lastContactedAt,
            "lastContactedAt must not be set when status becomes .declined")
    }

    /// Regression: setting .replied still persists the correct status in the database.
    func testUpdateStatusToRepliedPersistsInDatabase() throws {
        let prospect = app.addProspect(name: "Replied Test", email: "rep@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)

        let stored = app.prospectDatabase.getProspect(id: prospect.id)
        XCTAssertEqual(stored?.status, .replied)
    }

    /// Boundary: prospectsContacted count reflects all increments, even if a single
    /// prospect oscillates between contact and non-contact states multiple times.
    func testOscillatingStatusUpdatesAccumulateCorrectly() throws {
        app.startCoworkSession()
        let p = app.addProspect(name: "Oscillator", email: "osc@example.com")

        // contact → decline → contact → decline → contact: 3 increments total
        try app.updateProspectStatus(id: p.id, status: .contacted)  // +1 → 1
        try app.updateProspectStatus(id: p.id, status: .declined)   // +0 → 1
        try app.updateProspectStatus(id: p.id, status: .contacted)  // +1 → 2
        try app.updateProspectStatus(id: p.id, status: .declined)   // +0 → 2
        try app.updateProspectStatus(id: p.id, status: .meeting)    // +1 → 3

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3)
    }
}

// MARK: - GmailService URL Building Tests

final class GmailServiceURLBuildingTests: XCTestCase {

    // The base URL is hard-coded inside GmailService; we replicate it here for validation
    private let base = "https://gmail.googleapis.com/gmail/v1/users/me"

    // MARK: - URL format validation (matches the new manual-string approach)

    /// The new implementation builds the URL as a plain string; verify the format produces
    /// a valid URL that Foundation can parse.
    func testListMessagesURLWithDefaultMaxResultsIsValid() {
        let maxResults = 20
        let urlString = "\(base)/messages?maxResults=\(maxResults)"
        XCTAssertNotNil(URL(string: urlString),
            "Default listMessages URL must be a valid URL")
    }

    func testListMessagesURLWithCustomMaxResultsIsValid() {
        for maxResults in [1, 10, 50, 100, 500] {
            let urlString = "\(base)/messages?maxResults=\(maxResults)"
            XCTAssertNotNil(URL(string: urlString),
                "URL must be valid for maxResults=\(maxResults)")
        }
    }

    /// With an empty query, the URL must not contain a "q" parameter.
    func testListMessagesURLWithEmptyQueryOmitsQParam() {
        let maxResults = 10
        var urlString = "\(base)/messages?maxResults=\(maxResults)"
        let query: String? = nil
        if let q = query, !q.isEmpty {
            let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
            urlString += "&q=\(encoded)"
        }
        XCTAssertFalse(urlString.contains("&q="),
            "URL must not include q parameter when query is nil")
        XCTAssertNotNil(URL(string: urlString))
    }

    func testListMessagesURLWithEmptyStringQueryOmitsQParam() {
        var urlString = "\(base)/messages?maxResults=10"
        let query: String? = ""
        if let q = query, !q.isEmpty {
            let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
            urlString += "&q=\(encoded)"
        }
        XCTAssertFalse(urlString.contains("&q="))
    }

    /// With a plain ASCII query the URL must contain the "&q=" segment and remain valid.
    func testListMessagesURLWithASCIIQueryIsValid() {
        var urlString = "\(base)/messages?maxResults=10"
        let query = "from:agent@example.com"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        urlString += "&q=\(encoded)"

        XCTAssertNotNil(URL(string: urlString),
            "URL with ASCII query must be valid")
        XCTAssertTrue(urlString.contains("&q="))
    }

    /// Queries with special characters (spaces, colons, @) must be percent-encoded so the
    /// resulting URL string is still parseable by URL(string:).
    func testListMessagesURLWithSpecialCharsInQueryIsValid() {
        let queries = [
            "from:agent@example.com is:unread",
            "subject:Hello World!",
            "newer_than:7d label:inbox",
            "\"exact phrase\" OR other"
        ]
        for query in queries {
            var urlString = "\(base)/messages?maxResults=20"
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            urlString += "&q=\(encoded)"

            XCTAssertNotNil(URL(string: urlString),
                "URL with query '\(query)' must be valid after percent-encoding")
        }
    }

    /// Spaces in the query are encoded as %20 (urlQueryAllowed does not encode spaces
    /// in the same way as +), confirming the encoding choice in the PR.
    func testQuerySpacesArePercentEncoded() {
        let query = "hello world"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        // urlQueryAllowed encodes space as %20
        XCTAssertTrue(encoded.contains("%20") || !encoded.contains(" "),
            "Spaces in the query must be encoded")
    }

    /// The fallback `?? q` is used when percent encoding returns nil; verify that for
    /// well-formed strings percent encoding always succeeds (returns non-nil).
    func testPercentEncodingReturnsNonNilForTypicalQueries() {
        let queries = ["from:x@y.com", "label:unread", "has:attachment", ""]
        for query in queries {
            let result = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            XCTAssertNotNil(result,
                "addingPercentEncoding must return non-nil for query: '\(query)'")
        }
    }

    // MARK: - GmailService: Gmail not enabled (integration via WritersApp)

    func testListGmailMessagesThrowsGmailNotEnabledWhenDisabled() async {
        let app = WritersApp()
        XCTAssertFalse(app.isGmailEnabled)
        do {
            _ = try await app.listGmailMessages()
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesWithCustomMaxResultsThrowsGmailNotEnabled() async {
        let app = WritersApp()
        do {
            _ = try await app.listGmailMessages(maxResults: 5)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesWithQueryThrowsGmailNotEnabled() async {
        let app = WritersApp()
        do {
            _ = try await app.listGmailMessages(query: "from:agent@example.com")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - BrowserService URL Validation Tests

final class BrowserServiceURLValidationTests: XCTestCase {

    var browser: BrowserService!

    override func setUp() {
        super.setUp()
        browser = BrowserService()
    }

    override func tearDown() {
        browser = nil
        super.tearDown()
    }

    // MARK: - Invalid URL scheme throws CoworkError.invalidURL

    func testFetchWithFileSchemeThrowsInvalidURL() async {
        do {
            _ = try await browser.fetch(urlString: "file:///etc/hosts")
            XCTFail("Expected CoworkError.invalidURL for file:// URL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchWithFTPSchemeThrowsInvalidURL() async {
        do {
            _ = try await browser.fetch(urlString: "ftp://example.com/file.txt")
            XCTFail("Expected CoworkError.invalidURL for ftp:// URL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testFetchWithMalformedURLThrowsInvalidURL() async {
        do {
            _ = try await browser.fetch(urlString: "not a url at all")
            XCTFail("Expected CoworkError.invalidURL for malformed URL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchWithEmptyStringThrowsInvalidURL() async {
        do {
            _ = try await browser.fetch(urlString: "")
            XCTFail("Expected CoworkError.invalidURL for empty string")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - History management (not affected by the range change, but confirms
    //         clearHistory() and initial state are stable after the PR)

    func testInitialHistoryIsEmpty() {
        XCTAssertTrue(browser.history.isEmpty)
    }

    func testClearHistoryLeavesHistoryEmpty() {
        browser.clearHistory()
        XCTAssertTrue(browser.history.isEmpty)
    }

    // MARK: - Through WritersApp facade

    func testBrowseURLWithInvalidSchemeThrowsInvalidURL() async {
        let app = WritersApp()
        do {
            _ = try await app.browseURL("javascript:alert(1)")
            XCTFail("Expected CoworkError.invalidURL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrowseURLWithMalformedURLThrowsInvalidURL() async {
        let app = WritersApp()
        do {
            _ = try await app.browseURL("::bad-url::")
            XCTFail("Expected CoworkError.invalidURL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - viewGmailInbox maxResults Parsing Logic Tests

/// The PR simplified the viewGmailInbox CLI function's maxResults parsing:
/// Old:  validates that the input is in range 1–100, returns an error message if not.
/// New:  `Int(maxInput) ?? 10` — any valid integer is accepted; invalid input defaults to 10.
///
/// Since the CLI function itself is not exported as public API, these tests verify the
/// equivalent parsing logic directly.
final class GmailInboxMaxResultsParsingTests: XCTestCase {

    /// Replicates the new parsing logic from viewGmailInbox.
    private func parseMaxResults(from input: String) -> Int {
        return Int(input) ?? 10
    }

    func testEmptyInputDefaultsToTen() {
        XCTAssertEqual(parseMaxResults(from: ""), 10)
    }

    func testWhitespaceInputDefaultsToTen() {
        // The old implementation trimmed whitespace; the new implementation passes the raw
        // readLine() result directly to Int(_:). A whitespace-only string returns nil from
        // Int(_:), so the default of 10 is used.
        XCTAssertEqual(parseMaxResults(from: "   "), 10,
            "Whitespace-only input must default to 10 under the new parsing logic")
    }

    func testValidIntegerIsParsed() {
        XCTAssertEqual(parseMaxResults(from: "5"), 5)
        XCTAssertEqual(parseMaxResults(from: "10"), 10)
        XCTAssertEqual(parseMaxResults(from: "50"), 50)
        XCTAssertEqual(parseMaxResults(from: "100"), 100)
    }

    /// Under the old implementation, values > 100 were invalid and returned an error.
    /// Under the new implementation they are accepted as-is.
    func testValueAboveOldUpperBoundIsNowAccepted() {
        XCTAssertEqual(parseMaxResults(from: "200"), 200,
            "Values above 100 must now be accepted; the range validation was removed")
        XCTAssertEqual(parseMaxResults(from: "1000"), 1000)
    }

    /// Under the old implementation, 0 was invalid (range was 1–100).
    /// Under the new implementation it is accepted.
    func testZeroIsNowAccepted() {
        XCTAssertEqual(parseMaxResults(from: "0"), 0,
            "Zero must now be accepted since the lower-bound validation was removed")
    }

    /// Under the old implementation, negative values were invalid.
    /// Under the new implementation they are accepted.
    func testNegativeValueIsNowAccepted() {
        XCTAssertEqual(parseMaxResults(from: "-1"), -1,
            "Negative integers must now be accepted since range validation was removed")
    }

    func testNonNumericInputDefaultsToTen() {
        XCTAssertEqual(parseMaxResults(from: "abc"), 10)
        XCTAssertEqual(parseMaxResults(from: "ten"), 10)
        XCTAssertEqual(parseMaxResults(from: "1a"), 10)
    }

    func testDefaultValueIsExactlyTen() {
        // Regression: the default in the old code was also 10; verify it hasn't changed.
        XCTAssertEqual(parseMaxResults(from: ""), 10)
    }
}

// MARK: - CoworkError Model Tests

final class CoworkErrorModelTests: XCTestCase {

    func testAllErrorCasesHaveNonNilErrorDescription() {
        let id = UUID()
        let errors: [CoworkError] = [
            .gmailNotEnabled,
            .invalidOAuthToken,
            .prospectNotFound(id),
            .browserFetchFailed("timeout"),
            .networkError("500 Internal Server Error"),
            .invalidURL
        ]
        for coworkError in errors {
            XCTAssertNotNil(coworkError.errorDescription,
                "errorDescription must not be nil for CoworkError.\(coworkError)")
            XCTAssertFalse(coworkError.errorDescription!.isEmpty,
                "errorDescription must not be empty for CoworkError.\(coworkError)")
        }
    }

    func testProspectNotFoundErrorContainsUUID() {
        let id = UUID()
        let error = CoworkError.prospectNotFound(id)
        XCTAssertTrue(error.errorDescription?.contains(id.uuidString) ?? false,
            "prospectNotFound errorDescription must include the UUID")
    }

    func testBrowserFetchFailedContainsReason() {
        let reason = "HTTP 404 Not Found"
        let error = CoworkError.browserFetchFailed(reason)
        XCTAssertTrue(error.errorDescription?.contains(reason) ?? false,
            "browserFetchFailed errorDescription must include the reason string")
    }

    func testNetworkErrorContainsMessage() {
        let message = "connection reset"
        let error = CoworkError.networkError(message)
        XCTAssertTrue(error.errorDescription?.contains(message) ?? false,
            "networkError errorDescription must include the message")
    }
}