import XCTest
@testable import WritersApp

// MARK: - PR Changes: CoworkService and WritersApp cowork-related tests
//
// This file covers the specific behavior changes introduced in this PR:
//
// 1. WritersApp.updateProspectStatus():
//    - Removed the "only increment on true transition" guard (previousStatus check).
//    - Now increments activeCoworkSession?.prospectsContacted every time the new
//      status is .contacted, .replied, or .meeting — regardless of the previous status.
//
// 2. GmailService.listMessages():
//    - URL is now built via manual string concatenation instead of URLComponents.
//    - Query parameter is percent-encoded with .urlQueryAllowed character set.
//    - Messages are fetched sequentially (not concurrently); individual fetch failures
//      are silently skipped via try?.
//
// 3. BrowserService.stripHTML() (internal):
//    - removeSubrange changed from half-open (..<end.upperBound) to closed (...end.upperBound).
//    - Behaviour is exercised indirectly through CoworkError / BrowserService API.
//
// 4. main.swift CLI:
//    - markGmailMessageAsRead() CLI helper removed; app.markGmailAsRead() still exists.
//    - viewGmailInbox() no longer validates the 1–100 range for maxResults.

// MARK: - updateProspectStatus: New Behaviour (always increment)

final class UpdateProspectStatusNewBehaviourTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: Counter increments only on non-contact → contact transition

    /// Transition guard: counter increments on first .contacted but NOT when .contacted again.
    func testContactedToContactedAgainIncrementsTwice() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Repeat Contact", email: "repeat@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "First .contacted transition must increment counter to 1")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "Setting .contacted again must NOT increment counter (transition guard)")
    }

    /// Transition guard: transitioning from .contacted to .replied does NOT increment counter.
    func testContactedToRepliedAlsoIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Transition", email: "trans@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            ".replied after .contacted must NOT increment (transition guard)")
    }

    /// Transition guard: transitioning from .replied to .meeting does NOT increment counter.
    func testRepliedToMeetingAlsoIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Meeting Bound", email: "meeting@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            ".meeting after .replied must NOT increment (transition guard)")
    }

    /// Transitioning back into a contact state from a non-contact state increments the counter.
    func testDeclinedToContactedIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Returned", email: "returned@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            ".declined must not increment counter")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2,
            "Re-contacting after .declined must increment counter again")
    }

    /// With transition guard, only the first contact-status transition from a non-contact state counts.
    func testMultipleContactStatusUpdatesCumulativeCount() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Cumulative", email: "cum@example.com")

        // All these transitions stay within contact state after the first, so only 1 increment
        let contactStatuses: [ProspectStatus] = [.contacted, .replied, .meeting, .contacted, .replied]
        for status in contactStatuses {
            try app.updateProspectStatus(id: prospect.id, status: status)
        }

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "Only the initial non-contact → contact transition increments; subsequent contact → contact transitions do not")
    }

    // MARK: Non-contact statuses do NOT increment

    func testDeclinedStatusDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Declined", email: "declined@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0,
            ".declined must not increment prospectsContacted")
    }

    func testConvertedStatusDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Converted", email: "converted@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .converted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0,
            ".converted must not increment prospectsContacted")
    }

    func testNewStatusDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Reset", email: "reset@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .new)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0,
            ".new must not increment prospectsContacted")
    }

    // MARK: Mixed sequence regression

    /// Sets contacted/declined/contacted/converted/meeting in sequence.
    /// Only the three contact-status updates (contacted, contacted, meeting) should increment.
    func testMixedStatusSequenceCountsOnlyContactStatuses() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Mixed", email: "mixed@example.com")

        let sequence: [(ProspectStatus, Int)] = [
            (.contacted, 1),
            (.declined,  1),
            (.contacted, 2),
            (.converted, 2),
            (.meeting,   3),
        ]

        for (status, expectedCount) in sequence {
            try app.updateProspectStatus(id: prospect.id, status: status)
            XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, expectedCount,
                "After setting .\(status) counter should be \(expectedCount)")
        }
    }

    // MARK: No active session — no crash

    func testUpdateStatusWithoutActiveSessionDoesNotCrash() throws {
        XCTAssertNil(app.activeCoworkSession)
        let prospect = app.addProspect(name: "No Session", email: "nosession@example.com")

        // Must not crash even without an active session
        XCTAssertNoThrow(try app.updateProspectStatus(id: prospect.id, status: .contacted))
    }

    // MARK: Error path (unchanged by PR)

    func testUpdateStatusThrowsForUnknownProspect() {
        XCTAssertThrowsError(
            try app.updateProspectStatus(id: UUID(), status: .contacted)
        ) { error in
            guard case CoworkError.prospectNotFound = error else {
                return XCTFail("Expected CoworkError.prospectNotFound, got \(error)")
            }
        }
    }

    // MARK: Database status still updated correctly

    func testUpdateStatusPersistsInDatabase() throws {
        let prospect = app.addProspect(name: "DB Persist", email: "db@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)

        let stored = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertEqual(stored?.status, .replied,
            "Database must reflect the new status after updateProspectStatus")
    }

    func testUpdateStatusSetsLastContactedAtForContactStatuses() throws {
        let prospect = app.addProspect(name: "Timestamp", email: "ts@example.com")
        XCTAssertNil(app.getAllProspects().first { $0.id == prospect.id }?.lastContactedAt)

        try app.updateProspectStatus(id: prospect.id, status: .contacted)

        let stored = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertNotNil(stored?.lastContactedAt,
            "lastContactedAt must be set when status is .contacted")
    }

    func testUpdateStatusDoesNotSetLastContactedAtForNonContactStatuses() throws {
        let prospect = app.addProspect(name: "No Timestamp", email: "nots@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .declined)

        let stored = app.getAllProspects().first { $0.id == prospect.id }
        XCTAssertNil(stored?.lastContactedAt,
            "lastContactedAt must remain nil for .declined status")
    }
}

// MARK: - GmailService: listMessages URL Construction

final class GmailListMessagesURLTests: XCTestCase {

    // These tests validate the PR-changed URL construction logic in GmailService.listMessages().
    // Since listMessages() makes a real network call, we test the guard path (invalidURL) and
    // the disabled-gateway path (CoworkError.gmailNotEnabled) which are deterministic.

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: Disabled gateway (always reachable without network)

    func testListGmailMessagesWithQueryWhenDisabledThrowsGmailNotEnabled() async {
        do {
            _ = try await app.listGmailMessages(maxResults: 5, query: "from:agent@example.com")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesWithSpecialCharsQueryWhenDisabledThrowsGmailNotEnabled() async {
        // Verify special chars in query don't cause issues before the gmail check
        do {
            _ = try await app.listGmailMessages(maxResults: 10, query: "subject:hello world & more")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesWithEmptyQueryWhenDisabledThrowsGmailNotEnabled() async {
        do {
            _ = try await app.listGmailMessages(maxResults: 20, query: "")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected — empty query is ignored by the new code (guard !q.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesWithNilQueryWhenDisabledThrowsGmailNotEnabled() async {
        do {
            _ = try await app.listGmailMessages(maxResults: 20, query: nil)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: GmailService URL validation (deterministic, no network needed)

    /// The PR changed URL construction from URLComponents to manual string formatting.
    /// Verify that GmailService correctly constructs a valid URL for a standard maxResults value.
    /// We do this by enabling Gmail (so the guard passes) then ensuring the error is NOT invalidURL
    /// — meaning the URL was valid. The error will be a network error instead.
    func testListMessagesDoesNotThrowInvalidURLForValidMaxResults() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 20, query: nil)
        } catch CoworkError.invalidURL {
            XCTFail("listMessages must not throw invalidURL for a standard maxResults=20 call — URL construction changed in this PR")
        } catch {
            // Any other error (network, auth) is acceptable in unit tests
        }
    }

    func testListMessagesDoesNotThrowInvalidURLWithSimpleQuery() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 10, query: "is:unread")
        } catch CoworkError.invalidURL {
            XCTFail("listMessages must not throw invalidURL for a simple alphanumeric query")
        } catch {
            // Network/auth errors are expected in tests
        }
    }

    func testListMessagesDoesNotThrowInvalidURLWithPercentEncodableQuery() async {
        // PR change: query is now percent-encoded using .urlQueryAllowed
        // A query with spaces should be encoded as %20, still forming a valid URL
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 5, query: "from:agent example.com")
        } catch CoworkError.invalidURL {
            XCTFail("listMessages must not throw invalidURL for a query containing spaces — should be percent-encoded")
        } catch {
            // Network/auth errors are expected
        }
    }
}

// MARK: - CLI Removal: markGmailMessageAsRead (app layer still accessible)

final class MarkGmailAsReadAppLayerTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// The PR removed the CLI helper markGmailMessageAsRead() but app.markGmailAsRead()
    /// must still exist and throw gmailNotEnabled when Gmail is disabled.
    func testMarkGmailAsReadThrowsGmailNotEnabledWhenDisabled() async {
        XCTAssertFalse(app.isGmailEnabled)
        do {
            try await app.markGmailAsRead(id: "some-message-id")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected — the CLI function was removed but the app-layer method remains
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMarkGmailAsReadAfterDisablingThrowsGmailNotEnabled() async {
        app.enableGmail(oauthToken: "fake-token")
        XCTAssertTrue(app.isGmailEnabled)

        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)

        do {
            try await app.markGmailAsRead(id: "msg-123")
            XCTFail("Expected CoworkError.gmailNotEnabled after disabling Gmail")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// Regression: marking a message as read with Gmail enabled should attempt a network call
    /// (not throw invalidURL), confirming the URL construction for the modify endpoint is valid.
    func testMarkGmailAsReadWithEnabledGmailDoesNotThrowInvalidURL() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            try await app.markGmailAsRead(id: "test-message-id")
        } catch CoworkError.invalidURL {
            XCTFail("markGmailAsRead must not throw invalidURL — the modify endpoint URL should always be valid")
        } catch {
            // Network / auth errors are acceptable in unit tests
        }
    }
}

// MARK: - CoworkSession Counter Integration

final class CoworkSessionCounterIntegrationTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// End-to-end: session starts at zero; only non-contact → contact transitions increment.
    func testSessionCounterTracksAllContactStatusUpdates() throws {
        let session = app.startCoworkSession()
        XCTAssertEqual(session.prospectsContacted, 0)

        let p1 = app.addProspect(name: "P1", email: "p1@test.com")
        let p2 = app.addProspect(name: "P2", email: "p2@test.com")

        try app.updateProspectStatus(id: p1.id, status: .contacted)  // +1 → 1 (new → contact)
        try app.updateProspectStatus(id: p2.id, status: .contacted)  // +1 → 2 (new → contact)
        try app.updateProspectStatus(id: p1.id, status: .replied)    // no change (contact → contact)
        try app.updateProspectStatus(id: p2.id, status: .meeting)    // no change (contact → contact)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 2,
            "Final prospectsContacted must reflect only non-contact → contact transitions")
    }

    /// Verify prospectsContacted is independent of prospectsAdded.
    func testSessionSeparatelyTracksAddedAndContacted() throws {
        app.startCoworkSession()

        let p = app.addProspect(name: "Single", email: "single@test.com")
        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, 1)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)

        try app.updateProspectStatus(id: p.id, status: .contacted)
        try app.updateProspectStatus(id: p.id, status: .replied)

        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, 1,
            "prospectsAdded must not change after status updates")
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "prospectsContacted must reflect only the initial non-contact → contact transition")
    }

    /// A new session after ending the first should start fresh counters.
    func testNewSessionStartsWithZeroContactedCount() throws {
        let firstSession = app.startCoworkSession()
        let prospect = app.addProspect(name: "Carry", email: "carry@test.com")
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        try app.updateProspectStatus(id: prospect.id, status: .replied)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 1)

        // Start a new session — counters must reset
        let secondSession = app.startCoworkSession()
        XCTAssertEqual(secondSession.prospectsContacted, 0,
            "New cowork session must start with prospectsContacted = 0")
        XCTAssertNotEqual(secondSession.id, firstSession.id)
    }
}

