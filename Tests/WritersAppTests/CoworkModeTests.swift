import XCTest
@testable import WritersApp

final class CoworkModeTests: XCTestCase {
    var app: WritersApp!

    override func setUp() {
        super.setUp()
        app = WritersApp()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - ProspectStatus Enum Tests

    func testProspectStatusDisplayNames() {
        XCTAssertEqual(ProspectStatus.new.displayName, "New")
        XCTAssertEqual(ProspectStatus.contacted.displayName, "Contacted")
        XCTAssertEqual(ProspectStatus.replied.displayName, "Replied")
        XCTAssertEqual(ProspectStatus.meeting.displayName, "Meeting Scheduled")
        XCTAssertEqual(ProspectStatus.declined.displayName, "Declined")
        XCTAssertEqual(ProspectStatus.converted.displayName, "Converted")
    }

    func testProspectStatusCaseCount() {
        XCTAssertEqual(ProspectStatus.allCases.count, 6)
    }

    // MARK: - Prospect Model Tests

    func testProspectModelInit() {
        let prospect = Prospect(
            name: "Jane Agent",
            email: "jane@agency.com",
            company: "Agency Co",
            role: "Literary Agent",
            notes: "Met at conference",
            tags: ["fiction", "thriller"]
        )

        XCTAssertNotNil(prospect.id)
        XCTAssertEqual(prospect.name, "Jane Agent")
        XCTAssertEqual(prospect.email, "jane@agency.com")
        XCTAssertEqual(prospect.company, "Agency Co")
        XCTAssertEqual(prospect.role, "Literary Agent")
        XCTAssertEqual(prospect.status, .new)
        XCTAssertEqual(prospect.notes, "Met at conference")
        XCTAssertEqual(prospect.tags, ["fiction", "thriller"])
        XCTAssertNil(prospect.lastContactedAt)
    }

    func testProspectDefaultValues() {
        let prospect = Prospect(name: "Bob Publisher", email: "bob@pub.com")

        XCTAssertNil(prospect.company)
        XCTAssertNil(prospect.role)
        XCTAssertEqual(prospect.status, .new)
        XCTAssertEqual(prospect.notes, "")
        XCTAssertTrue(prospect.tags.isEmpty)
        XCTAssertNil(prospect.lastContactedAt)
    }

    func testProspectCodable() throws {
        let prospect = Prospect(
            name: "Alice Editor",
            email: "alice@press.com",
            company: "Big Press",
            status: .replied
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prospect)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Prospect.self, from: data)

        XCTAssertEqual(decoded.id, prospect.id)
        XCTAssertEqual(decoded.name, prospect.name)
        XCTAssertEqual(decoded.email, prospect.email)
        XCTAssertEqual(decoded.company, prospect.company)
        XCTAssertEqual(decoded.status, prospect.status)
    }

    // MARK: - GmailMessage Model Tests

    func testGmailMessageInit() {
        let date = Date()
        let message = GmailMessage(
            id: "msg-001",
            threadId: "thread-001",
            subject: "Re: Your Manuscript",
            from: "editor@press.com",
            to: ["author@example.com"],
            snippet: "We'd love to discuss…",
            body: "Dear Author, we have reviewed your submission…",
            date: date,
            isRead: false,
            labels: ["INBOX", "UNREAD"]
        )

        XCTAssertEqual(message.id, "msg-001")
        XCTAssertEqual(message.threadId, "thread-001")
        XCTAssertEqual(message.subject, "Re: Your Manuscript")
        XCTAssertEqual(message.from, "editor@press.com")
        XCTAssertEqual(message.to, ["author@example.com"])
        XCTAssertFalse(message.isRead)
        XCTAssertEqual(message.labels, ["INBOX", "UNREAD"])
    }

    func testGmailMessageCodable() throws {
        let message = GmailMessage(
            id: "msg-002",
            threadId: "thread-002",
            subject: "Offer",
            from: "agent@agency.com",
            to: ["me@example.com"],
            snippet: "Great news",
            body: "We want to represent you.",
            date: Date(),
            isRead: true
        )

        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(GmailMessage.self, from: data)

        XCTAssertEqual(decoded.id, message.id)
        XCTAssertEqual(decoded.subject, message.subject)
        XCTAssertEqual(decoded.isRead, message.isRead)
    }

    // MARK: - GmailDraft Model Tests

