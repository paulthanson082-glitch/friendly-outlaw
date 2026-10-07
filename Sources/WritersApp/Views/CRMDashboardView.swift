#if canImport(SwiftUI)
import SwiftUI

// MARK: - CRMDashboardView

/// Full CRM dashboard with metal theme.
/// Four sections: The Body Count (stats), The Roster (contacts),
/// The Conquest (deal pipeline), and The Chronicle (interaction history).
@available(iOS 16.0, macOS 13.0, *)
public struct CRMDashboardView: View {
    @StateObject private var viewModel: CRMDashboardViewModel
    @State private var selectedTab: CRMTab = .overview
    @State private var showingAddContact = false
    @State private var showingAddDeal = false

    public init(crmManager: CRMManager) {
        _viewModel = StateObject(wrappedValue: CRMDashboardViewModel(crmManager: crmManager))
    }

    public var body: some View {
        ZStack {
            MetalTheme.abyssGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                crmHeader

                // Tab bar
                crmTabBar

                // Content
                Group {
                    switch selectedTab {
                    case .overview:   CRMOverviewSection(viewModel: viewModel)
                    case .contacts:   CRMRosterSection(viewModel: viewModel)
                    case .pipeline:   CRMConquestSection(viewModel: viewModel)
                    case .chronicle:  CRMChronicleSection(viewModel: viewModel)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactSheet(viewModel: viewModel, isPresented: $showingAddContact)
        }
        .sheet(isPresented: $showingAddDeal) {
            AddDealSheet(viewModel: viewModel, isPresented: $showingAddDeal)
        }
        .onAppear { viewModel.reload() }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if selectedTab == .contacts { showingAddContact = true }
                    else { showingAddDeal = true }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(MetalTheme.crimson)
                }
            }
        }
    }

    // MARK: - Header

    private var crmHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "network")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(MetalTheme.bloodRed)
            VStack(alignment: .leading, spacing: 2) {
                Text("THE NETWORK")
                    .font(.system(size: 20, weight: .black))
                    .tracking(4)
                    .foregroundColor(MetalTheme.chrome)
                Text("Publishing CRM")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
            }
            Spacer()
            // Quick stat pill
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.stats.activeDeals)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(MetalTheme.ember)
                Text("ACTIVE")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(MetalTheme.obsidian)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MetalTheme.bloodRed.opacity(0.6)),
            alignment: .bottom
        )
    }

    // MARK: - Tab Bar

    private var crmTabBar: some View {
        HStack(spacing: 0) {
            ForEach(CRMTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .regular))
                        Text(tab.label)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1.5)
                    }
                    .foregroundColor(selectedTab == tab ? MetalTheme.crimson : MetalTheme.steel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? MetalTheme.crimson : .clear),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(MetalTheme.obsidian)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(MetalTheme.chainLink),
            alignment: .bottom
        )
    }
}

// MARK: - CRMTab

@available(iOS 16.0, macOS 13.0, *)
enum CRMTab: CaseIterable {
    case overview, contacts, pipeline, chronicle

    var label: String {
        switch self {
        case .overview:   return "OVERVIEW"
        case .contacts:   return "ROSTER"
        case .pipeline:   return "CONQUEST"
        case .chronicle:  return "CHRONICLE"
        }
    }

    var systemImage: String {
        switch self {
        case .overview:   return "chart.bar.fill"
        case .contacts:   return "person.3.fill"
        case .pipeline:   return "arrow.right.square.fill"
        case .chronicle:  return "clock.fill"
        }
    }
}

// MARK: - Overview Section

@available(iOS 16.0, macOS 13.0, *)
private struct CRMOverviewSection: View {
    @ObservedObject var viewModel: CRMDashboardViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetalTheme.sectionTitle("The Body Count").padding(.top, 8)

