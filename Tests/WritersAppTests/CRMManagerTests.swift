import XCTest
@testable import WritersApp

// MARK: - DealStage Tests

final class DealStageTests: XCTestCase {

    func testDealStageRawValues() {
        XCTAssertEqual(DealStage.prospect.rawValue, "prospect")
        XCTAssertEqual(DealStage.queried.rawValue, "queried")
        XCTAssertEqual(DealStage.requested.rawValue, "requested")
        XCTAssertEqual(DealStage.submitted.rawValue, "submitted")
        XCTAssertEqual(DealStage.contracted.rawValue, "contracted")
        XCTAssertEqual(DealStage.rejected.rawValue, "rejected")
    }

    func testDealStageDisplayNames() {
        XCTAssertEqual(DealStage.prospect.displayName, "Prospect")
        XCTAssertEqual(DealStage.queried.displayName, "Queried")
        XCTAssertEqual(DealStage.requested.displayName, "Requested")
        XCTAssertEqual(DealStage.submitted.displayName, "Submitted")
        XCTAssertEqual(DealStage.contracted.displayName, "Contracted")
        XCTAssertEqual(DealStage.rejected.displayName, "Rejected")
    }

    func testDealStageMetalNames() {
        XCTAssertEqual(DealStage.prospect.metalName, "The Hunt")
        XCTAssertEqual(DealStage.queried.metalName, "First Blood")
        XCTAssertEqual(DealStage.requested.metalName, "Full Assault")
        XCTAssertEqual(DealStage.submitted.metalName, "In the Pit")
        XCTAssertEqual(DealStage.contracted.metalName, "Victory Lap")
        XCTAssertEqual(DealStage.rejected.metalName, "Fallen")
    }

    func testDealStageNextProgression() {
        XCTAssertEqual(DealStage.prospect.next, .queried)
        XCTAssertEqual(DealStage.queried.next, .requested)
        XCTAssertEqual(DealStage.requested.next, .submitted)
        XCTAssertEqual(DealStage.submitted.next, .contracted)
        XCTAssertNil(DealStage.contracted.next)
        XCTAssertNil(DealStage.rejected.next)
    }

    func testDealStageIsTerminal() {
        XCTAssertFalse(DealStage.prospect.isTerminal)
        XCTAssertFalse(DealStage.queried.isTerminal)
        XCTAssertFalse(DealStage.requested.isTerminal)
        XCTAssertFalse(DealStage.submitted.isTerminal)
        XCTAssertTrue(DealStage.contracted.isTerminal)
        XCTAssertTrue(DealStage.rejected.isTerminal)
    }

    func testDealStageCodableRoundTrip() throws {
        for stage in DealStage.allCases {
            let encoded = try JSONEncoder().encode(stage)
            let decoded = try JSONDecoder().decode(DealStage.self, from: encoded)
            XCTAssertEqual(decoded, stage)
        }
    }

    func testDealStageAllCasesCount() {
        XCTAssertEqual(DealStage.allCases.count, 6)
    }
}

// MARK: - InteractionType Tests

final class InteractionTypeTests: XCTestCase {

    func testInteractionTypeRawValues() {
        XCTAssertEqual(InteractionType.email.rawValue, "email")
        XCTAssertEqual(InteractionType.call.rawValue, "call")
        XCTAssertEqual(InteractionType.meeting.rawValue, "meeting")
        XCTAssertEqual(InteractionType.submission.rawValue, "submission")
        XCTAssertEqual(InteractionType.note.rawValue, "note")
    }

    func testInteractionTypeDisplayNames() {
        XCTAssertEqual(InteractionType.email.displayName, "Email")
        XCTAssertEqual(InteractionType.call.displayName, "Call")
        XCTAssertEqual(InteractionType.meeting.displayName, "Meeting")
        XCTAssertEqual(InteractionType.submission.displayName, "Submission")
        XCTAssertEqual(InteractionType.note.displayName, "Note")
    }