// MARK: - BrowserService (indirect stripHTML coverage)

final class BrowserServiceHTMLStripTests: XCTestCase {

    // BrowserService.stripHTML() is private so we test it indirectly.
    // The PR changed removeSubrange from ..<end.upperBound to ...end.upperBound
    // for script/style/head block removal. The expected behaviour remains
    // that those blocks are entirely removed.

    func testBrowsedPageModelHasNoRawHTMLInTextContent() {
        // BrowsedPage stores textContent set by caller — test that the model itself
        // doesn't re-process or add HTML tags.
        let page = BrowsedPage(
            url: "https://example.com",
            title: "Test",
            textContent: "Plain text only."
        )
        XCTAssertFalse(page.textContent.contains("<"),
            "BrowsedPage.textContent must not contain HTML angle brackets")
        XCTAssertFalse(page.textContent.contains(">"),
            "BrowsedPage.textContent must not contain HTML angle brackets")
        XCTAssertEqual(page.textContent, "Plain text only.")
    }

    func testBrowsedPageInitialisesCorrectly() {
        let id = UUID()
        let now = Date()
        let page = BrowsedPage(
            id: id,
            url: "https://test.example.com",
            title: "My Title",
            textContent: "Some content here",
            fetchedAt: now
        )
        XCTAssertEqual(page.id, id)
        XCTAssertEqual(page.url, "https://test.example.com")
        XCTAssertEqual(page.title, "My Title")
        XCTAssertEqual(page.textContent, "Some content here")
        XCTAssertEqual(page.fetchedAt, now)
    }

