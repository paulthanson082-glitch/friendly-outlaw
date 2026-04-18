import Foundation

// MARK: - CRMManager

/// Manages CRM contacts, deals, and interaction history for the writers app.
/// Tracks relationships with publishers, editors, agents, and other industry contacts.
public class CRMManager {

    // MARK: - Private Storage

    private var contacts: [UUID: CRMContact] = [:]
    private var deals: [UUID: CRMDeal] = [:]
    private var interactions: [UUID: CRMInteraction] = [:]

    public init() {}

    // MARK: - Contact CRUD

    /// Create and store a new CRM contact
    @discardableResult
    public func createContact(
        name: String,
        email: String? = nil,
        phone: String? = nil,
        company: String? = nil,
        role: String? = nil,
        tags: [String] = [],
        notes: String = ""
    ) -> CRMContact {
        let contact = CRMContact(
            name: name,
            email: email,
            phone: phone,
            company: company,
            role: role,
            tags: tags,
            notes: notes
        )
        contacts[contact.id] = contact
        return contact
    }

    /// Retrieve a contact by ID
    public func getContact(id: UUID) -> CRMContact? {
        contacts[id]
    }

    /// Return all contacts sorted by name
    public func getAllContacts() -> [CRMContact] {
        contacts.values.sorted { $0.name < $1.name }
    }

    /// Persist an updated contact
    public func updateContact(_ contact: CRMContact) {
        guard contacts[contact.id] != nil else { return }
        var updated = contact
        updated.metadata.modified = Date()
        contacts[contact.id] = updated
    }

    /// Remove a contact and all associated deals and interactions
    public func deleteContact(id: UUID) {
        contacts.removeValue(forKey: id)
        let contactDeals = deals.values.filter { $0.contactId == id }.map { $0.id }
        for dealId in contactDeals {
            deleteDeal(id: dealId)
        }
        interactions = interactions.filter { $0.value.contactId != id }
    }

    /// Search contacts by name, company, role, email, or tags
    public func searchContacts(query: String) -> [CRMContact] {
        let lowered = query.lowercased()
        return contacts.values.filter { contact in
            contact.name.lowercased().contains(lowered)
            || (contact.company?.lowercased().contains(lowered) ?? false)
            || (contact.role?.lowercased().contains(lowered) ?? false)
            || (contact.email?.lowercased().contains(lowered) ?? false)
            || contact.tags.contains { $0.lowercased().contains(lowered) }
        }.sorted { $0.name < $1.name }
    }

    // MARK: - Deal CRUD

    /// Create and store a new deal linked to a contact
    @discardableResult
    public func createDeal(
        title: String,
        contactId: UUID,
        stage: DealStage = .prospect,
        value: Double? = nil,
        documentId: UUID? = nil,
        notes: String = ""
    ) -> CRMDeal {
        let deal = CRMDeal(
            title: title,
            contactId: contactId,
            stage: stage,
            value: value,
            documentId: documentId,
            notes: notes
        )
        deals[deal.id] = deal
        return deal
    }

    /// Retrieve a deal by ID
    public func getDeal(id: UUID) -> CRMDeal? {
        deals[id]
    }

    /// Return all deals for a specific contact
    public func getDeals(forContact contactId: UUID) -> [CRMDeal] {
        deals.values
            .filter { $0.contactId == contactId }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Return all deals in a given pipeline stage
    public func getDeals(inStage stage: DealStage) -> [CRMDeal] {
        deals.values
            .filter { $0.stage == stage }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Return all active (non-terminal) deals
    public func getActiveDeals() -> [CRMDeal] {
        deals.values
            .filter { !$0.stage.isTerminal }
            .sorted { $0.metadata.created > $1.metadata.created }
    }

    /// Persist an updated deal
    public func updateDeal(_ deal: CRMDeal) {
        guard deals[deal.id] != nil else { return }
        var updated = deal
        updated.metadata.modified = Date()
        deals[deal.id] = updated
    }

    /// Remove a deal and its associated interactions
    public func deleteDeal(id: UUID) {
        deals.removeValue(forKey: id)
        interactions = interactions.filter { $0.value.dealId != id }
    }

    /// Advance a deal to its next stage. Returns the new stage, or nil if already terminal.
    @discardableResult
    public func advanceDeal(id: UUID) -> DealStage? {
        guard var deal = deals[id], let next = deal.stage.next else { return nil }
        deal.stage = next
        deal.metadata.modified = Date()
        if next.isTerminal {
            deal.metadata.closedAt = Date()
        }
        deals[id] = deal
        return next
    }

    /// Mark a deal as rejected (lost). Returns the updated deal.
    @discardableResult
    public func rejectDeal(id: UUID) -> CRMDeal? {
        guard var deal = deals[id] else { return nil }
        deal.stage = .rejected
        deal.metadata.modified = Date()
        deal.metadata.closedAt = Date()
        deals[id] = deal
        return deal
    }

    // MARK: - Interaction CRUD

    /// Log a new interaction with a contact
    @discardableResult
    public func logInteraction(
        contactId: UUID,
        dealId: UUID? = nil,
        type: InteractionType,
        summary: String,
        date: Date = Date()
    ) -> CRMInteraction {
        let interaction = CRMInteraction(
            contactId: contactId,
            dealId: dealId,
            type: type,
            summary: summary,
            date: date
        )
        interactions[interaction.id] = interaction
        // Update the contact's lastContacted timestamp
        if var contact = contacts[contactId] {
            contact.metadata.lastContacted = date
            contact.metadata.modified = Date()
            contacts[contactId] = contact
        }
        return interaction
    }

    /// Retrieve all interactions for a contact, sorted newest first
    public func getInteractions(forContact contactId: UUID) -> [CRMInteraction] {
        interactions.values
            .filter { $0.contactId == contactId }
            .sorted { $0.date > $1.date }
    }

    /// Retrieve all interactions for a deal, sorted newest first
    public func getInteractions(forDeal dealId: UUID) -> [CRMInteraction] {
        interactions.values
            .filter { $0.dealId == dealId }
            .sorted { $0.date > $1.date }
    }

    /// Retrieve the most recent interactions across all contacts
    public func getRecentInteractions(limit: Int = 20) -> [CRMInteraction] {
        Array(
            interactions.values
                .sorted { $0.date > $1.date }
                .prefix(limit)
        )
    }

    /// Delete an interaction by ID
    public func deleteInteraction(id: UUID) {
        interactions.removeValue(forKey: id)
    }

    // MARK: - Statistics

    /// Compute aggregate CRM statistics for the dashboard
    public func getCRMStats() -> CRMStats {
        let allDeals = Array(deals.values)
        let activeDeals = allDeals.filter { !$0.stage.isTerminal }
        let contracted = allDeals.filter { $0.stage == .contracted }
        let pipelineValue = allDeals
            .filter { !$0.stage.isTerminal }
            .compactMap { $0.value }
            .reduce(0, +)

        var byStage: [DealStage: Int] = [:]
        for stage in DealStage.allCases {
            byStage[stage] = allDeals.filter { $0.stage == stage }.count
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCount = interactions.values.filter { $0.date >= thirtyDaysAgo }.count

        return CRMStats(
            totalContacts: contacts.count,
            totalDeals: allDeals.count,
            activeDeals: activeDeals.count,
            contractedDeals: contracted.count,
            totalPipelineValue: pipelineValue,
            dealsByStage: byStage,
            recentInteractionCount: recentCount
        )
    }
}