                // Stats row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CRMStatCard(value: "\(viewModel.stats.totalContacts)", label: "CONTACTS", icon: "person.fill", color: MetalTheme.chrome)
                    CRMStatCard(value: "\(viewModel.stats.totalDeals)", label: "DEALS", icon: "briefcase.fill", color: MetalTheme.gold)
                    CRMStatCard(value: "\(viewModel.stats.contractedDeals)", label: "CONTRACTED", icon: "checkmark.seal.fill", color: MetalTheme.toxicGreen)
                    CRMStatCard(value: "\(viewModel.stats.recentInteractionCount)", label: "30-DAY TOUCHES", icon: "bolt.fill", color: MetalTheme.ember)
                }

                // Pipeline value
                if viewModel.stats.totalPipelineValue > 0 {
                    pipelineValueCard
                }

                // Stage breakdown
                MetalTheme.sectionTitle("Pipeline Breakdown").padding(.top, 4)
                stageBreakdown

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }

    private var pipelineValueCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                MetalTheme.sectionTitle("Total Pipeline Value")
                Text(String(format: "$%.0f", viewModel.stats.totalPipelineValue))
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(MetalTheme.conquestGradient)
            }
            Spacer()
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(MetalTheme.conquestGradient)
        }
        .metalCard()
    }

    private var stageBreakdown: some View {
        VStack(spacing: 8) {
            ForEach(DealStage.allCases, id: \.self) { stage in
                let count = viewModel.stats.dealsByStage[stage] ?? 0
                let total = max(viewModel.stats.totalDeals, 1)
                HStack(spacing: 10) {
                    Text(stage.metalName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                        .frame(width: 100, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(MetalTheme.gunmetal)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stageColor(stage))
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(total), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("\(count)")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(MetalTheme.steel)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .metalCard()
    }

    private func stageColor(_ stage: DealStage) -> Color {
        switch stage {
        case .prospect:   return MetalTheme.steel
        case .queried:    return MetalTheme.ember
        case .requested:  return MetalTheme.crimson
        case .submitted:  return MetalTheme.bloodRed
        case .contracted: return MetalTheme.toxicGreen
        case .rejected:   return MetalTheme.chainLink
        }
    }
}

// MARK: - Roster Section (Contacts)

@available(iOS 16.0, macOS 13.0, *)
private struct CRMRosterSection: View {
    @ObservedObject var viewModel: CRMDashboardViewModel
    @State private var searchQuery = ""

    var filteredContacts: [CRMContact] {
        searchQuery.isEmpty
            ? viewModel.contacts
            : viewModel.contacts.filter { contact in
                contact.name.lowercased().contains(searchQuery.lowercased())
                || (contact.company?.lowercased().contains(searchQuery.lowercased()) ?? false)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(MetalTheme.steel)
                TextField("Search the roster...", text: $searchQuery)
                    .foregroundColor(MetalTheme.chrome)
                    .tint(MetalTheme.crimson)
            }
            .padding(10)
            .background(MetalTheme.gunmetal)
            .cornerRadius(8)
            .padding(12)

            if filteredContacts.isEmpty {
                CRMEmptyState(icon: "person.3", message: "The roster is empty.\nAdd your first contact to begin the hunt.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredContacts) { contact in
                            ContactRow(contact: contact, dealCount: viewModel.dealCount(forContact: contact.id))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Conquest Section (Deal Pipeline)

@available(iOS 16.0, macOS 13.0, *)
private struct CRMConquestSection: View {
    @ObservedObject var viewModel: CRMDashboardViewModel

    var activeStages: [DealStage] {
        DealStage.allCases.filter { $0 != .rejected }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(activeStages, id: \.self) { stage in
                    PipelineColumn(
                        stage: stage,
                        deals: viewModel.deals(inStage: stage),
                        contacts: viewModel.contacts,
                        onAdvance: { deal in viewModel.advanceDeal(deal) },
                        onReject: { deal in viewModel.rejectDeal(deal) }
                    )
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Chronicle Section (Interactions)

@available(iOS 16.0, macOS 13.0, *)
private struct CRMChronicleSection: View {
    @ObservedObject var viewModel: CRMDashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            MetalTheme.sectionTitle("Recent Interactions")
                .padding(.top, 12)
                .padding(.horizontal, 16)

            if viewModel.recentInteractions.isEmpty {
                CRMEmptyState(icon: "clock", message: "No interactions logged yet.\nStart tracking your communications.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.recentInteractions) { interaction in
                            InteractionRow(
                                interaction: interaction,
                                contactName: viewModel.contactName(for: interaction.contactId)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Pipeline Column

@available(iOS 16.0, macOS 13.0, *)
private struct PipelineColumn: View {
    let stage: DealStage
    let deals: [CRMDeal]
    let contacts: [CRMContact]
    let onAdvance: (CRMDeal) -> Void
    let onReject: (CRMDeal) -> Void

    private func contactName(for id: UUID) -> String {
        contacts.first { $0.id == id }?.name ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.metalName.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(MetalTheme.steel)
                Text("\(deals.count) deal\(deals.count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MetalTheme.chainLink)
            }
            .padding(.horizontal, 4)

            // Deal cards
            if deals.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(MetalTheme.obsidian.opacity(0.5))
                    .frame(width: 220, height: 80)
                    .overlay(
                        Text("No deals")
                            .font(.system(size: 11))
                            .foregroundColor(MetalTheme.chainLink)
                    )
            } else {
                ForEach(deals) { deal in
                    DealCard(
                        deal: deal,
                        contactName: contactName(for: deal.contactId),
                        onAdvance: { onAdvance(deal) },
                        onReject: { onReject(deal) }
                    )
                }
            }
        }
        .frame(width: 220, alignment: .top)
    }
}

// MARK: - DealCard

@available(iOS 16.0, macOS 13.0, *)
private struct DealCard: View {
    let deal: CRMDeal
    let contactName: String
    let onAdvance: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(deal.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(MetalTheme.chrome)
                .lineLimit(2)

            // Contact
            Label(contactName, systemImage: "person.fill")
                .font(.system(size: 11))
                .foregroundColor(MetalTheme.steel)

            // Value if set
            if let value = deal.value {
                Label(String(format: "$%.0f", value), systemImage: "dollarsign.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MetalTheme.conquestGradient)
            }

            // Actions
            if !deal.stage.isTerminal {
                HStack(spacing: 6) {
                    if deal.stage.next != nil {
                        Button(action: onAdvance) {
                            Label("Advance", systemImage: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(MetalTheme.toxicGreen)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: onReject) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(MetalTheme.steel.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Label(deal.stage == .contracted ? "Sealed" : "Fallen", systemImage: deal.stage == .contracted ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(deal.stage == .contracted ? MetalTheme.toxicGreen : MetalTheme.steel)
            }
        }
        .padding(12)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(deal.stage == .contracted ? MetalTheme.toxicGreen.opacity(0.4) : MetalTheme.chainLink, lineWidth: 0.5)
        )
    }
}

// MARK: - ContactRow

@available(iOS 16.0, macOS 13.0, *)
private struct ContactRow: View {
    let contact: CRMContact
    let dealCount: Int

    var body: some View {
        HStack(spacing: 12) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(MetalTheme.gunmetal)
                    .frame(width: 44, height: 44)
                Text(contact.name.prefix(2).uppercased())
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(MetalTheme.crimson)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(MetalTheme.chrome)

                if let company = contact.company {
                    Text(company)
                        .font(.system(size: 12))
                        .foregroundColor(MetalTheme.steel)
                }

                if let role = contact.role {
                    Text(role)
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel.opacity(0.7))
                }
            }

            Spacer()

            // Deal count badge
            if dealCount > 0 {
                VStack(spacing: 2) {
                    Text("\(dealCount)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(MetalTheme.ember)
                    Text("deals")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(MetalTheme.steel)
                }
            }

            // Last contacted indicator
            if let lastContacted = contact.metadata.lastContacted {
                VStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(MetalTheme.chainLink)
                    Text(relativeDateString(lastContacted))
                        .font(.system(size: 9))
                        .foregroundColor(MetalTheme.steel.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(MetalTheme.obsidian)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    private func relativeDateString(_ date: Date) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
        if days == 0 { return "today" }
        if days == 1 { return "1d ago" }
        if days < 30 { return "\(days)d ago" }
        return "\(days / 30)mo ago"
    }
}

// MARK: - InteractionRow

@available(iOS 16.0, macOS 13.0, *)
private struct InteractionRow: View {
    let interaction: CRMInteraction
    let contactName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(MetalTheme.gunmetal)
                    .frame(width: 36, height: 36)
                Image(systemName: interaction.type.systemImageName)
                    .font(.system(size: 14))
                    .foregroundColor(MetalTheme.ember)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contactName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(MetalTheme.chrome)
                    Spacer()
                    Text(shortDate(interaction.date))
                        .font(.system(size: 11))
                        .foregroundColor(MetalTheme.steel)
                }

                Text(interaction.summary)
                    .font(.system(size: 12))
                    .foregroundColor(MetalTheme.steel)
                    .lineLimit(2)

                Label(interaction.type.displayName, systemImage: interaction.type.systemImageName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MetalTheme.chainLink)
            }
        }
        .padding(10)
        .background(MetalTheme.obsidian)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MetalTheme.chainLink, lineWidth: 0.5)
        )
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    private func shortDate(_ date: Date) -> String {
        InteractionRow.shortDateFormatter.string(from: date)
    }
}

// MARK: - CRMStatCard

@available(iOS 16.0, macOS 13.0, *)
private struct CRMStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(MetalTheme.steel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .metalCard()
    }
}

// MARK: - CRMEmptyState

@available(iOS 16.0, macOS 13.0, *)
private struct CRMEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MetalTheme.chainLink)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(MetalTheme.steel)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(40)
    }
}

// MARK: - AddContactSheet

@available(iOS 16.0, macOS 13.0, *)
private struct AddContactSheet: View {
    @ObservedObject var viewModel: CRMDashboardViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var role = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MetalTheme.abyss.ignoresSafeArea()
                Form {
                    Section(header: MetalTheme.sectionTitle("Identity")) {
                        metalTextField("Name *", text: $name)
                        metalTextField("Email", text: $email)
                        metalTextField("Phone", text: $phone)
                    }
                    Section(header: MetalTheme.sectionTitle("Company")) {
                        metalTextField("Company / Publisher", text: $company)
                        metalTextField("Role (Agent, Editor…)", text: $role)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add to Roster")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(MetalTheme.steel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        viewModel.addContact(
                            name: name,
                            email: email.isEmpty ? nil : email,
                            phone: phone.isEmpty ? nil : phone,
                            company: company.isEmpty ? nil : company,
                            role: role.isEmpty ? nil : role
                        )
                        isPresented = false
                    }
                    .foregroundColor(name.isEmpty ? MetalTheme.steel : MetalTheme.crimson)
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func metalTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundColor(MetalTheme.chrome)
    }
}

// MARK: - AddDealSheet

@available(iOS 16.0, macOS 13.0, *)
private struct AddDealSheet: View {
    @ObservedObject var viewModel: CRMDashboardViewModel
    @Binding var isPresented: Bool

    @State private var title = ""
    @State private var selectedContactIndex = 0
    @State private var selectedStage = DealStage.prospect
    @State private var valueText = ""

    var contacts: [CRMContact] { viewModel.contacts }

    var body: some View {
        NavigationStack {
            ZStack {
                MetalTheme.abyss.ignoresSafeArea()
                Form {
                    Section(header: MetalTheme.sectionTitle("Deal Info")) {
                        TextField("Deal title / manuscript name", text: $title)
                            .foregroundColor(MetalTheme.chrome)
                        if !contacts.isEmpty {
                            Picker("Contact", selection: $selectedContactIndex) {
                                ForEach(contacts.indices, id: \.self) { i in
                                    Text(contacts[i].name).tag(i)
                                }
                            }
                        }
                    }
                    Section(header: MetalTheme.sectionTitle("Stage")) {
                        Picker("Stage", selection: $selectedStage) {
                            ForEach(DealStage.allCases, id: \.self) { stage in
                                Text(stage.displayName).tag(stage)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Section(header: MetalTheme.sectionTitle("Value (optional)")) {
                        TextField("Contract value ($)", text: $valueText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .foregroundColor(MetalTheme.chrome)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Deal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(MetalTheme.steel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
                              contacts.indices.contains(selectedContactIndex) else { return }
                        let contact = contacts[selectedContactIndex]
                        let value = Double(valueText)
                        viewModel.addDeal(
                            title: title,
                            contactId: contact.id,
                            stage: selectedStage,
                            value: value
                        )
                        isPresented = false
                    }
                    .foregroundColor((title.isEmpty || contacts.isEmpty) ? MetalTheme.steel : MetalTheme.crimson)
                    .fontWeight(.bold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || !contacts.indices.contains(selectedContactIndex))
                }
            }
        }
    }
}

// MARK: - CRMDashboardViewModel

@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class CRMDashboardViewModel: ObservableObject {
    @Published var contacts: [CRMContact] = []
    @Published var recentInteractions: [CRMInteraction] = []
    @Published var stats: CRMStats = CRMStats()

    private let crmManager: CRMManager

    public init(crmManager: CRMManager) {
        self.crmManager = crmManager
    }

    // MARK: - Load

    func reload() {
        contacts = crmManager.getAllContacts()
        recentInteractions = crmManager.getRecentInteractions(limit: 30)
        stats = crmManager.getCRMStats()
    }

    // MARK: - Queries

    func deals(inStage stage: DealStage) -> [CRMDeal] {
        crmManager.getDeals(inStage: stage)
    }

    func dealCount(forContact id: UUID) -> Int {
        crmManager.getDeals(forContact: id).count
    }

    func contactName(for id: UUID) -> String {
        contacts.first { $0.id == id }?.name ?? "Unknown"
    }

    // MARK: - Mutations

    func addContact(name: String, email: String?, phone: String?, company: String?, role: String?) {
        crmManager.createContact(name: name, email: email, phone: phone, company: company, role: role)
        reload()
    }

    func addDeal(title: String, contactId: UUID, stage: DealStage, value: Double?) {
        crmManager.createDeal(title: title, contactId: contactId, stage: stage, value: value)
        reload()
    }

    func advanceDeal(_ deal: CRMDeal) {
        crmManager.advanceDeal(id: deal.id)
        reload()
    }

    func rejectDeal(_ deal: CRMDeal) {
        crmManager.rejectDeal(id: deal.id)
        reload()
    }
}

#endif