    func testInteractionTypeSystemImageNames() {
        XCTAssertEqual(InteractionType.email.systemImageName, "envelope.fill")
        XCTAssertEqual(InteractionType.call.systemImageName, "phone.fill")
        XCTAssertEqual(InteractionType.meeting.systemImageName, "person.2.fill")
        XCTAssertEqual(InteractionType.submission.systemImageName, "paperplane.fill")
        XCTAssertEqual(InteractionType.note.systemImageName, "note.text")
    }

    func testInteractionTypeCodableRoundTrip() throws {
        for interactionType in InteractionType.allCases {
            let encoded = try JSONEncoder().encode(interactionType)
            let decoded = try JSONDecoder().decode(InteractionType.self, from: encoded)
            XCTAssertEqual(decoded, interactionType)
        }
    }
}

// MARK: - CRMManager Contact CRUD Tests

final class CRMManagerContactTests: XCTestCase {

    var manager: CRMManager!

    override func setUp() {
        super.setUp()
        manager = CRMManager()
    }

    func testCreateContactReturnsContactWithGivenName() {
        let contact = manager.createContact(name: "Alice Agent")
        XCTAssertEqual(contact.name, "Alice Agent")
    }

    func testCreateContactStoresAllOptionalFields() {
        let contact = manager.createContact(
            name: "Bob Publisher",
            email: "bob@pub.com",
            phone: "555-1234",
            company: "Big Press",
            role: "Publisher",
            tags: ["fiction", "thriller"],
            notes: "Met at conference"
        )
        XCTAssertEqual(contact.email, "bob@pub.com")
        XCTAssertEqual(contact.phone, "555-1234")
        XCTAssertEqual(contact.company, "Big Press")
        XCTAssertEqual(contact.role, "Publisher")
        XCTAssertEqual(contact.tags, ["fiction", "thriller"])
        XCTAssertEqual(contact.notes, "Met at conference")
    }

    func testGetContactByIdReturnsCreatedContact() {
        let contact = manager.createContact(name: "Carol Editor")
        let retrieved = manager.getContact(id: contact.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, contact.id)
        XCTAssertEqual(retrieved?.name, "Carol Editor")
    }

    func testGetContactByIdReturnsNilForUnknownId() {
        let result = manager.getContact(id: UUID())
        XCTAssertNil(result)
    }

    func testGetAllContactsReturnsAllCreatedContacts() {
        manager.createContact(name: "Alice")
        manager.createContact(name: "Bob")
        manager.createContact(name: "Carol")
        let all = manager.getAllContacts()
        XCTAssertEqual(all.count, 3)
    }

    func testGetAllContactsSortedByName() {
        manager.createContact(name: "Zara")
        manager.createContact(name: "Alice")
        manager.createContact(name: "Mike")
        let names = manager.getAllContacts().map { $0.name }
        XCTAssertEqual(names, ["Alice", "Mike", "Zara"])
    }

    func testUpdateContactPersistsChanges() {
        var contact = manager.createContact(name: "Old Name")
        contact.name = "New Name"
        manager.updateContact(contact)
        let retrieved = manager.getContact(id: contact.id)
        XCTAssertEqual(retrieved?.name, "New Name")
    }

    func testUpdateContactIgnoresUnknownId() {
        let unknown = CRMContact(name: "Ghost")
        manager.updateContact(unknown) // should not crash or add the contact
        XCTAssertNil(manager.getContact(id: unknown.id))
        XCTAssertEqual(manager.getAllContacts().count, 0)
    }

    func testDeleteContactRemovesContact() {
        let contact = manager.createContact(name: "To Delete")
        manager.deleteContact(id: contact.id)
        XCTAssertNil(manager.getContact(id: contact.id))
    }

