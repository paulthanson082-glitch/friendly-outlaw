import XCTest
@testable import WritersApp

// MARK: - CRMManager Tests

final class CRMManagerTests: XCTestCase {

    var manager: CRMManager!

    override func setUp() {
        super.setUp()
        manager = CRMManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Contact CRUD

    func testCreateContactReturnsContactWithCorrectName() {
        let contact = manager.createContact(name: "Jane Austen")
        XCTAssertEqual(contact.name, "Jane Austen")
    }

    func testCreateContactStoresOptionalFields() {
        let contact = manager.createContact(
            name: "Agent Smith",
            email: "smith@lit.agency",
            phone: "555-1234",
            company: "Big Five Publishing",
            role: "Literary Agent",
            tags: ["thriller", "fiction"],
            notes: "Prefers short queries"
        )
        XCTAssertEqual(contact.email, "smith@lit.agency")
        XCTAssertEqual(contact.phone, "555-1234")
        XCTAssertEqual(contact.company, "Big Five Publishing")
        XCTAssertEqual(contact.role, "Literary Agent")
        XCTAssertEqual(contact.tags, ["thriller", "fiction"])
        XCTAssertEqual(contact.notes, "Prefers short queries")
    }

    func testCreateContactAssignsUniqueIds() {
        let c1 = manager.createContact(name: "Alice")
        let c2 = manager.createContact(name: "Bob")
        XCTAssertNotEqual(c1.id, c2.id)
    }

    func testGetContactReturnsStoredContact() {
        let contact = manager.createContact(name: "Editor One")
        let retrieved = manager.getContact(id: contact.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Editor One")
    }

    func testGetContactReturnsNilForUnknownId() {
        XCTAssertNil(manager.getContact(id: UUID()))
    }

    func testGetAllContactsReturnsSortedByName() {
        manager.createContact(name: "Zelda")
        manager.createContact(name: "Alice")
        manager.createContact(name: "Mike")
        let all = manager.getAllContacts()
        XCTAssertEqual(all.map { $0.name }, ["Alice", "Mike", "Zelda"])
    }

    func testGetAllContactsReturnsEmptyWhenNone() {
        XCTAssertTrue(manager.getAllContacts().isEmpty)
    }

    func testUpdateContactPersistsChanges() {
        var contact = manager.createContact(name: "Old Name")
        contact.name = "New Name"
        manager.updateContact(contact)
        let retrieved = manager.getContact(id: contact.id)
        XCTAssertEqual(retrieved?.name, "New Name")
    }

    func testUpdateContactDoesNothingForUnknownContact() {
        let orphan = CRMContact(name: "Ghost")
        manager.updateContact(orphan)
        XCTAssertNil(manager.getContact(id: orphan.id))
    }

    func testDeleteContactRemovesContact() {
        let contact = manager.createContact(name: "To Delete")
        manager.deleteContact(id: contact.id)
        XCTAssertNil(manager.getContact(id: contact.id))
    }

    func testDeleteContactAlsoRemovesAssociatedDeals() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel Deal", contactId: contact.id)
        manager.deleteContact(id: contact.id)
        XCTAssertNil(manager.getDeal(id: deal.id))
    }

    func testDeleteContactAlsoRemovesAssociatedInteractions() {
        let contact = manager.createContact(name: "Agent")
        manager.logInteraction(contactId: contact.id, type: .email, summary: "Initial query")
        manager.deleteContact(id: contact.id)
        XCTAssertTrue(manager.getInteractions(forContact: contact.id).isEmpty)
    }

    // MARK: - Contact Search

    func testSearchContactsByName() {
        manager.createContact(name: "Jane Austen")
        manager.createContact(name: "Charlotte Brontë")
        let results = manager.searchContacts(query: "austen")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Jane Austen")
    }

    func testSearchContactsByCompany() {
        manager.createContact(name: "Bob", company: "Penguin Random House")
        manager.createContact(name: "Alice", company: "HarperCollins")
        let results = manager.searchContacts(query: "penguin")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Bob")
    }

    func testSearchContactsByRole() {
        manager.createContact(name: "Dave", role: "Literary Agent")
        manager.createContact(name: "Eve", role: "Editor")
        let results = manager.searchContacts(query: "agent")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Dave")
    }

    func testSearchContactsByEmail() {
        manager.createContact(name: "Frank", email: "frank@publisher.com")
        let results = manager.searchContacts(query: "publisher.com")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchContactsByTag() {
        manager.createContact(name: "Grace", tags: ["thriller", "mystery"])
        manager.createContact(name: "Hank", tags: ["romance"])
        let results = manager.searchContacts(query: "thriller")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Grace")
    }

    func testSearchContactsReturnsEmptyForNoMatch() {
        manager.createContact(name: "Alice")
        XCTAssertTrue(manager.searchContacts(query: "zzznomatch").isEmpty)
    }

    func testSearchContactsIsCaseInsensitive() {
        manager.createContact(name: "ALICE")
        let results = manager.searchContacts(query: "alice")
        XCTAssertEqual(results.count, 1)
    }

    // MARK: - Deal CRUD

    func testCreateDealReturnsCorrectDeal() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel Submission", contactId: contact.id)
        XCTAssertEqual(deal.title, "Novel Submission")
        XCTAssertEqual(deal.contactId, contact.id)
        XCTAssertEqual(deal.stage, .prospect)
    }

    func testCreateDealWithAllFields() {
        let contact = manager.createContact(name: "Agent")
        let docId = UUID()
        let deal = manager.createDeal(
            title: "Sci-Fi Trilogy",
            contactId: contact.id,
            stage: .submitted,
            value: 50000,
            documentId: docId,
            notes: "Full MS submitted"
        )
        XCTAssertEqual(deal.stage, .submitted)
        XCTAssertEqual(deal.value, 50000)
        XCTAssertEqual(deal.documentId, docId)
        XCTAssertEqual(deal.notes, "Full MS submitted")
    }

    func testGetDealReturnsStoredDeal() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Fantasy Novel", contactId: contact.id)
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Fantasy Novel")
    }

