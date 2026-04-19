import XCTest
@testable import WritersApp

/// Tests for WritersApp Cowork Mode functionality as changed in this PR:
/// - addProspect no longer takes a status parameter
/// - Cowork session counters (prospectsAdded, prospectsContacted) still work
/// - ProspectDatabase CRUD operations
/// - GmailService guard (gmailNotEnabled error)
/// - BrowserService history management
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

    // MARK: - Cowork session lifecycle

    func testStartCoworkSessionCreatesSession() {
        let session = app.startCoworkSession()
        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endedAt)
    }

    func testStartCoworkSessionSetsActiveSession() {
        _ = app.startCoworkSession()
        XCTAssertNotNil(app.activeCoworkSession)
    }

    func testEndCoworkSessionReturnsSession() {
        _ = app.startCoworkSession()
        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended)
        XCTAssertNotNil(ended?.endedAt)
    }

    func testEndCoworkSessionClearsActiveSession() {
        _ = app.startCoworkSession()
        _ = app.endCoworkSession()
        XCTAssertNil(app.activeCoworkSession)
    }

    func testEndCoworkSessionWithoutActiveSessionReturnsNil() {
        let result = app.endCoworkSession()
        XCTAssertNil(result)
    }

    func testStartCoworkSessionReplacesExistingSession() {
        let first = app.startCoworkSession()
        let second = app.startCoworkSession()
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(app.activeCoworkSession?.id, second.id)
    }

    // MARK: - addProspect increments cowork session prospectsAdded

    func testAddProspectIncrementsProspectsAddedWhenSessionActive() {
        _ = app.startCoworkSession()
        let initialCount = app.activeCoworkSession?.prospectsAdded ?? 0
        _ = app.addProspect(name: "Test Prospect", email: "test@example.com")
        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, initialCount + 1)
    }

    func testAddMultipleProspectsIncrementsByOne() {
        _ = app.startCoworkSession()
        _ = app.addProspect(name: "Prospect 1", email: "p1@example.com")
        _ = app.addProspect(name: "Prospect 2", email: "p2@example.com")
        _ = app.addProspect(name: "Prospect 3", email: "p3@example.com")
        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, 3)
    }

    func testAddProspectWithoutSessionDoesNotCrash() {
        // No active session — should still add prospect to database without crash
        let prospect = app.addProspect(name: "No Session", email: "nosession@test.com")
        XCTAssertNotNil(prospect.id)
    }

    // MARK: - updateProspectStatus increments prospectsContacted

    func testUpdateStatusToContactedIncrementsCoworkSessionCounter() throws {
        _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Contacted Person", email: "c@example.com")
        let initialContacted = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, initialContacted + 1)
    }

    func testUpdateStatusToRepliedIncrementsCoworkSessionCounter() throws {
        _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Replied Person", email: "r@example.com")
        let initialContacted = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, initialContacted + 1)
    }

    func testUpdateStatusToMeetingIncrementsCoworkSessionCounter() throws {
        _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Meeting Person", email: "m@example.com")
        let initialContacted = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, initialContacted + 1)
    }

    func testUpdateStatusToDeclinedDoesNotIncrementCoworkSessionCounter() throws {
        _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Declined Person", email: "d@example.com")
        let initialContacted = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, initialContacted,
                       "declined status should not increment prospectsContacted")
    }

    func testUpdateStatusToConvertedDoesNotIncrementCoworkSessionCounter() throws {
        _ = app.startCoworkSession()
        let prospect = app.addProspect(name: "Converted Person", email: "cv@example.com")
        let initialContacted = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .converted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, initialContacted,
                       "converted status should not increment prospectsContacted")
    }

    // MARK: - ProspectDatabase: default status after addProspect

    func testNewProspectHasStatusNew() {
        let prospect = app.addProspect(name: "Fresh", email: "fresh@example.com")
        XCTAssertEqual(prospect.status, .new)
    }

    // MARK: - Gmail guard

    func testListGmailMessagesThrowsWhenGmailNotEnabled() async {
        do {
            _ = try await app.listGmailMessages()
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Expected CoworkError.gmailNotEnabled, got \(error)")
        }
    }

    func testIsGmailEnabledFalseByDefault() {
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testEnableAndDisableGmail() {
        app.enableGmail(oauthToken: "test-token")
        XCTAssertTrue(app.isGmailEnabled)
        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testSendGmailThrowsWhenGmailNotEnabled() async {
        let draft = GmailDraft(to: "x@x.com", subject: "Hi", body: "Hello")
        do {
            _ = try await app.sendGmail(draft: draft)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Expected CoworkError.gmailNotEnabled, got \(error)")
        }
    }

    // MARK: - Browser service

    func testGetBrowsingHistoryEmptyByDefault() {
        let history = app.getBrowsingHistory()
        XCTAssertTrue(history.isEmpty)
    }

    func testClearBrowsingHistory() async throws {
        // We can't easily fetch real URLs in unit tests, so just test clear on empty
        app.clearBrowsingHistory()
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }

    func testBrowseURLInvalidSchemeThrows() async {
        do {
            _ = try await app.browseURL("ftp://invalid.example.com")
            XCTFail("Expected error for invalid scheme")
        } catch {
            // Expected — BrowserService requires http/https
        }
    }

    // MARK: - ProspectDatabase CRUD

    func testGetProspectsWithStatusFiltersCorrectly() throws {
        let p1 = app.addProspect(name: "New Guy", email: "new@test.com")
        let p2 = app.addProspect(name: "Old Guy", email: "old@test.com")
        try app.updateProspectStatus(id: p2.id, status: .contacted)

        let newOnes = app.getProspects(withStatus: .new)
        let contactedOnes = app.getProspects(withStatus: .contacted)

        XCTAssertTrue(newOnes.contains { $0.id == p1.id })
        XCTAssertTrue(contactedOnes.contains { $0.id == p2.id })
        XCTAssertFalse(contactedOnes.contains { $0.id == p1.id })
    }

    func testProspectStatsReflectActualCounts() throws {
        _ = app.addProspect(name: "Stats A", email: "sa@test.com")
        _ = app.addProspect(name: "Stats B", email: "sb@test.com")
        let stats = app.getProspectStats()
        XCTAssertGreaterThanOrEqual(stats[.new] ?? 0, 2)
        // All ProspectStatus cases should have an entry
        for status in ProspectStatus.allCases {
            XCTAssertNotNil(stats[status], "Stats should include entry for \(status)")
        }
    }

    func testUpdateNonexistentProspectThrows() {
        let fakeId = UUID()
        XCTAssertThrowsError(try app.updateProspectStatus(id: fakeId, status: .contacted)) { error in
            guard case CoworkError.prospectNotFound(_) = error else {
                XCTFail("Expected CoworkError.prospectNotFound, got \(error)")
                return
            }
        }
    }
}