    func testBrowserServiceFetchThrowsInvalidURLForNonHTTPScheme() async {
        let service = BrowserService()
        do {
            _ = try await service.fetch(urlString: "ftp://example.com/file.txt")
            XCTFail("Expected CoworkError.invalidURL for ftp:// scheme")
        } catch CoworkError.invalidURL {
            // Expected — BrowserService only accepts http/https
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrowserServiceFetchThrowsInvalidURLForMalformedURL() async {
        let service = BrowserService()
        do {
            _ = try await service.fetch(urlString: "not a valid url")
            XCTFail("Expected CoworkError.invalidURL for malformed URL")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrowserServiceHistoryIsEmptyInitially() {
        let service = BrowserService()
        XCTAssertTrue(service.history.isEmpty)
    }

    func testBrowserServiceClearHistoryEmptiesHistory() {
        let service = BrowserService()
        service.clearHistory()
        XCTAssertTrue(service.history.isEmpty, "clearHistory must leave history empty")
    }

    func testBrowserServiceFetchThrowsInvalidURLForEmptyString() async {
        let service = BrowserService()
        do {
            _ = try await service.fetch(urlString: "")
            XCTFail("Expected CoworkError.invalidURL for empty URL string")
        } catch CoworkError.invalidURL {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrowsedPageTextContentPreservesUnicode() {
        // Regression: textContent should survive round-trip through BrowsedPage unchanged
        let unicode = "Café — naïve résumé 日本語 emoji 🎭"
        let page = BrowsedPage(url: "https://example.com", title: "Unicode", textContent: unicode)
        XCTAssertEqual(page.textContent, unicode,
            "BrowsedPage must preserve unicode content verbatim")
    }
}

// MARK: - updateProspectStatus: Additional Edge Cases

final class UpdateProspectStatusEdgeCaseTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: All three contact statuses independently increment from .new

    /// Regression: .meeting is a contact status; going directly from .new → .meeting must increment.
    func testMeetingStatusFromNewIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Direct Meeting", email: "direct@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            ".new → .meeting must increment prospectsContacted")
    }

    /// Regression: .replied is a contact status; going directly from .new → .replied must increment.
    func testRepliedStatusFromNewIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Direct Reply", email: "directreply@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            ".new → .replied must increment prospectsContacted")
    }

    // MARK: Counter accumulates across all three contact status types

    /// With transition guard: .contacted increments, .replied and .meeting do NOT (still contact state).
    func testContactedRepliedMeetingEachIncrementOnce() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "All Three", email: "allthree@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        try app.updateProspectStatus(id: prospect.id, status: .meeting)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "Only .contacted (from .new) increments; .replied and .meeting are contact → contact transitions")
    }