    func testGetDealReturnsNilForUnknownId() {
        XCTAssertNil(manager.getDeal(id: UUID()))
    }

    func testGetDealsForContactReturnsOnlyContactDeals() {
        let c1 = manager.createContact(name: "Agent 1")
        let c2 = manager.createContact(name: "Agent 2")
        manager.createDeal(title: "Deal A", contactId: c1.id)
        manager.createDeal(title: "Deal B", contactId: c1.id)
        manager.createDeal(title: "Deal C", contactId: c2.id)
        let deals = manager.getDeals(forContact: c1.id)
        XCTAssertEqual(deals.count, 2)
        XCTAssertTrue(deals.allSatisfy { $0.contactId == c1.id })
    }

    func testGetDealsInStage() {
        let contact = manager.createContact(name: "Publisher")
        manager.createDeal(title: "Prospect", contactId: contact.id, stage: .prospect)
        manager.createDeal(title: "Queried", contactId: contact.id, stage: .queried)
        manager.createDeal(title: "Queried 2", contactId: contact.id, stage: .queried)
        let queried = manager.getDeals(inStage: .queried)
        XCTAssertEqual(queried.count, 2)
    }

    func testGetActiveDealsExcludesTerminalStages() {
        let contact = manager.createContact(name: "Publisher")
        manager.createDeal(title: "Active", contactId: contact.id, stage: .submitted)
        manager.createDeal(title: "Won", contactId: contact.id, stage: .contracted)
        manager.createDeal(title: "Lost", contactId: contact.id, stage: .rejected)
        let active = manager.getActiveDeals()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active[0].title, "Active")
    }

    func testUpdateDealPersistsChanges() {
        let contact = manager.createContact(name: "Publisher")
        var deal = manager.createDeal(title: "Old Title", contactId: contact.id)
        deal.title = "New Title"
        manager.updateDeal(deal)
        XCTAssertEqual(manager.getDeal(id: deal.id)?.title, "New Title")
    }

    func testDeleteDealRemovesDeal() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "To Delete", contactId: contact.id)
        manager.deleteDeal(id: deal.id)
        XCTAssertNil(manager.getDeal(id: deal.id))
    }

    func testDeleteDealAlsoRemovesAssociatedInteractions() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Deal", contactId: contact.id)
        manager.logInteraction(contactId: contact.id, dealId: deal.id, type: .email, summary: "Follow up")
        manager.deleteDeal(id: deal.id)
        XCTAssertTrue(manager.getInteractions(forDeal: deal.id).isEmpty)
    }

    // MARK: - Deal Stage Advancement

    func testAdvanceDealMovesToNextStage() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Submission", contactId: contact.id, stage: .prospect)
        let newStage = manager.advanceDeal(id: deal.id)
        XCTAssertEqual(newStage, .queried)
        XCTAssertEqual(manager.getDeal(id: deal.id)?.stage, .queried)
    }

    func testAdvanceDealThroughFullPipeline() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id, stage: .prospect)
        var stages: [DealStage] = []
        while let next = manager.advanceDeal(id: deal.id) {
            stages.append(next)
        }
        XCTAssertEqual(stages, [.queried, .requested, .submitted, .contracted])
    }

    func testAdvanceDealReturnsNilAtContracted() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id, stage: .contracted)
        XCTAssertNil(manager.advanceDeal(id: deal.id))
    }

    func testAdvanceDealReturnsNilAtRejected() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id, stage: .rejected)
        XCTAssertNil(manager.advanceDeal(id: deal.id))
    }

    func testAdvanceDealSetsClosedAtWhenContracted() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id, stage: .submitted)
        manager.advanceDeal(id: deal.id)
        XCTAssertNotNil(manager.getDeal(id: deal.id)?.metadata.closedAt)
    }

    func testAdvanceDealReturnsNilForUnknownId() {
        XCTAssertNil(manager.advanceDeal(id: UUID()))
    }

    // MARK: - Deal Rejection

    func testRejectDealSetsRejectedStage() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Manuscript", contactId: contact.id, stage: .queried)
        let updated = manager.rejectDeal(id: deal.id)
        XCTAssertEqual(updated?.stage, .rejected)
        XCTAssertEqual(manager.getDeal(id: deal.id)?.stage, .rejected)
    }

    func testRejectDealSetsClosedAt() {
        let contact = manager.createContact(name: "Publisher")
        let deal = manager.createDeal(title: "Manuscript", contactId: contact.id)
        manager.rejectDeal(id: deal.id)
        XCTAssertNotNil(manager.getDeal(id: deal.id)?.metadata.closedAt)
    }

    func testRejectDealReturnsNilForUnknownId() {
        XCTAssertNil(manager.rejectDeal(id: UUID()))
    }

    // MARK: - Interaction Management

    func testLogInteractionCreatesInteraction() {
        let contact = manager.createContact(name: "Agent")
        let interaction = manager.logInteraction(contactId: contact.id, type: .email, summary: "Query sent")
        XCTAssertEqual(interaction.contactId, contact.id)
        XCTAssertEqual(interaction.type, .email)
        XCTAssertEqual(interaction.summary, "Query sent")
    }

    func testLogInteractionWithDeal() {
        let contact = manager.createContact(name: "Agent")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id)
        let interaction = manager.logInteraction(contactId: contact.id, dealId: deal.id, type: .meeting, summary: "Call notes")
        XCTAssertEqual(interaction.dealId, deal.id)
    }

    func testLogInteractionUpdatesLastContacted() {
        let contact = manager.createContact(name: "Agent")
        let before = contact.metadata.lastContacted
        XCTAssertNil(before)
        manager.logInteraction(contactId: contact.id, type: .call, summary: "Quick call")
        let updated = manager.getContact(id: contact.id)
        XCTAssertNotNil(updated?.metadata.lastContacted)
    }

    func testGetInteractionsForContactReturnsSortedNewestFirst() {
        let contact = manager.createContact(name: "Agent")
        let past = Date(timeIntervalSinceNow: -3600)
        let now = Date()
        manager.logInteraction(contactId: contact.id, type: .email, summary: "Old", date: past)
        manager.logInteraction(contactId: contact.id, type: .call, summary: "New", date: now)
        let interactions = manager.getInteractions(forContact: contact.id)
        XCTAssertEqual(interactions.count, 2)
        XCTAssertEqual(interactions[0].summary, "New")
        XCTAssertEqual(interactions[1].summary, "Old")
    }

    func testGetInteractionsForDeal() {
        let contact = manager.createContact(name: "Agent")
        let deal = manager.createDeal(title: "Novel", contactId: contact.id)
        manager.logInteraction(contactId: contact.id, type: .email, summary: "No deal")
        manager.logInteraction(contactId: contact.id, dealId: deal.id, type: .email, summary: "With deal")
        let dealInteractions = manager.getInteractions(forDeal: deal.id)
        XCTAssertEqual(dealInteractions.count, 1)
        XCTAssertEqual(dealInteractions[0].summary, "With deal")
    }

    func testGetRecentInteractionsRespectsLimit() {
        let contact = manager.createContact(name: "Agent")
        for i in 0..<10 {
            manager.logInteraction(contactId: contact.id, type: .note, summary: "Note \(i)")
        }
        let recent = manager.getRecentInteractions(limit: 5)
        XCTAssertEqual(recent.count, 5)
    }

    func testDeleteInteractionRemovesInteraction() {
        let contact = manager.createContact(name: "Agent")
        let interaction = manager.logInteraction(contactId: contact.id, type: .email, summary: "To delete")
        manager.deleteInteraction(id: interaction.id)
        XCTAssertTrue(manager.getInteractions(forContact: contact.id).isEmpty)
    }

    // MARK: - CRM Statistics

    func testGetCRMStatsReflectsContactCount() {
        manager.createContact(name: "A")
        manager.createContact(name: "B")
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalContacts, 2)
    }

    func testGetCRMStatsReflectsDealCount() {
        let contact = manager.createContact(name: "Publisher")
        manager.createDeal(title: "Deal 1", contactId: contact.id)
        manager.createDeal(title: "Deal 2", contactId: contact.id)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalDeals, 2)
    }

    func testGetCRMStatsCountsActiveDeals() {
        let contact = manager.createContact(name: "Publisher")
        manager.createDeal(title: "Active", contactId: contact.id, stage: .submitted)
        manager.createDeal(title: "Won", contactId: contact.id, stage: .contracted)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.activeDeals, 1)
        XCTAssertEqual(stats.contractedDeals, 1)
    }

    func testGetCRMStatsTotalPipelineValueSumsActiveDeals() {
        let contact = manager.createContact(name: "Publisher")
        manager.createDeal(title: "Active", contactId: contact.id, stage: .queried, value: 10000)
        manager.createDeal(title: "Won", contactId: contact.id, stage: .contracted, value: 50000)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalPipelineValue, 10000, accuracy: 0.01,
                       "Pipeline value should only include non-terminal deals")
    }

    func testGetCRMStatsStartsEmpty() {
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalContacts, 0)
        XCTAssertEqual(stats.totalDeals, 0)
        XCTAssertEqual(stats.activeDeals, 0)
        XCTAssertEqual(stats.contractedDeals, 0)
        XCTAssertEqual(stats.totalPipelineValue, 0.0, accuracy: 0.001)
    }

    // MARK: - DealStage model

    func testDealStageDisplayNames() {
        XCTAssertEqual(DealStage.prospect.displayName, "Prospect")
        XCTAssertEqual(DealStage.queried.displayName, "Queried")
        XCTAssertEqual(DealStage.contracted.displayName, "Contracted")
        XCTAssertEqual(DealStage.rejected.displayName, "Rejected")
    }

    func testDealStageIsTerminal() {
        XCTAssertTrue(DealStage.contracted.isTerminal)
        XCTAssertTrue(DealStage.rejected.isTerminal)
        XCTAssertFalse(DealStage.prospect.isTerminal)
        XCTAssertFalse(DealStage.submitted.isTerminal)
    }

    func testDealStageNextValues() {
        XCTAssertEqual(DealStage.prospect.next, .queried)
        XCTAssertEqual(DealStage.queried.next, .requested)
        XCTAssertEqual(DealStage.requested.next, .submitted)
        XCTAssertEqual(DealStage.submitted.next, .contracted)
        XCTAssertNil(DealStage.contracted.next)
        XCTAssertNil(DealStage.rejected.next)
    }

    func testDealStageCodableRoundTrip() throws {
        for stage in DealStage.allCases {
            let data = try JSONEncoder().encode(stage)
            let decoded = try JSONDecoder().decode(DealStage.self, from: data)
            XCTAssertEqual(decoded, stage)
        }
    }

    // MARK: - InteractionType model

    func testInteractionTypeDisplayNames() {
        XCTAssertEqual(InteractionType.email.displayName, "Email")
        XCTAssertEqual(InteractionType.call.displayName, "Call")
        XCTAssertEqual(InteractionType.meeting.displayName, "Meeting")
        XCTAssertEqual(InteractionType.submission.displayName, "Submission")
        XCTAssertEqual(InteractionType.note.displayName, "Note")
    }

    func testInteractionTypeCodableRoundTrip() throws {
        for type_ in InteractionType.allCases {
            let data = try JSONEncoder().encode(type_)
            let decoded = try JSONDecoder().decode(InteractionType.self, from: data)
            XCTAssertEqual(decoded, type_)
        }
    }
}