    func testGmailDraftInit() {
        let draft = GmailDraft(
            to: "editor@press.com",
            subject: "Query Letter",
            body: "Dear Editor, I am writing to query…",
            inReplyTo: "msg-001"
        )

        XCTAssertNotNil(draft.id)
        XCTAssertEqual(draft.to, "editor@press.com")
        XCTAssertEqual(draft.subject, "Query Letter")
        XCTAssertEqual(draft.body, "Dear Editor, I am writing to query…")
        XCTAssertEqual(draft.inReplyTo, "msg-001")
    }

    func testGmailDraftDefaultValues() {
        let draft = GmailDraft(to: "a@b.com", subject: "Hi", body: "Hello")
        XCTAssertNil(draft.inReplyTo)
    }

    // MARK: - BrowsedPage Model Tests

    func testBrowsedPageInit() {
        let page = BrowsedPage(
            url: "https://example.com",
            title: "Example Domain",
            textContent: "This domain is for use in illustrative examples."
        )

        XCTAssertNotNil(page.id)
        XCTAssertEqual(page.url, "https://example.com")
        XCTAssertEqual(page.title, "Example Domain")
        XCTAssertEqual(page.textContent, "This domain is for use in illustrative examples.")
    }

    func testBrowsedPageCodable() throws {
        let page = BrowsedPage(url: "https://test.com", title: "Test", textContent: "Content")

        let data = try JSONEncoder().encode(page)
        let decoded = try JSONDecoder().decode(BrowsedPage.self, from: data)

        XCTAssertEqual(decoded.id, page.id)
        XCTAssertEqual(decoded.url, page.url)
        XCTAssertEqual(decoded.title, page.title)
        XCTAssertEqual(decoded.textContent, page.textContent)
    }

    // MARK: - CoworkSession Model Tests

