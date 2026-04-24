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

    // MARK: - ProspectDatabase CRUD

    func testAddAndGetProspect() {
        let prospect = app.addProspect(
            name: "Jane Agent",
            email: "jane@agency.com",
            company: "Top Agency",
            role: "Literary Agent",
            notes: "Loves sci-fi",
            tags: ["sci-fi", "literary"]
        )
        XCTAssertEqual(prospect.name, "Jane Agent")
        XCTAssertEqual(prospect.email, "jane@agency.com")
        XCTAssertEqual(prospect.company, "Top Agency")
        XCTAssertEqual(prospect.role, "Literary Agent")
        XCTAssertEqual(prospect.status, .new)
        XCTAssertEqual(prospect.notes, "Loves sci-fi")
        XCTAssertEqual(prospect.tags, ["sci-fi", "literary"])

        let fetched = app.prospectDatabase.getProspect(id: prospect.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, prospect.id)
    }

    func testGetAllProspects() {
        XCTAssertTrue(app.getAllProspects().isEmpty)
        _ = app.addProspect(name: "Alice", email: "alice@example.com")
        _ = app.addProspect(name: "Bob", email: "bob@example.com")
        XCTAssertEqual(app.getAllProspects().count, 2)
    }

    func testDeleteProspect() {
        let prospect = app.addProspect(name: "Temp", email: "temp@example.com")
        XCTAssertEqual(app.getAllProspects().count, 1)
        app.deleteProspect(id: prospect.id)
        XCTAssertTrue(app.getAllProspects().isEmpty)
    }

    func testSearchProspects() {
        _ = app.addProspect(name: "Alice Publisher", email: "alice@press.com", company: "Big Press")
        _ = app.addProspect(name: "Bob Agent", email: "bob@agency.com", notes: "science fiction fan")
        _ = app.addProspect(name: "Carol Editor", email: "carol@mag.com")

        let byName = app.searchProspects(query: "alice")
        XCTAssertEqual(byName.count, 1)
        XCTAssertEqual(byName.first?.name, "Alice Publisher")

        let byCompany = app.searchProspects(query: "big press")
        XCTAssertEqual(byCompany.count, 1)

        let byNotes = app.searchProspects(query: "science fiction")
        XCTAssertEqual(byNotes.count, 1)
        XCTAssertEqual(byNotes.first?.name, "Bob Agent")

        let noMatch = app.searchProspects(query: "zzznomatch")
        XCTAssertTrue(noMatch.isEmpty)
    }

    func testSearchProspectsByTag() {
        _ = app.addProspect(name: "Tagged", email: "tagged@example.com", tags: ["thriller", "mystery"])
        let results = app.searchProspects(query: "thriller")
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - ProspectStatus Transitions

    func testUpdateProspectStatusThrowsForUnknownId() {
        XCTAssertThrowsError(
            try app.updateProspectStatus(id: UUID(), status: .contacted)
        )
    }

    func testUpdateProspectStatusChangesStatus() throws {
        let prospect = app.addProspect(name: "Test", email: "test@example.com")
        XCTAssertEqual(prospect.status, .new)

        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        let updated = app.prospectDatabase.getProspect(id: prospect.id)
        XCTAssertEqual(updated?.status, .contacted)
        XCTAssertNotNil(updated?.lastContactedAt)
    }

    func testGetProspectsByStatus() throws {
        let p1 = app.addProspect(name: "P1", email: "p1@x.com")
        let p2 = app.addProspect(name: "P2", email: "p2@x.com")
        _ = app.addProspect(name: "P3", email: "p3@x.com")

        try app.updateProspectStatus(id: p1.id, status: .contacted)
        try app.updateProspectStatus(id: p2.id, status: .replied)

        XCTAssertEqual(app.getProspects(withStatus: .new).count, 1)
        XCTAssertEqual(app.getProspects(withStatus: .contacted).count, 1)
        XCTAssertEqual(app.getProspects(withStatus: .replied).count, 1)
    }

    func testProspectStats() throws {
        _ = app.addProspect(name: "A", email: "a@x.com")
        let b = app.addProspect(name: "B", email: "b@x.com")
        let c = app.addProspect(name: "C", email: "c@x.com")
        try app.updateProspectStatus(id: b.id, status: .contacted)
        try app.updateProspectStatus(id: c.id, status: .converted)

        let stats = app.getProspectStats()
        XCTAssertEqual(stats[.new], 1)
        XCTAssertEqual(stats[.contacted], 1)
        XCTAssertEqual(stats[.converted], 1)
        XCTAssertEqual(stats[.replied], 0)
    }

    // MARK: - CoworkSession Counters

    func testCoworkSessionStartAndEnd() {
        XCTAssertNil(app.activeCoworkSession)
        let session = app.startCoworkSession()
        XCTAssertNotNil(app.activeCoworkSession)
        XCTAssertEqual(session.emailsSent, 0)
        XCTAssertEqual(session.prospectsAdded, 0)
        XCTAssertEqual(session.prospectsContacted, 0)
        XCTAssertEqual(session.pagesResearched, 0)

        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended?.endedAt)
        XCTAssertNil(app.activeCoworkSession)
    }

    func testEndCoworkSessionWithNoActiveSessionReturnsNil() {
        XCTAssertNil(app.endCoworkSession())
    }

    func testProspectsAddedCounter() {
        app.startCoworkSession()
        _ = app.addProspect(name: "New P", email: "n@x.com")
        _ = app.addProspect(name: "New P2", email: "n2@x.com")
        XCTAssertEqual(app.activeCoworkSession?.prospectsAdded, 2)
    }

    func testProspectsContactedCounterIncrementsOnEveryContactStatusUpdate() throws {
        app.startCoworkSession()
        let prospect = app.addProspect(name: "P", email: "p@x.com")

        // Transition new → contacted: should increment
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 1)

        // contacted → contacted again: should also increment (new behaviour: no transition guard)
        try app.updateProspectStatus(id: prospect.id, status: .contacted)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 2)

        // contacted → replied (still a contact state): should increment
        try app.updateProspectStatus(id: prospect.id, status: .replied)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3)

        // replied → declined (not a contact state): counter stays
        try app.updateProspectStatus(id: prospect.id, status: .declined)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 3)

        // declined → meeting (contact state): should increment
        try app.updateProspectStatus(id: prospect.id, status: .meeting)
        XCTAssertEqual(app.activeCoworkSession?.prospectsContacted, 4)
    }

    func testCoworkSessionDurationMinutes() {
        _ = app.startCoworkSession()
        let ended = app.endCoworkSession()
        XCTAssertNotNil(ended?.durationMinutes)
        XCTAssertGreaterThanOrEqual(ended!.durationMinutes!, 0)
    }

    // MARK: - BrowserService

    func testBrowsedPageStruct() {
        let page = BrowsedPage(url: "https://example.com", title: "Test", textContent: "Hello World")
        XCTAssertEqual(page.textContent, "Hello World")
        XCTAssertEqual(page.url, "https://example.com")
        XCTAssertEqual(page.title, "Test")
    }

    func testBrowserHistoryTracking() {
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
        app.browserService.clearHistory()
        XCTAssertTrue(app.getBrowsingHistory().isEmpty)
    }

    func testBrowsedPagePlainText() {
        let page = BrowsedPage(url: "https://test.example.com", title: "Title", textContent: "Plain text, no tags.")
        XCTAssertFalse(page.textContent.contains("<"))
        XCTAssertFalse(page.textContent.contains(">"))
        XCTAssertEqual(page.textContent, "Plain text, no tags.")
    }

    // MARK: - ProspectStatus Enum

    func testProspectStatusDisplayNames() {
        XCTAssertEqual(ProspectStatus.new.displayName, "New")
        XCTAssertEqual(ProspectStatus.contacted.displayName, "Contacted")
        XCTAssertEqual(ProspectStatus.replied.displayName, "Replied")
        XCTAssertEqual(ProspectStatus.meeting.displayName, "Meeting Scheduled")
        XCTAssertEqual(ProspectStatus.declined.displayName, "Declined")
        XCTAssertEqual(ProspectStatus.converted.displayName, "Converted")
        XCTAssertEqual(ProspectStatus.allCases.count, 6)
    }

    // MARK: - GmailDraft Model

    func testGmailDraftInit() {
        let draft = GmailDraft(
            to: "agent@example.com",
            subject: "Query: My Novel",
            body: "Dear Agent,\n\nI am writing to query..."
        )
        XCTAssertEqual(draft.to, "agent@example.com")
        XCTAssertEqual(draft.subject, "Query: My Novel")
        XCTAssertNil(draft.inReplyTo)
    }

    func testGmailDraftWithReply() {
        let draft = GmailDraft(
            to: "agent@example.com",
            subject: "Re: Query",
            body: "Thank you!",
            inReplyTo: "thread-abc-123"
        )
        XCTAssertEqual(draft.inReplyTo, "thread-abc-123")
    }

    // MARK: - CoworkError

    func testCoworkErrorDescriptions() {
        XCTAssertNotNil(CoworkError.gmailNotEnabled.errorDescription)
        XCTAssertNotNil(CoworkError.invalidOAuthToken.errorDescription)
        XCTAssertNotNil(CoworkError.prospectNotFound(UUID()).errorDescription)
        XCTAssertNotNil(CoworkError.browserFetchFailed("timeout").errorDescription)
        XCTAssertNotNil(CoworkError.networkError("500").errorDescription)
        XCTAssertNotNil(CoworkError.invalidURL.errorDescription)
    }

    // MARK: - Gmail Enable/Disable

    func testGmailEnableDisable() {
        XCTAssertFalse(app.isGmailEnabled)
        app.enableGmail(oauthToken: "fake-token")
        XCTAssertTrue(app.isGmailEnabled)
        app.disableGmail()
        XCTAssertFalse(app.isGmailEnabled)
    }

    func testMarkGmailAsReadThrowsWhenDisabled() async {
        XCTAssertFalse(app.isGmailEnabled)
        do {
            try await app.markGmailAsRead(id: "msg-id")
            XCTFail("Expected CoworkError.gmailNotEnabled to be thrown")
        } catch CoworkError.gmailNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testListGmailMessagesThrowsWhenDisabled() async {
        XCTAssertFalse(app.isGmailEnabled)
        do {
            _ = try await app.listGmailMessages()
            XCTFail("Expected CoworkError.gmailNotEnabled to be thrown")
        } catch CoworkError.gmailNotEnabled {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
