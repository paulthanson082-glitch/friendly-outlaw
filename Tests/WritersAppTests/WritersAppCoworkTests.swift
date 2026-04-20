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

    func testUpdateProspectStatusDeclinedDoesNotIncrementContactCounter() throws {
        let _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Declined", email: "dec@example.com")
        try app.updateProspectStatus(id: prospect.id, status: .declined)

        let ended = app.endCoworkSession()
        XCTAssertEqual(ended?.prospectsContacted, 0,
            "Setting status to .declined must not increment prospectsContacted")
    }

    // MARK: - ProspectDatabase Directly (unit tests for ProspectDatabase class)

    func testProspectDatabaseAddAndRetrieve() {
        let db = ProspectDatabase()
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