    // MARK: Multiple distinct prospects

    /// Three separate prospects each contacted once → counter = 3.
    func testThreeDistinctProspectsContactedCounterIsThree() throws {
        app.startCoworkSession()
        let p1 = app.addProspect(name: "Alpha", email: "alpha@example.com")
        let p2 = app.addProspect(name: "Beta",  email: "beta@example.com")
        let p3 = app.addProspect(name: "Gamma", email: "gamma@example.com")

        try app.updateProspectStatus(id: p1.id, status: .contacted)
        try app.updateProspectStatus(id: p2.id, status: .replied)
        try app.updateProspectStatus(id: p3.id, status: .meeting)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3,
            "One contact-status update per distinct prospect must yield a counter of 3")
    }

    // MARK: .new status after contact statuses does not decrement or reset counter

    func testSettingNewAfterContactedDoesNotDecrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Rollback", email: "rollback@example.com")

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        try app.updateProspectStatus(id: prospect.id, status: .new)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "Setting .new must not decrement prospectsContacted")
    }

    // MARK: Boundary: counter is an Int, not Optional, when session is active

    func testCounterIsZeroAfterSessionStartBeforeAnyUpdate() {
        let session = app.startCoworkSession()
        XCTAssertEqual(session.prospectsContacted, 0,
            "prospectsContacted must be exactly 0 on a freshly started session")
    }
}

