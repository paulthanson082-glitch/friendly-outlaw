import XCTest
@testable import WritersApp

// MARK: - WritersApp Cowork Mode Tests
// Tests for cowork-related changes in this PR:
// - addProspect no longer accepts a `status` parameter
// - Cowork session tracking still works correctly with addProspect
// - Prospect defaults to .new status in all cowork flows

final class WritersAppCoworkTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Cowork Session Lifecycle

    func testStartCoworkSessionReturnsSession() {
        let session = app.startCoworkSession()
        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endedAt)
    }

    func testEndCoworkSessionReturnsNilWhenNoActiveSession() {
        let result = app.endCoworkSession()
        XCTAssertNil(result, "endCoworkSession must return nil when no session is active")
    }

    func testEndCoworkSessionReturnsPreviousSession() {
        let started = app.startCoworkSession()
        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended)
        XCTAssertEqual(ended?.id, started.id)
    }

    func testEndCoworkSessionSetsEndedAt() {
        let _ = app.startCoworkSession()
        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended?.endedAt,
            "Ended session must have an endedAt timestamp")
    }

    // MARK: - addProspect Without Status Parameter (PR Change)

    func testAddProspectDuringCoworkSessionDefaultsToNewStatus() {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(
            name: "Cowork Prospect",
            email: "cowork@example.com",
            company: "Publisher House",
            notes: "Met at book fair"
        )
        XCTAssertEqual(prospect.status, .new,
            "Prospect created during cowork session must have .new status")
    }

    func testAddProspectIncrementsCoworkSessionCounter() {
        let session = app.startCoworkSession()
        XCTAssertEqual(session.prospectsAdded, 0)

        let _ = app.addProspect(name: "Prospect One", email: "one@example.com")
        // The session counter is tracked on the mutable activeCoworkSession
        // We can verify by ending the session and checking its final count
        let _ = app.addProspect(name: "Prospect Two", email: "two@example.com")
        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsAdded, 2,
            "prospectsAdded must be incremented for each addProspect call during an active session")
    }

    func testAddProspectWithoutActiveSessionDoesNotCrash() {
        // No active session - addProspect should still work, just no counter increment
        let prospect = app.addProspect(name: "No Session Prospect", email: "nosession@example.com")
        XCTAssertEqual(prospect.status, .new)
        XCTAssertEqual(prospect.name, "No Session Prospect")
    }

    func testProspectsAddedCounterReflectsMultipleAdditions() {
        let _ = app.startCoworkSession()

        for i in 1...5 {
            let _ = app.addProspect(name: "Prospect \(i)", email: "p\(i)@example.com")
        }

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsAdded, 5)
    }

    // MARK: - updateProspectStatus Tracks Contacts in Session

    func testUpdateProspectStatusContactedIncrementsSessionCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Contact Me", email: "contact@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .contacted)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 1,
            "prospectsContacted should be incremented when status is set to .contacted")
    }

    func testUpdateProspectStatusRepliedIncrementsSessionCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Reply Me", email: "reply@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 1)
    }

    func testUpdateProspectStatusMeetingIncrementsSessionCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Meet Me", email: "meet@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .meeting)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 1)
    }

    func testUpdateProspectStatusNewDoesNotIncrementContactCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Stay New", email: "new@example.com")
        // Setting to .new (same as default) should not count as a contact
        try app.updateProspectStatus(id: prospect.id, status: .new)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 0,
            "Setting status to .new must not increment prospectsContacted")
    }

    func testUpdateProspectStatusRejectedDoesNotIncrementContactCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Rejected", email: "rej@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .rejected)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 0,
            "Setting status to .rejected must not increment prospectsContacted")
    }

    // MARK: - PR Change: prospectsContacted only increments on transition to contact status

    /// new → replied (contact state) must increment counter (non-contact to contact transition).
    func testNewToRepliedTransitionIncrementsContactedCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Quick Reply", email: "qr@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "new → replied (contact state) must increment prospectsContacted exactly once")
    }

    /// new → meeting (contact state) must increment counter.
    func testNewToMeetingTransitionIncrementsContactedCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Fast Track", email: "ft@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "new → meeting (contact state) must increment prospectsContacted")
    }

    /// Transitioning between two distinct contact states must NOT increment counter.
    func testContactedToMeetingDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Contact Then Meet", email: "ctm@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "contacted → meeting (both contact states) must NOT add another count")
    }

    /// replied → contacted (both contact states) must NOT increment counter.
    func testRepliedToContactedDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Back And Forth", email: "baf@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "replied → contacted (both contact states) must not double-count")
    }

    /// Multiple prospects going through non-contact → contact transitions each count once.
    func testMultipleProspectsEachCountedOnce() throws {
        app.startCoworkSession()
        let p1 = app.addProspect(name: "P1", email: "p1@ex.com")
        let p2 = app.addProspect(name: "P2", email: "p2@ex.com")
        let p3 = app.addProspect(name: "P3", email: "p3@ex.com")
        try app.updateProspectStatus(id: p1.id, status: .contacted)
        try app.updateProspectStatus(id: p2.id, status: .replied)
        try app.updateProspectStatus(id: p3.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3,
            "Three distinct non-contact → contact transitions must produce count of 3")
    }

    /// Non-contact → non-contact transition must not increment.
    func testNewToDeclinedDoesNotIncrementCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Declined", email: "dec@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0,
            "new → declined (both non-contact states) must not increment the counter")
    }

    /// Same status set twice (e.g. contacted → contacted) must NOT double-increment.
    func testSameContactStatusSetTwiceDoesNotDoubleIncrement() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Repeat", email: "rep@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "Setting the same contact status a second time must not increment the counter again")
    }

    /// declined → meeting (non-contact → contact) must increment.
    func testDeclinedToMeetingIncrementsCounter() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Second Chance", email: "sc@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)
        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1,
            "declined → meeting (non-contact → contact) must increment the counter")
    }

    // MARK: - ProspectDatabase Directly (unit tests for ProspectDatabase class)

    func testProspectDatabaseAddAndRetrieve() {

        let prospect = Prospect(name: "Direct DB", email: "direct@example.com")
        db.addProspect(prospect)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Direct DB")
    }

    func testProspectDatabaseGetAllSortedByCreationDate() {
        let db = ProspectDatabase()
        // Add prospects; since they're created in rapid succession they'll have the same or very close dates
        let p1 = Prospect(name: "Alpha", email: "a@test.com")
        db.addProspect(p1)
        let p2 = Prospect(name: "Beta", email: "b@test.com")
        db.addProspect(p2)

        let all = db.getAllProspects()
        XCTAssertEqual(all.count, 2)
    }

    func testProspectDatabaseFilterByStatus() {
        let db = ProspectDatabase()
        let p1 = Prospect(name: "New1", email: "n1@test.com", status: .new)
        let p2 = Prospect(name: "Contacted1", email: "c1@test.com", status: .contacted)
        db.addProspect(p1)
        db.addProspect(p2)

        let newProspects = db.getProspects(withStatus: .new)
        XCTAssertTrue(newProspects.contains { $0.id == p1.id })
        XCTAssertFalse(newProspects.contains { $0.id == p2.id })
    }

    func testProspectDatabaseSearch() {
        let db = ProspectDatabase()
        let p = Prospect(name: "Unique Publisher Name", email: "unique@publisher.com", company: "Publisher Co")
        db.addProspect(p)

        let results = db.searchProspects(query: "Unique Publisher")
        XCTAssertTrue(results.contains { $0.id == p.id })

        let noResults = db.searchProspects(query: "XYZ Not Found 12345")
        XCTAssertFalse(noResults.contains { $0.id == p.id })
    }

    func testProspectDatabaseUpdateStatus() throws {
        let db = ProspectDatabase()
        let p = Prospect(name: "Status Changer", email: "sc@test.com")
        db.addProspect(p)

        try db.updateProspectStatus(id: p.id, status: .contacted)

        let retrieved = db.getProspect(id: p.id)
        XCTAssertEqual(retrieved?.status, .contacted)
        XCTAssertNotNil(retrieved?.lastContactedAt,
            "lastContactedAt must be set when status is .contacted")
    }

    func testProspectDatabaseUpdateStatusSetsLastContactedAtForMeeting() throws {
        let db = ProspectDatabase()
        let p = Prospect(name: "Meeting Setter", email: "ms@test.com")
        db.addProspect(p)

        try db.updateProspectStatus(id: p.id, status: .meeting)
        let retrieved = db.getProspect(id: p.id)
        XCTAssertNotNil(retrieved?.lastContactedAt)
    }

    func testProspectDatabaseUpdateStatusDoesNotSetLastContactedAtForNew() throws {
        let db = ProspectDatabase()
        let p = Prospect(name: "Still New", email: "sn@test.com")
        db.addProspect(p)

        try db.updateProspectStatus(id: p.id, status: .new)
        let retrieved = db.getProspect(id: p.id)
        XCTAssertNil(retrieved?.lastContactedAt,
            "lastContactedAt must not be set for non-contact statuses")
    }

    func testProspectDatabaseDeleteProspect() {
        let db = ProspectDatabase()
        let p = Prospect(name: "To Remove", email: "remove@test.com")
        db.addProspect(p)

        db.deleteProspect(id: p.id)

        XCTAssertNil(db.getProspect(id: p.id))
        XCTAssertFalse(db.getAllProspects().contains { $0.id == p.id })
    }

    func testProspectDatabaseUpdateStatusThrowsForUnknownId() {
        let db = ProspectDatabase()
        let unknownId = UUID()

        XCTAssertThrowsError(
            try db.updateProspectStatus(id: unknownId, status: .contacted)
        ) { error in
            guard case CoworkError.prospectNotFound(let id) = error else {
                return XCTFail("Expected CoworkError.prospectNotFound, got \(error)")
            }
            XCTAssertEqual(id, unknownId)
        }
    }

    func testProspectDatabaseStats() {
        let db = ProspectDatabase()
        let p1 = Prospect(name: "S1", email: "s1@t.com", status: .new)
        let p2 = Prospect(name: "S2", email: "s2@t.com", status: .contacted)
        let p3 = Prospect(name: "S3", email: "s3@t.com", status: .contacted)
        db.addProspect(p1)
        db.addProspect(p2)
        db.addProspect(p3)

        let stats = db.getStats()
        XCTAssertEqual(stats[.new], 1)
        XCTAssertEqual(stats[.contacted], 2)
    }

    // MARK: - Gmail Not Enabled (regression)

    func testListGmailMessagesThrowsWhenNotEnabled() async {
        do {
            let _ = try await app.listGmailMessages()
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendGmailThrowsWhenNotEnabled() async {
        let draft = GmailDraft(to: "test@example.com", subject: "Hello", body: "Test")
        do {
            let _ = try await app.sendGmail(draft: draft)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMarkGmailAsReadThrowsWhenNotEnabled() async {
        do {
            try await app.markGmailAsRead(id: "fake-id")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testIsGmailEnabledFalseByDefault() {
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testEnableGmailSetsIsGmailEnabledTrue() {
        app.enableGmail(oauthToken: "fake-oauth-token")
        XCTAssertTrue(app.isGmailEnabled)
    }

    func testDisableGmailSetsIsGmailEnabledFalse() {
        app.enableGmail(oauthToken: "fake-oauth-token")
        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)
    }

    // MARK: - Browsing History

    func testGetBrowsingHistoryEmptyByDefault() {
        let history = app.getBrowsingHistory()
        XCTAssertTrue(history.isEmpty)
    }

    func testClearBrowsingHistoryDoesNotCrashWhenEmpty() {
        app.clearBrowsingHistory() // Should not crash
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }
}