    func testDeleteContactAlsoDeletesAssociatedDeals() {
        let contact = manager.createContact(name: "With Deal")
        let deal = manager.createDeal(title: "Big Contract", contactId: contact.id)
        XCTAssertNotNil(manager.getDeal(id: deal.id))
        manager.deleteContact(id: contact.id)
        XCTAssertNil(manager.getDeal(id: deal.id))
    }

    func testDeleteContactAlsoDeletesAssociatedInteractions() {
        let contact = manager.createContact(name: "With Interaction")
        let interaction = manager.logInteraction(contactId: contact.id, type: .email, summary: "Hello")
        XCTAssertEqual(manager.getInteractions(forContact: contact.id).count, 1)
        manager.deleteContact(id: contact.id)
        XCTAssertEqual(manager.getInteractions(forContact: contact.id).count, 0)
        _ = interaction // suppress unused warning
    }

    func testSearchContactsByName() {
        manager.createContact(name: "Alice Agent", email: "alice@agents.com")
        manager.createContact(name: "Bob Publisher")
        let results = manager.searchContacts(query: "alice")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Alice Agent")
    }

    func testSearchContactsByEmail() {
        manager.createContact(name: "Carol", email: "carol@bigpress.com")
        manager.createContact(name: "Dave", email: "dave@other.com")
        let results = manager.searchContacts(query: "bigpress")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Carol")
    }

    func testSearchContactsByCompany() {
        manager.createContact(name: "Eve", company: "Penguin Books")
        manager.createContact(name: "Frank", company: "Random House")
        let results = manager.searchContacts(query: "penguin")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Eve")
    }

    func testSearchContactsByRole() {
        manager.createContact(name: "Grace", role: "Literary Agent")
        manager.createContact(name: "Hank", role: "Editor")
        let results = manager.searchContacts(query: "literary")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Grace")
    }

    func testSearchContactsByTag() {
        manager.createContact(name: "Ivy", tags: ["mystery", "thriller"])
        manager.createContact(name: "Jack", tags: ["romance"])
        let results = manager.searchContacts(query: "thriller")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Ivy")
    }

    func testSearchContactsReturnsEmptyWhenNoMatch() {
        manager.createContact(name: "Alice")
        let results = manager.searchContacts(query: "zzznomatch")
        XCTAssertTrue(results.isEmpty)
    }

    func testSearchContactsIsCaseInsensitive() {
        manager.createContact(name: "Alice")
        let results = manager.searchContacts(query: "ALICE")
        XCTAssertFalse(results.isEmpty)
    }
}

// MARK: - CRMManager Deal CRUD Tests

final class CRMManagerDealTests: XCTestCase {

    var manager: CRMManager!
    var contactId: UUID!

    override func setUp() {
        super.setUp()
        manager = CRMManager()
        contactId = manager.createContact(name: "Test Contact").id
    }

    func testCreateDealReturnsProspectByDefault() {
        let deal = manager.createDeal(title: "My Novel", contactId: contactId)
        XCTAssertEqual(deal.stage, .prospect)
    }

    func testCreateDealWithExplicitStage() {
        let deal = manager.createDeal(title: "Deal", contactId: contactId, stage: .submitted)
        XCTAssertEqual(deal.stage, .submitted)
    }

    func testCreateDealWithValue() {
        let deal = manager.createDeal(title: "Deal", contactId: contactId, value: 5000.0)
        XCTAssertEqual(deal.value, 5000.0)
    }

    func testGetDealByIdReturnsCreatedDeal() {
        let deal = manager.createDeal(title: "My Deal", contactId: contactId)
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertEqual(retrieved?.id, deal.id)
        XCTAssertEqual(retrieved?.title, "My Deal")
    }

    func testGetDealByIdReturnsNilForUnknownId() {
        XCTAssertNil(manager.getDeal(id: UUID()))
    }

