import XCTest
@testable import WritersApp

// MARK: - WritersApp.crmManager Tests
// Tests for the new crmManager property added to WritersApp in this PR.

final class WritersAppCRMManagerTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testCRMManagerIsInitializedOnAppInit() {
        // crmManager should be a non-nil CRMManager after WritersApp init
        // (The property is a public let, so we just verify it's accessible.)
        let manager = app.crmManager
        XCTAssertNotNil(manager, "WritersApp.crmManager should be initialized on app creation")
    }

    func testCRMManagerIsIndependentPerAppInstance() {
        let app2 = WritersApp()
        // Each WritersApp instance should have its own independent crmManager
        XCTAssertFalse(app.crmManager === app2.crmManager,
                       "Each WritersApp instance should have an independent CRMManager")
    }

    func testCRMManagerCanCreateContacts() {
        let contact = app.crmManager.createContact(name: "Jane Editor", email: "jane@publisher.com")
        XCTAssertEqual(contact.name, "Jane Editor")
        XCTAssertEqual(contact.email, "jane@publisher.com")
    }

    func testCRMManagerContactsAreIsolatedFromOtherAppInstances() {
        let app2 = WritersApp()
        app.crmManager.createContact(name: "Contact In App1", email: "a@example.com")
        let contactsInApp2 = app2.crmManager.getAllContacts()
        XCTAssertEqual(contactsInApp2.count, 0,
                       "Contacts added to one WritersApp instance should not appear in another")
    }
}

// MARK: - ProspectDatabase Tests
// Tests for ProspectDatabase CRUD operations (the docstrings were removed in this PR
// but the behavior remains; these tests verify correctness).

final class ProspectDatabaseTests: XCTestCase {

    var db: ProspectDatabase!

    override func setUp() {
        super.setUp()
        db = ProspectDatabase()
    }

    override func tearDown() {
        db = nil
        super.tearDown()
    }

    // MARK: - addProspect / getProspect

    func testAddAndGetProspect() {
        let prospect = Prospect(name: "Alice", email: "alice@example.com")
        db.addProspect(prospect)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Alice")
        XCTAssertEqual(retrieved?.email, "alice@example.com")
    }

    func testGetProspectReturnsNilForUnknownId() {
        let retrieved = db.getProspect(id: UUID())
        XCTAssertNil(retrieved)
    }

    func testAddProspectOverwritesExistingEntry() {
        let prospect = Prospect(name: "Bob", email: "bob@example.com")
        db.addProspect(prospect)
        // Add again (same id) with the same data – should overwrite
        db.addProspect(prospect)
        XCTAssertEqual(db.getAllProspects().count, 1)
    }

    // MARK: - getAllProspects

    func testGetAllProspectsReturnsAllEntries() {
        let p1 = Prospect(name: "Alice", email: "alice@example.com")
        let p2 = Prospect(name: "Bob", email: "bob@example.com")
        db.addProspect(p1)
        db.addProspect(p2)
        XCTAssertEqual(db.getAllProspects().count, 2)
    }

    func testGetAllProspectsEmptyWhenNoneAdded() {
        XCTAssertTrue(db.getAllProspects().isEmpty)
    }