    func testCoworkSessionInit() {
        let session = CoworkSession()

        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endedAt)
        XCTAssertEqual(session.emailsSent, 0)
        XCTAssertEqual(session.prospectsAdded, 0)
        XCTAssertEqual(session.prospectsContacted, 0)
        XCTAssertEqual(session.pagesResearched, 0)
    }

    func testCoworkSessionDurationNilWhenActive() {
        let session = CoworkSession()
        XCTAssertNil(session.durationMinutes)
    }

    func testCoworkSessionDurationMinutes() {
        let start = Date()
        let end = start.addingTimeInterval(120) // 2 minutes
        let session = CoworkSession(startedAt: start, endedAt: end)

        XCTAssertNotNil(session.durationMinutes)
        XCTAssertEqual(session.durationMinutes!, 2.0, accuracy: 0.01)
    }

    func testCoworkSessionCodable() throws {
        let session = CoworkSession(emailsSent: 3, prospectsAdded: 2, prospectsContacted: 1, pagesResearched: 5)

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(CoworkSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.emailsSent, 3)
        XCTAssertEqual(decoded.prospectsAdded, 2)
        XCTAssertEqual(decoded.prospectsContacted, 1)
        XCTAssertEqual(decoded.pagesResearched, 5)
    }

    // MARK: - CoworkError Tests

    func testCoworkErrorDescriptions() {
        let id = UUID()
        XCTAssertNotNil(CoworkError.gmailNotEnabled.errorDescription)
        XCTAssertNotNil(CoworkError.invalidOAuthToken.errorDescription)
        XCTAssertNotNil(CoworkError.prospectNotFound(id).errorDescription)
        XCTAssertNotNil(CoworkError.browserFetchFailed("HTTP 404").errorDescription)
        XCTAssertNotNil(CoworkError.networkError("timeout").errorDescription)
        XCTAssertNotNil(CoworkError.invalidURL.errorDescription)
    }

    func testCoworkErrorGmailNotEnabledMessage() {
        let error = CoworkError.gmailNotEnabled
        XCTAssertTrue(error.errorDescription?.contains("Gmail") ?? false)
    }

    // MARK: - ProspectDatabase CRUD Tests

    func testProspectDatabaseAddAndGet() {
        let db = ProspectDatabase()
        let prospect = Prospect(name: "Test User", email: "test@test.com")

        db.addProspect(prospect)

        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Test User")
        XCTAssertEqual(retrieved?.email, "test@test.com")
    }

    func testProspectDatabaseGetNonExistent() {
        let db = ProspectDatabase()
        let result = db.getProspect(id: UUID())
        XCTAssertNil(result)
    }

    func testProspectDatabaseGetAll() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "A", email: "a@a.com"))
        db.addProspect(Prospect(name: "B", email: "b@b.com"))
        db.addProspect(Prospect(name: "C", email: "c@c.com"))

        let all = db.getAllProspects()
        XCTAssertEqual(all.count, 3)
    }

    func testProspectDatabaseGetAllSortedByCreatedAt() {
        let db = ProspectDatabase()
        let p1 = Prospect(name: "Older", email: "old@test.com", createdAt: Date().addingTimeInterval(-100))
        let p2 = Prospect(name: "Newer", email: "new@test.com", createdAt: Date())
        db.addProspect(p1)
        db.addProspect(p2)

        let all = db.getAllProspects()
        XCTAssertEqual(all.first?.name, "Newer")
        XCTAssertEqual(all.last?.name, "Older")
    }

    func testProspectDatabaseUpdate() {
        let db = ProspectDatabase()
        var prospect = Prospect(name: "Original", email: "orig@test.com")
        db.addProspect(prospect)

        prospect.name = "Updated"
        db.updateProspect(prospect)

        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertEqual(retrieved?.name, "Updated")
    }

    func testProspectDatabaseDelete() {
        let db = ProspectDatabase()
        let prospect = Prospect(name: "To Delete", email: "del@test.com")
        db.addProspect(prospect)

        db.deleteProspect(id: prospect.id)

        XCTAssertNil(db.getProspect(id: prospect.id))
        XCTAssertEqual(db.getAllProspects().count, 0)
    }

    func testProspectDatabaseFilterByStatus() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "New 1", email: "n1@test.com", status: .new))
        db.addProspect(Prospect(name: "New 2", email: "n2@test.com", status: .new))
        db.addProspect(Prospect(name: "Contacted", email: "c@test.com", status: .contacted))

        let newProspects = db.getProspects(withStatus: .new)
        XCTAssertEqual(newProspects.count, 2)

        let contactedProspects = db.getProspects(withStatus: .contacted)
        XCTAssertEqual(contactedProspects.count, 1)

        let repliedProspects = db.getProspects(withStatus: .replied)
        XCTAssertEqual(repliedProspects.count, 0)
    }

    func testProspectDatabaseSearchByName() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "Alice Smith", email: "alice@example.com"))
        db.addProspect(Prospect(name: "Bob Jones", email: "bob@example.com"))

        let results = db.searchProspects(query: "alice")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Alice Smith")
    }

    func testProspectDatabaseSearchByEmail() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "Agent One", email: "agent@bigagency.com"))
        db.addProspect(Prospect(name: "Agent Two", email: "agent@smallpress.com"))

        let results = db.searchProspects(query: "bigagency")
        XCTAssertEqual(results.count, 1)
    }

    func testProspectDatabaseSearchByCompany() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "John", email: "j@company.com", company: "Penguin Books"))
        db.addProspect(Prospect(name: "Jane", email: "ja@other.com", company: "HarperCollins"))

        let results = db.searchProspects(query: "penguin")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "John")
    }

    func testProspectDatabaseSearchByNotes() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "P1", email: "p1@t.com", notes: "Met at BookExpo"))
        db.addProspect(Prospect(name: "P2", email: "p2@t.com", notes: "Cold outreach"))

        let results = db.searchProspects(query: "bookexpo")
        XCTAssertEqual(results.count, 1)
    }

    func testProspectDatabaseSearchByTags() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "T1", email: "t1@t.com", tags: ["fiction", "literary"]))
        db.addProspect(Prospect(name: "T2", email: "t2@t.com", tags: ["nonfiction", "memoir"]))

        let results = db.searchProspects(query: "literary")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "T1")
    }

    func testProspectDatabaseSearchCaseInsensitive() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "UPPERCASE NAME", email: "up@test.com"))

        let results = db.searchProspects(query: "uppercase")
        XCTAssertEqual(results.count, 1)
    }

    func testProspectDatabaseStats() {
        let db = ProspectDatabase()
        db.addProspect(Prospect(name: "N1", email: "n1@t.com", status: .new))
        db.addProspect(Prospect(name: "N2", email: "n2@t.com", status: .new))
        db.addProspect(Prospect(name: "C1", email: "c1@t.com", status: .contacted))
        db.addProspect(Prospect(name: "V1", email: "v1@t.com", status: .converted))

        let stats = db.getStats()
        XCTAssertEqual(stats[.new], 2)
        XCTAssertEqual(stats[.contacted], 1)
        XCTAssertEqual(stats[.converted], 1)
        XCTAssertEqual(stats[.replied], 0)
        XCTAssertEqual(stats[.meeting], 0)
        XCTAssertEqual(stats[.declined], 0)
    }

    func testProspectDatabaseUpdateStatus() throws {
        let db = ProspectDatabase()
        let prospect = Prospect(name: "Status Test", email: "st@test.com", status: .new)
        db.addProspect(prospect)

        try db.updateProspectStatus(id: prospect.id, status: .contacted)

        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertEqual(retrieved?.status, .contacted)
        XCTAssertNotNil(retrieved?.lastContactedAt)
    }

    func testProspectDatabaseUpdateStatusDeclinedDoesNotSetLastContacted() throws {
        let db = ProspectDatabase()
        let prospect = Prospect(name: "Declined", email: "d@test.com", status: .new)
        db.addProspect(prospect)

        try db.updateProspectStatus(id: prospect.id, status: .declined)

        let retrieved = db.getProspect(id: prospect.id)
        XCTAssertEqual(retrieved?.status, .declined)
        XCTAssertNil(retrieved?.lastContactedAt)
    }

    func testProspectDatabaseUpdateStatusNotFoundThrows() {
        let db = ProspectDatabase()
        XCTAssertThrowsError(try db.updateProspectStatus(id: UUID(), status: .contacted)) { error in
            guard case CoworkError.prospectNotFound = error else {
                XCTFail("Expected CoworkError.prospectNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - WritersApp Prospect Facade Tests

    func testAddProspect() {
        let prospect = app.addProspect(
            name: "Agent Smith",
            email: "smith@agency.com",
            company: "Top Agency",
            role: "Literary Agent",
            notes: "Interested in thrillers",
            tags: ["thriller", "crime"]
        )

        XCTAssertEqual(prospect.name, "Agent Smith")
        XCTAssertEqual(prospect.email, "smith@agency.com")
        XCTAssertEqual(prospect.company, "Top Agency")
        XCTAssertEqual(prospect.status, .new)
    }

    func testGetAllProspects() {
        _ = app.addProspect(name: "A", email: "a@test.com")
        _ = app.addProspect(name: "B", email: "b@test.com")

        let all = app.getAllProspects()
        XCTAssertEqual(all.count, 2)
    }

    func testGetProspectsByStatus() {
        _ = app.addProspect(name: "New 1", email: "n1@test.com")
        _ = app.addProspect(name: "New 2", email: "n2@test.com")
        let p = app.addProspect(name: "To Contact", email: "tc@test.com")
        try? app.updateProspectStatus(id: p.id, status: .contacted)

        let newProspects = app.getProspects(withStatus: .new)
        XCTAssertEqual(newProspects.count, 2)

        let contactedProspects = app.getProspects(withStatus: .contacted)
        XCTAssertEqual(contactedProspects.count, 1)
    }

    func testSearchProspects() {
        _ = app.addProspect(name: "Maria Garcia", email: "maria@publisher.com")
        _ = app.addProspect(name: "Tom Brown", email: "tom@agency.com")

        let results = app.searchProspects(query: "garcia")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Maria Garcia")
    }

    func testUpdateProspectStatus() throws {
        let p = app.addProspect(name: "Status Update", email: "su@test.com")

        try app.updateProspectStatus(id: p.id, status: .replied)

        let all = app.getAllProspects()
        let retrieved = all.first { $0.id == p.id }
        XCTAssertEqual(retrieved?.status, .replied)
    }

    func testUpdateProspectStatusNotFoundThrows() {
        XCTAssertThrowsError(try app.updateProspectStatus(id: UUID(), status: .contacted))
    }

    func testDeleteProspect() {
        let p = app.addProspect(name: "Delete Me", email: "del@test.com")
        XCTAssertEqual(app.getAllProspects().count, 1)

        app.deleteProspect(id: p.id)
        XCTAssertEqual(app.getAllProspects().count, 0)
    }

    func testGetProspectStats() {
        _ = app.addProspect(name: "N1", email: "n1@t.com")
        _ = app.addProspect(name: "N2", email: "n2@t.com")
        let p = app.addProspect(name: "C1", email: "c1@t.com")
        try? app.updateProspectStatus(id: p.id, status: .meeting)

        let stats = app.getProspectStats()
        XCTAssertEqual(stats[.new], 2)
        XCTAssertEqual(stats[.meeting], 1)
    }

    // MARK: - Cowork Session Lifecycle Tests

    func testStartCoworkSession() {
        let session = app.startCoworkSession()

        XCTAssertNotNil(session.id)
        XCTAssertNil(session.endedAt)
        XCTAssertNotNil(app.activeCoworkSession)
        XCTAssertEqual(app.activeCoworkSession?.id, session.id)
    }

    func testEndCoworkSession() {
        _ = app.startCoworkSession()
        let ended = app.endCoworkSession()

        XCTAssertNotNil(ended)
        XCTAssertNotNil(ended?.endedAt)
        XCTAssertNil(app.activeCoworkSession)
    }

    func testEndCoworkSessionWhenNoneActive() {
        let result = app.endCoworkSession()
        XCTAssertNil(result)
    }

    func testStartCoworkSessionReplacesExisting() {
        let first = app.startCoworkSession()
        let second = app.startCoworkSession()

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(app.activeCoworkSession?.id, second.id)
    }

    // MARK: - Session Counter Tracking Tests

    func testSessionTrackingProspectsAdded() {
        _ = app.startCoworkSession()

        _ = app.addProspect(name: "P1", email: "p1@t.com")
        _ = app.addProspect(name: "P2", email: "p2@t.com")

        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, 2)
    }

    func testSessionTrackingProspectsContactedOnStatusUpdate() {
        _ = app.startCoworkSession()

        let p = app.addProspect(name: "Contact Track", email: "ct@t.com")
        try? app.updateProspectStatus(id: p.id, status: .contacted)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
    }

    func testSessionTrackingProspectsContactedForMeeting() {
        _ = app.startCoworkSession()

        let p = app.addProspect(name: "Meeting Track", email: "mt@t.com")
        try? app.updateProspectStatus(id: p.id, status: .meeting)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)
    }

    func testSessionTrackingNoIncrementForDeclined() {
        _ = app.startCoworkSession()

        let p = app.addProspect(name: "Declined", email: "dec@t.com")
        try? app.updateProspectStatus(id: p.id, status: .declined)

        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 0)
    }

    func testSessionTrackingProspectsAddedWithoutActiveSession() {
        // Adding prospects without an active session should not crash
        _ = app.addProspect(name: "No Session", email: "ns@t.com")
        XCTAssertNil(app.activeCoworkSession)
    }

    // MARK: - Gmail Enable / Disable Tests

    func testGmailEnableDisable() {
        XCTAssertFalse(app.isGmailEnabled)

        app.enableGmail(oauthToken: "test-token")
        XCTAssertTrue(app.isGmailEnabled)

        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testListGmailMessagesThrowsWhenDisabled() async {
        do {
            _ = try await app.listGmailMessages()
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendGmailThrowsWhenDisabled() async {
        let draft = GmailDraft(to: "a@b.com", subject: "Test", body: "Hello")
        do {
            _ = try await app.sendGmail(draft: draft)
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMarkGmailAsReadThrowsWhenDisabled() async {
        do {
            try await app.markGmailAsRead(id: "msg-123")
            XCTFail("Expected CoworkError.gmailNotEnabled")
        } catch CoworkError.gmailNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - BrowserService Tests

    func testBrowserServiceHistoryInitiallyEmpty() {
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }

    func testBrowserServiceClearHistoryWhenEmpty() {
        // Clearing an empty history should not crash and should remain empty.
        app.clearBrowsingHistory()
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }

    func testBrowserServiceDirectClearHistory() {
        let browser = BrowserService()
        XCTAssertTrue(browser.history.isEmpty)
        browser.clearHistory()
        XCTAssertTrue(browser.history.isEmpty)
    }

    func testBrowseURLInvalidSchemeThrows() async {
        do {
            _ = try await app.browseURL("ftp://example.com/file")
            XCTFail("Expected CoworkError.invalidURL")
        } catch CoworkError.invalidURL {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrowseURLInvalidURLThrows() async {
        do {
            _ = try await app.browseURL("not a url at all !!!")
            XCTFail("Expected CoworkError.invalidURL")
        } catch CoworkError.invalidURL {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