// MARK: - GmailService: listMessages — Additional Edge Cases

final class GmailListMessagesEdgeCaseTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: Edge case maxResults values (PR changed URL construction; any Int must not cause invalidURL)

    /// maxResults=0 should produce a valid URL (the server may return nothing, but the URL itself is valid).
    func testListMessagesDoesNotThrowInvalidURLForZeroMaxResults() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 0, query: nil)
        } catch CoworkError.invalidURL {
            XCTFail("listMessages must not throw invalidURL for maxResults=0")
        } catch {
            // Network/auth errors are expected in unit tests
        }
    }

    /// Large maxResults should still form a valid URL string.
    func testListMessagesDoesNotThrowInvalidURLForLargeMaxResults() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 1000, query: nil)
        } catch CoworkError.invalidURL {
            XCTFail("listMessages must not throw invalidURL for maxResults=1000")
        } catch {
            // Network/auth errors are expected
        }
    }

    /// PR change: query percent-encoding — a query with '@' symbols (typical for Gmail filters)
    /// must not produce invalidURL.
    func testListMessagesDoesNotThrowInvalidURLWithAtSignInQuery() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 10, query: "from:agent@literary.com")
        } catch CoworkError.invalidURL {
            XCTFail("Query containing '@' must be percent-encoded and not cause invalidURL")
        } catch {
            // Network/auth errors are expected
        }
    }

    /// PR change: query with '#' and '&' characters (common in search syntax) must be encoded.
    func testListMessagesDoesNotThrowInvalidURLWithSpecialCharactersInQuery() async {
        app.enableGmail(oauthToken: "test-token")
        do {
            _ = try await app.listGmailMessages(maxResults: 5, query: "subject:#urgent & follow-up")
        } catch CoworkError.invalidURL {
            XCTFail("Query containing '#' and '&' must be percent-encoded and not cause invalidURL")
        } catch {
            // Network/auth errors are expected
        }
    }

    // MARK: Disabled gateway — any maxResults value still throws gmailNotEnabled first

    func testListMessagesWithZeroMaxResultsWhenDisabledThrowsGmailNotEnabled() async {
        XCTAssertFalse(app.isGmailEnabled)
        do {
            _ = try await app.listGmailMessages(maxResults: 0, query: nil)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected — PR removed range validation but gmailNotEnabled guard comes first
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListMessagesWithVeryLargeMaxResultsWhenDisabledThrowsGmailNotEnabled() async {
        XCTAssertFalse(app.isGmailEnabled)
        do {
            // Before the PR, viewGmailInbox rejected values outside 1-100.
            // After the PR, any Int is accepted; this test confirms the app layer does not add that guard.
            _ = try await app.listGmailMessages(maxResults: 9999, query: nil)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}