    func testGetAllProspectsSortedNewestFirst() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        let p1 = Prospect(name: "Alice", email: "alice@example.com", createdAt: earlier)
        let p2 = Prospect(name: "Bob", email: "bob@example.com", createdAt: later)
        db.addProspect(p1)
        db.addProspect(p2)
        let all = db.getAllProspects()
        XCTAssertEqual(all.first?.name, "Bob", "Newest prospect should appear first")
        XCTAssertEqual(all.last?.name, "Alice", "Oldest prospect should appear last")
    }

    // MARK: - getProspects(withStatus:)

    func testGetProspectsWithStatusFiltersCorrectly() {
        let p1 = Prospect(name: "Lead", email: "lead@example.com", status: .new)
        let p2 = Prospect(name: "Active", email: "active@example.com", status: .contacted)
        db.addProspect(p1)
        db.addProspect(p2)
        let newProspects = db.getProspects(withStatus: .new)
        XCTAssertEqual(newProspects.count, 1)
        XCTAssertEqual(newProspects.first?.name, "Lead")
    }

    func testGetProspectsWithStatusReturnsEmptyForNoMatch() {
        let p1 = Prospect(name: "Alice", email: "a@example.com", status: .new)
        db.addProspect(p1)
        let meetings = db.getProspects(withStatus: .meeting)
        XCTAssertTrue(meetings.isEmpty)
    }

    // MARK: - updateProspect

    func testUpdateProspectReplacesEntry() {
        let prospect = Prospect(name: "Old Name", email: "old@example.com")
        db.addProspect(prospect)
        let updated = Prospect(id: prospect.id, name: "New Name", email: "old@example.com")
        db.updateProspect(updated)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertEqual(retrieved?.name, "New Name")
    }

    // MARK: - updateProspectStatus

    func testUpdateProspectStatusChangesStatus() throws {
        let prospect = Prospect(name: "Charlie", email: "charlie@example.com", status: .new)
        db.addProspect(prospect)
        try db.updateProspectStatus(id: prospect.id, status: .contacted)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertEqual(retrieved?.status, .contacted)
    }

    func testUpdateProspectStatusThrowsForUnknownId() {
        XCTAssertThrowsError(try db.updateProspectStatus(id: UUID(), status: .contacted))
    }

    func testUpdateProspectStatusToContactedSetsLastContactedAt() throws {
        let prospect = Prospect(name: "Dave", email: "dave@example.com", status: .new)
        db.addProspect(prospect)
        let before = Date()
        try db.updateProspectStatus(id: prospect.id, status: .contacted)
        let after = Date()
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved?.lastContactedAt)
        if let lca = retrieved?.lastContactedAt {
            XCTAssertGreaterThanOrEqual(lca, before)
            XCTAssertLessThanOrEqual(lca, after)
        }
    }

    func testUpdateProspectStatusToRepliedSetsLastContactedAt() throws {
        let prospect = Prospect(name: "Eve", email: "eve@example.com", status: .contacted)
        db.addProspect(prospect)
        try db.updateProspectStatus(id: prospect.id, status: .replied)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved?.lastContactedAt)
    }

    func testUpdateProspectStatusToMeetingSetsLastContactedAt() throws {
        let prospect = Prospect(name: "Frank", email: "frank@example.com", status: .replied)
        db.addProspect(prospect)
        try db.updateProspectStatus(id: prospect.id, status: .meeting)
        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved?.lastContactedAt)
    }

    // MARK: - deleteProspect

    func testDeleteProspectRemovesEntry() {
        let prospect = Prospect(name: "Grace", email: "grace@example.com")
        db.addProspect(prospect)
        db.deleteProspect(id: prospect.id)
        XCTAssertNil(db.getProspect(id: prospect.id))
        XCTAssertEqual(db.getAllProspects().count, 0)
    }

    func testDeleteProspectOnUnknownIdDoesNotThrow() {
        // Deleting a non-existent prospect should be a no-op
        XCTAssertNoThrow(db.deleteProspect(id: UUID()))
    }

    // MARK: - searchProspects

    func testSearchProspectsByName() {
        let p1 = Prospect(name: "Alice Wonder", email: "alice@example.com")
        let p2 = Prospect(name: "Bob Smith", email: "bob@example.com")
        db.addProspect(p1)
        db.addProspect(p2)
        let results = db.searchProspects(query: "alice")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Alice Wonder")
    }

    func testSearchProspectsByEmail() {
        let p1 = Prospect(name: "Alice", email: "alice@publisher.com")
        let p2 = Prospect(name: "Bob", email: "bob@agency.com")
        db.addProspect(p1)
        db.addProspect(p2)
        let results = db.searchProspects(query: "publisher")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.email, "alice@publisher.com")
    }

    func testSearchProspectsCaseInsensitive() {
        let p1 = Prospect(name: "UPPERCASE PERSON", email: "upper@example.com")
        db.addProspect(p1)
        let results = db.searchProspects(query: "uppercase")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchProspectsReturnsEmptyForNoMatch() {
        let p1 = Prospect(name: "Alice", email: "alice@example.com")
        db.addProspect(p1)
        let results = db.searchProspects(query: "zzz_no_match_zzz")
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - getStats

    func testGetStatsReturnsAllStatuses() {
        let stats = db.getStats()
        // All ProspectStatus cases should appear in the stats dictionary
        for status in ProspectStatus.allCases {
            XCTAssertNotNil(stats[status], "Stats should include entry for status: \(status)")
        }
    }

    func testGetStatsCountsCorrectly() {
        let p1 = Prospect(name: "A", email: "a@example.com", status: .new)
        let p2 = Prospect(name: "B", email: "b@example.com", status: .new)
        let p3 = Prospect(name: "C", email: "c@example.com", status: .contacted)
        db.addProspect(p1)
        db.addProspect(p2)
        db.addProspect(p3)
        let stats = db.getStats()
        XCTAssertEqual(stats[.new], 2)
        XCTAssertEqual(stats[.contacted], 1)
    }

    func testGetStatsReturnsZeroForEmptyStatuses() {
        let p1 = Prospect(name: "A", email: "a@example.com", status: .new)
        db.addProspect(p1)
        let stats = db.getStats()
        // Statuses with no prospects should be 0
        XCTAssertEqual(stats[.meeting], 0)
        XCTAssertEqual(stats[.declined], 0)
        XCTAssertEqual(stats[.converted], 0)
    }
}

// MARK: - CoworkSession Lifecycle Tests (WritersApp facade)

final class WritersAppCoworkSessionTests: XCTestCase {

    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testStartCoworkSessionCreatesActiveSession() {
        let session = app.startCoworkSession()
        XCTAssertNotNil(app.activeCoworkSession)
        XCTAssertEqual(app.activeCoworkSession?.id, session.id)
    }

    func testEndCoworkSessionReturnsSession() {
        app.startCoworkSession()
        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended)
    }

    func testEndCoworkSessionClearsActiveSession() {
        app.startCoworkSession()
        app.endCoworkSession()
        XCTAssertNil(app.activeCoworkSession)
    }

    func testEndCoworkSessionWithNoActiveSessionReturnsNil() {
        let result = app.endCoworkSession()
        XCTAssertNil(result)
    }

    func testStartCoworkSessionReplacesExistingSession() {
        let first = app.startCoworkSession()
        let second = app.startCoworkSession()
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(app.activeCoworkSession?.id, second.id)
    }

    // MARK: - Prospect facade via WritersApp

    func testAddProspectReturnsCreatedProspect() {
        let prospect = app.addProspect(name: "Writer Agent", email: "agent@lit.com")
        XCTAssertEqual(prospect.name, "Writer Agent")
        XCTAssertEqual(prospect.email, "agent@lit.com")
    }

    func testGetAllProspectsReflectsAddedProspects() {
        app.addProspect(name: "P1", email: "p1@example.com")
        app.addProspect(name: "P2", email: "p2@example.com")
        let all = app.getAllProspects()
        XCTAssertEqual(all.count, 2)
    }

    func testGetProspectsWithStatusFilter() throws {
        let p = app.addProspect(name: "New Prospect", email: "new@example.com")
        app.addProspect(name: "Contacted Prospect", email: "contacted@example.com")
        // Promote one to contacted
        try app.updateProspectStatus(id: p.id, status: .contacted)
        let contactedProspects = app.getProspects(withStatus: .contacted)
        XCTAssertEqual(contactedProspects.count, 1)
        XCTAssertEqual(contactedProspects.first?.name, "New Prospect")
    }

    func testSearchProspects() {
        app.addProspect(name: "Unique Name XYZ", email: "unique@example.com")
        app.addProspect(name: "Other Person", email: "other@example.com")
        let results = app.searchProspects(query: "unique")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Unique Name XYZ")
    }

    func testUpdateProspectStatusChangesStatus() throws {
        let prospect = app.addProspect(name: "Status Test", email: "status@example.com", status: .new)
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        let updated = app.getAllProspects().first(where: { $0.id == prospect.id })
        XCTAssertEqual(updated?.status, .contacted)
    }

    func testUpdateProspectStatusIncrementsSessionContactedCount() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "Contact Test", email: "ct@example.com", status: .new)
        let countBefore = app.activeCoworkSession?.prospectsContacted ?? 0
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        let countAfter = app.activeCoworkSession?.prospectsContacted ?? 0
        XCTAssertEqual(countAfter, countBefore + 1)
    }

    func testUpdateProspectStatusWithoutActiveSessionDoesNotCrash() throws {
        let prospect = app.addProspect(name: "No Session", email: "ns@example.com", status: .new)
        XCTAssertNoThrow(try app.updateProspectStatus(id: prospect.id, status: .contacted))
    }

    func testDeleteProspectRemovesFromList() {
        let prospect = app.addProspect(name: "Delete Me", email: "del@example.com")
        app.deleteProspect(id: prospect.id)
        XCTAssertTrue(app.getAllProspects().isEmpty)
    }

    func testGetProspectStatsReturnsAllStatuses() {
        let stats = app.getProspectStats()
        for status in ProspectStatus.allCases {
            XCTAssertNotNil(stats[status])
        }
    }

    func testAddProspectIncrementsActiveSessionCount() {
        app.startCoworkSession()
        let countBefore = app.activeCoworkSession?.prospectsAdded ?? 0
        app.addProspect(name: "Session Counter", email: "sc@example.com")
        let countAfter = app.activeCoworkSession?.prospectsAdded ?? 0
        XCTAssertEqual(countAfter, countBefore + 1)
    }

    // MARK: - Gmail facade

    func testGmailIsDisabledByDefault() {
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testEnableGmailSetsEnabledFlag() {
        app.enableGmail(oauthToken: "mock-token-123")
        XCTAssertTrue(app.isGmailEnabled)
    }

    func testDisableGmailClearsEnabledFlag() {
        app.enableGmail(oauthToken: "mock-token-123")
        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testListGmailMessagesThrowsWhenNotEnabled() async {
        do {
            _ = try await app.listGmailMessages()
            XCTFail("Should have thrown CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendGmailThrowsWhenNotEnabled() async {
        let draft = GmailDraft(to: "test@example.com", subject: "Test", body: "Hello")
        do {
            _ = try await app.sendGmail(draft: draft)
            XCTFail("Should have thrown CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMarkGmailAsReadThrowsWhenNotEnabled() async {
        do {
            try await app.markGmailAsRead(id: "msg123")
            XCTFail("Should have thrown CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Browser facade

    func testGetBrowsingHistoryEmptyAtStart() {
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }

    func testClearBrowsingHistoryDoesNotCrash() {
        app.clearBrowsingHistory()
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }
}