    func testGetDealsForContactReturnsOnlyContactDeals() {
        let contact2 = manager.createContact(name: "Other Contact")
        manager.createDeal(title: "Deal A", contactId: contactId)
        manager.createDeal(title: "Deal B", contactId: contactId)
        manager.createDeal(title: "Deal C", contactId: contact2.id)
        let deals = manager.getDeals(forContact: contactId)
        XCTAssertEqual(deals.count, 2)
        XCTAssertTrue(deals.allSatisfy { $0.contactId == contactId })
    }

    func testGetDealsInStageFiltersCorrectly() {
        manager.createDeal(title: "Prospect Deal", contactId: contactId, stage: .prospect)
        manager.createDeal(title: "Queried Deal", contactId: contactId, stage: .queried)
        let prospects = manager.getDeals(inStage: .prospect)
        XCTAssertEqual(prospects.count, 1)
        XCTAssertEqual(prospects[0].title, "Prospect Deal")
    }

    func testGetActiveDealsExcludesTerminalDeals() {
        manager.createDeal(title: "Active", contactId: contactId, stage: .queried)
        manager.createDeal(title: "Contracted", contactId: contactId, stage: .contracted)
        manager.createDeal(title: "Rejected", contactId: contactId, stage: .rejected)
        let active = manager.getActiveDeals()
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active[0].title, "Active")
    }

    func testUpdateDealPersistsChanges() {
        var deal = manager.createDeal(title: "Old Title", contactId: contactId)
        deal.title = "New Title"
        manager.updateDeal(deal)
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertEqual(retrieved?.title, "New Title")
    }

    func testUpdateDealIgnoresUnknownId() {
        let unknown = CRMDeal(title: "Ghost", contactId: contactId)
        manager.updateDeal(unknown)
        XCTAssertNil(manager.getDeal(id: unknown.id))
    }

    func testDeleteDealRemovesDeal() {
        let deal = manager.createDeal(title: "Doomed Deal", contactId: contactId)
        manager.deleteDeal(id: deal.id)
        XCTAssertNil(manager.getDeal(id: deal.id))
    }

    func testDeleteDealAlsoRemovesLinkedInteractions() {
        let deal = manager.createDeal(title: "Deal With Interaction", contactId: contactId)
        manager.logInteraction(contactId: contactId, dealId: deal.id, type: .email, summary: "Sent pitch")
        XCTAssertEqual(manager.getInteractions(forDeal: deal.id).count, 1)
        manager.deleteDeal(id: deal.id)
        XCTAssertEqual(manager.getInteractions(forDeal: deal.id).count, 0)
    }

    func testAdvanceDealProgressesStageSequentially() {
        let deal = manager.createDeal(title: "Stage Deal", contactId: contactId, stage: .prospect)
        let next = manager.advanceDeal(id: deal.id)
        XCTAssertEqual(next, .queried)
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertEqual(retrieved?.stage, .queried)
    }

    func testAdvanceDealThroughFullPipeline() {
        let deal = manager.createDeal(title: "Pipeline Deal", contactId: contactId)
        var stage = deal.stage
        let expected: [DealStage] = [.queried, .requested, .submitted, .contracted]
        for expectedStage in expected {
            let next = manager.advanceDeal(id: deal.id)
            XCTAssertEqual(next, expectedStage)
            stage = expectedStage
        }
        XCTAssertEqual(stage, .contracted)
        // contracted is terminal — advance should return nil
        XCTAssertNil(manager.advanceDeal(id: deal.id))
    }

    func testAdvanceDealSetsClosedAtWhenContracted() {
        let deal = manager.createDeal(title: "Deal", contactId: contactId, stage: .submitted)
        manager.advanceDeal(id: deal.id) // → contracted
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertNotNil(retrieved?.metadata.closedAt)
    }

    func testAdvanceDealReturnsNilForUnknownId() {
        let result = manager.advanceDeal(id: UUID())
        XCTAssertNil(result)
    }

    func testRejectDealSetsRejectedStage() {
        let deal = manager.createDeal(title: "Rejected Deal", contactId: contactId, stage: .submitted)
        let updated = manager.rejectDeal(id: deal.id)
        XCTAssertEqual(updated?.stage, .rejected)
        let retrieved = manager.getDeal(id: deal.id)
        XCTAssertEqual(retrieved?.stage, .rejected)
    }

    func testRejectDealSetsClosedAt() {
        let deal = manager.createDeal(title: "Doomed Deal", contactId: contactId)
        let updated = manager.rejectDeal(id: deal.id)
        XCTAssertNotNil(updated?.metadata.closedAt)
    }

    func testRejectDealReturnsNilForUnknownId() {
        XCTAssertNil(manager.rejectDeal(id: UUID()))
    }
}

// MARK: - CRMManager Interaction Tests

final class CRMManagerInteractionTests: XCTestCase {

    var manager: CRMManager!
    var contactId: UUID!

    override func setUp() {
        super.setUp()
        manager = CRMManager()
        contactId = manager.createContact(name: "Interaction Contact").id
    }

    func testLogInteractionCreatesInteractionForContact() {
        let interaction = manager.logInteraction(contactId: contactId, type: .email, summary: "Initial pitch")
        XCTAssertEqual(interaction.contactId, contactId)
        XCTAssertEqual(interaction.type, .email)
        XCTAssertEqual(interaction.summary, "Initial pitch")
    }

    func testLogInteractionWithDealLink() {
        let deal = manager.createDeal(title: "Deal", contactId: contactId)
        let interaction = manager.logInteraction(contactId: contactId, dealId: deal.id, type: .submission, summary: "Sent manuscript")
        XCTAssertEqual(interaction.dealId, deal.id)
    }

    func testLogInteractionUpdatesContactLastContacted() {
        let before = manager.getContact(id: contactId)?.metadata.lastContacted
        XCTAssertNil(before)
        manager.logInteraction(contactId: contactId, type: .call, summary: "Quick chat")
        let after = manager.getContact(id: contactId)?.metadata.lastContacted
        XCTAssertNotNil(after)
    }

    func testGetInteractionsForContactReturnsSortedNewestFirst() {
        let older = Date(timeIntervalSinceNow: -3600)
        let newer = Date()
        manager.logInteraction(contactId: contactId, type: .email, summary: "Old email", date: older)
        manager.logInteraction(contactId: contactId, type: .call, summary: "New call", date: newer)
        let interactions = manager.getInteractions(forContact: contactId)
        XCTAssertEqual(interactions.count, 2)
        XCTAssertGreaterThan(interactions[0].date, interactions[1].date)
    }

    func testGetInteractionsForContactReturnsOnlyContactInteractions() {
        let other = manager.createContact(name: "Other")
        manager.logInteraction(contactId: contactId, type: .email, summary: "Mine")
        manager.logInteraction(contactId: other.id, type: .note, summary: "Theirs")
        let mine = manager.getInteractions(forContact: contactId)
        XCTAssertEqual(mine.count, 1)
        XCTAssertEqual(mine[0].summary, "Mine")
    }

    func testGetInteractionsForDealReturnsOnlyDealInteractions() {
        let deal = manager.createDeal(title: "Deal", contactId: contactId)
        manager.logInteraction(contactId: contactId, dealId: deal.id, type: .submission, summary: "For deal")
        manager.logInteraction(contactId: contactId, type: .note, summary: "General note")
        let dealInteractions = manager.getInteractions(forDeal: deal.id)
        XCTAssertEqual(dealInteractions.count, 1)
        XCTAssertEqual(dealInteractions[0].summary, "For deal")
    }

    func testGetRecentInteractionsReturnsLimitedResults() {
        for i in 1...25 {
            manager.logInteraction(contactId: contactId, type: .note, summary: "Note \(i)")
        }
        let recent = manager.getRecentInteractions(limit: 10)
        XCTAssertEqual(recent.count, 10)
    }

    func testGetRecentInteractionsDefaultLimitIs20() {
        for i in 1...25 {
            manager.logInteraction(contactId: contactId, type: .note, summary: "Note \(i)")
        }
        let recent = manager.getRecentInteractions()
        XCTAssertEqual(recent.count, 20)
    }

    func testDeleteInteractionRemovesInteraction() {
        let interaction = manager.logInteraction(contactId: contactId, type: .email, summary: "To remove")
        XCTAssertEqual(manager.getInteractions(forContact: contactId).count, 1)
        manager.deleteInteraction(id: interaction.id)
        XCTAssertEqual(manager.getInteractions(forContact: contactId).count, 0)
    }
}

// MARK: - CRMManager Statistics Tests

final class CRMManagerStatsTests: XCTestCase {

    var manager: CRMManager!

    override func setUp() {
        super.setUp()
        manager = CRMManager()
    }

    func testEmptyManagerHasZeroStats() {
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalContacts, 0)
        XCTAssertEqual(stats.totalDeals, 0)
        XCTAssertEqual(stats.activeDeals, 0)
        XCTAssertEqual(stats.contractedDeals, 0)
        XCTAssertEqual(stats.totalPipelineValue, 0)
        XCTAssertEqual(stats.recentInteractionCount, 0)
    }

    func testTotalContactsReflectsAllContacts() {
        manager.createContact(name: "A")
        manager.createContact(name: "B")
        manager.createContact(name: "C")
        XCTAssertEqual(manager.getCRMStats().totalContacts, 3)
    }

    func testTotalDealsAndActiveDeals() {
        let c = manager.createContact(name: "Contact")
        manager.createDeal(title: "Active", contactId: c.id, stage: .queried)
        manager.createDeal(title: "Contracted", contactId: c.id, stage: .contracted)
        manager.createDeal(title: "Rejected", contactId: c.id, stage: .rejected)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalDeals, 3)
        XCTAssertEqual(stats.activeDeals, 1)
        XCTAssertEqual(stats.contractedDeals, 1)
    }

    func testPipelineValueSumsActiveDealsWithValues() {
        let c = manager.createContact(name: "Contact")
        manager.createDeal(title: "Deal A", contactId: c.id, stage: .queried, value: 1000.0)
        manager.createDeal(title: "Deal B", contactId: c.id, stage: .submitted, value: 2500.0)
        // Terminal deals should NOT be counted in pipeline value
        manager.createDeal(title: "Contracted", contactId: c.id, stage: .contracted, value: 5000.0)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.totalPipelineValue, 3500.0, accuracy: 0.01)
    }

    func testDealsByStageMapCoversAllStages() {
        let stats = manager.getCRMStats()
        for stage in DealStage.allCases {
            XCTAssertNotNil(stats.dealsByStage[stage], "dealsByStage must include stage: \(stage.rawValue)")
        }
    }

    func testDealsByStageCountsCorrectly() {
        let c = manager.createContact(name: "Contact")
        manager.createDeal(title: "P1", contactId: c.id, stage: .prospect)
        manager.createDeal(title: "P2", contactId: c.id, stage: .prospect)
        manager.createDeal(title: "Q1", contactId: c.id, stage: .queried)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.dealsByStage[.prospect], 2)
        XCTAssertEqual(stats.dealsByStage[.queried], 1)
        XCTAssertEqual(stats.dealsByStage[.submitted], 0)
    }

    func testRecentInteractionCountIncludesRecentOnes() {
        let c = manager.createContact(name: "Contact")
        manager.logInteraction(contactId: c.id, type: .email, summary: "Recent", date: Date())
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.recentInteractionCount, 1)
    }

    func testRecentInteractionCountExcludesOldOnes() {
        let c = manager.createContact(name: "Contact")
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        manager.logInteraction(contactId: c.id, type: .email, summary: "Old", date: oldDate)
        let stats = manager.getCRMStats()
        XCTAssertEqual(stats.recentInteractionCount, 0)
    }
}
