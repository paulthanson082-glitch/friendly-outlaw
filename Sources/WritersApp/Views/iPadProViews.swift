#if canImport(SwiftUI) && os(iOS)
import SwiftUI

// MARK: - Main iPad Pro App View

/// Main view for the iPad Pro writers app with adaptive layout
@available(iOS 16.0, macOS 13.0, *)
public struct WritersAppView: View {
    @StateObject private var viewModel = WritersAppViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            AdaptiveLayoutView(
                viewModel: viewModel,
                availableSize: geometry.size
            )
        }
        .onAppear {
            viewModel.initialize()
        }
    }
}

// MARK: - Adaptive Layout View

/// Adapts layout based on available screen size and multitasking mode
@available(iOS 16.0, macOS 13.0, *)
struct AdaptiveLayoutView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    let availableSize: CGSize

    var body: some View {
        let layout = viewModel.multitaskingManager.getRecommendedLayout()

        NavigationSplitView(columnVisibility: .constant(
            layout.showSidebar ? .all : .detailOnly
        )) {
            // Sidebar
            if layout.showSidebar {
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: layout.sidebarWidth)
            }
        } detail: {
            // Main content area
            HStack(spacing: 0) {
                // Document Editor
                DocumentEditorView(viewModel: viewModel)
                    .frame(maxWidth: layout.editorMaxWidth)

                // AI Panel
                if layout.showAIPanel && viewModel.showAIPanel {
                    Divider()
                    AISidebarView(viewModel: viewModel)
                        .frame(width: layout.aiPanelWidth)
                }
            }
        }
        .onChange(of: availableSize) { _, newSize in
            viewModel.updateMultitaskingState(size: newSize)
        }
    }
}

// MARK: - Sidebar View

/// Navigation sidebar for documents and templates
@available(iOS 16.0, macOS 13.0, *)
struct SidebarView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    @State private var selectedSection: SidebarSection = .documents

    var body: some View {
        List(selection: $selectedSection) {
            Section("Library") {
                Label("Documents", systemImage: "doc.text")
                    .tag(SidebarSection.documents)

                Label("Templates", systemImage: "rectangle.stack")
                    .tag(SidebarSection.templates)

                Label("Recent", systemImage: "clock")
                    .tag(SidebarSection.recent)
            }

            Section("Categories") {
                ForEach(TemplateCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.iconName)
                        .tag(SidebarSection.category(category))
                }
            }

            Section("Tools") {
                Label("Statistics", systemImage: "chart.bar")
                    .tag(SidebarSection.statistics)

                Label("Settings", systemImage: "gear")
                    .tag(SidebarSection.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Writers App")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.createNewDocument() }) {
                    Label("New Document", systemImage: "plus")
                }
            }
        }
    }
}

enum SidebarSection: Hashable {
    case documents
    case templates
    case recent
    case category(TemplateCategory)
    case statistics
    case settings
}

// MARK: - Document Editor View

/// Main document editing view optimized for iPad Pro
@available(iOS 16.0, macOS 13.0, *)
struct DocumentEditorView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            EditorToolbarView(
                viewModel: viewModel
            )

            Divider()

            // Editor content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Title field
                    TextField("Document Title", text: $viewModel.currentDocumentTitle)
                        .font(.system(size: 28, weight: .bold))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, viewModel.editorPadding.leading)
                        .padding(.top, viewModel.editorPadding.top)

                    Divider()
                        .padding(.vertical, 12)
                        .padding(.horizontal, viewModel.editorPadding.leading)

                    // Content editor
                    TextEditor(text: $viewModel.currentDocumentContent)
                        .font(.system(size: viewModel.bodyFontSize))
                        .lineSpacing(viewModel.lineSpacing)
                        .padding(.horizontal, viewModel.editorPadding.leading)
                        .padding(.bottom, viewModel.editorPadding.bottom)
                        .focused($isEditorFocused)
                        .frame(minHeight: 400)
                }
            }

            // Status bar
            EditorStatusBarView(viewModel: viewModel)
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $viewModel.showWordCountSheet) {
            WordCountDetailView(viewModel: viewModel)
        }
    }
}

// MARK: - Word Count Detail View

/// Sheet displaying detailed word count statistics for the current document
@available(iOS 16.0, macOS 13.0, *)
struct WordCountDetailView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    @Environment(\.dismiss) private var dismiss

    private var sentenceCount: Int {
        let content = viewModel.currentDocumentContent
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var paragraphCount: Int {
        let content = viewModel.currentDocumentContent
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Writing Stats") {
                    StatRow(label: "Words", value: "\(viewModel.wordCount)")
                    StatRow(label: "Characters", value: "\(viewModel.characterCount)")
                    StatRow(label: "Sentences", value: "\(sentenceCount)")
                    StatRow(label: "Paragraphs", value: "\(paragraphCount)")
                    StatRow(label: "Reading Time", value: "\(viewModel.readingTime) min")
                }

                if let goal = viewModel.wordCountGoal {
                    Section("Word Count Goal") {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: Double(min(viewModel.wordCount, goal)), total: Double(goal))
                            HStack {
                                Text("\(viewModel.wordCount) of \(goal) words")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                let remaining = max(0, goal - viewModel.wordCount)
                                Text(remaining == 0 ? "Goal reached!" : "\(remaining) remaining")
                                    .font(.caption)
                                    .foregroundColor(remaining == 0 ? .green : .secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Word Count")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Editor Toolbar View

/// Toolbar for the document editor
@available(iOS 16.0, macOS 13.0, *)
struct EditorToolbarView: View {
    @ObservedObject var viewModel: WritersAppViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Formatting buttons
            Group {
                Button(action: { viewModel.toggleBold() }) {
                    Image(systemName: "bold")
                }
                .keyboardShortcut("b", modifiers: .command)

                Button(action: { viewModel.toggleItalic() }) {
                    Image(systemName: "italic")
                }
                .keyboardShortcut("i", modifiers: .command)

                Button(action: { viewModel.toggleUnderline() }) {
                    Image(systemName: "underline")
                }
                .keyboardShortcut("u", modifiers: .command)
            }

            Divider()
                .frame(height: 20)

            // Heading buttons
            Menu {
                Button("Heading 1") { viewModel.applyHeading(level: 1) }
                Button("Heading 2") { viewModel.applyHeading(level: 2) }
                Button("Heading 3") { viewModel.applyHeading(level: 3) }
                Button("Body") { viewModel.applyBodyStyle() }
            } label: {
                Label("Style", systemImage: "textformat")
            }

            // List buttons
            Menu {
                Button(action: { viewModel.toggleBulletList() }) {
                    Label("Bullet List", systemImage: "list.bullet")
                }
                Button(action: { viewModel.toggleNumberedList() }) {
                    Label("Numbered List", systemImage: "list.number")
                }
            } label: {
                Label("List", systemImage: "list.bullet")
            }

            Spacer()

            // AI button
            Button(action: { viewModel.toggleAIPanel() }) {
                Label("AI Assistant", systemImage: "sparkles")
            }
            .keyboardShortcut("a", modifiers: [.command, .option])

            // Focus mode button
            Button(action: { viewModel.toggleFocusMode() }) {
                Image(systemName: viewModel.isFocusMode ? "eye.slash" : "eye")
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            // More options
            Menu {
                Button(action: { viewModel.exportDocument() }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button(action: { viewModel.showDocumentInfo() }) {
                    Label("Document Info", systemImage: "info.circle")
                }
                Button(action: { viewModel.showWordCount() }) {
                    Label("Word Count", systemImage: "number")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

// MARK: - Editor Status Bar View

/// Status bar showing document statistics
@available(iOS 16.0, macOS 13.0, *)
struct EditorStatusBarView: View {
    @ObservedObject var viewModel: WritersAppViewModel

    var body: some View {
        HStack(spacing: 24) {
            // Word count
            HStack(spacing: 4) {
                Image(systemName: "textformat.123")
                    .foregroundColor(.secondary)
                Text("\(viewModel.wordCount) words")
            }

            // Character count
            HStack(spacing: 4) {
                Image(systemName: "character")
                    .foregroundColor(.secondary)
                Text("\(viewModel.characterCount) characters")
            }

            // Reading time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("\(viewModel.readingTime) min read")
            }

            Spacer()

            // Word count goal progress
            if let goal = viewModel.wordCountGoal {
                HStack(spacing: 8) {
                    ProgressView(value: Double(viewModel.wordCount), total: Double(goal))
                        .frame(width: 100)

                    Text("\(viewModel.wordCount)/\(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Save status
            HStack(spacing: 4) {
                if viewModel.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
                Text(viewModel.isSaving ? "Saving..." : "Saved")
                    .font(.caption)
            }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemBackground))
    }
}

// MARK: - AI Sidebar View

/// Side panel for AI writing assistance
@available(iOS 16.0, macOS 13.0, *)
struct AISidebarView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    @State private var aiPrompt = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("AI Assistant", systemImage: "sparkles")
                    .font(.headline)

                Spacer()

                Button(action: { viewModel.toggleAIPanel() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))

            Divider()

            // Quick actions
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick action buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Actions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            AIQuickActionButton(
                                title: "Continue",
                                icon: "arrow.right.circle",
                                action: { viewModel.aiContinueWriting() }
                            )
                            AIQuickActionButton(
                                title: "Improve",
                                icon: "wand.and.stars",
                                action: { viewModel.aiImproveText() }
                            )
                            AIQuickActionButton(
                                title: "Expand",
                                icon: "arrow.up.left.and.arrow.down.right",
                                action: { viewModel.aiExpandText() }
                            )
                            AIQuickActionButton(
                                title: "Simplify",
                                icon: "text.badge.minus",
                                action: { viewModel.aiSimplifyText() }
                            )
                            AIQuickActionButton(
                                title: "Grammar",
                                icon: "checkmark.circle",
                                action: { viewModel.aiCheckGrammar() }
                            )
                            AIQuickActionButton(
                                title: "Summarize",
                                icon: "text.badge.checkmark",
                                action: { viewModel.aiSummarize() }
                            )
                        }
                    }

                    Divider()

                    // Writing tools
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Writing Tools")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        AIToolButton(
                            title: "Brainstorm Ideas",
                            icon: "lightbulb",
                            description: "Generate creative ideas for your topic",
                            action: { viewModel.aiBrainstorm() }
                        )

                        AIToolButton(
                            title: "Generate Outline",
                            icon: "list.bullet.indent",
                            description: "Create a structured outline",
                            action: { viewModel.aiGenerateOutline() }
                        )

                        AIToolButton(
                            title: "Character Development",
                            icon: "person.2",
                            description: "Develop rich, complex characters",
                            action: { viewModel.aiDevelopCharacter() }
                        )

                        AIToolButton(
                            title: "Improve Dialogue",
                            icon: "bubble.left.and.bubble.right",
                            description: "Make dialogue more natural",
                            action: { viewModel.aiImproveDialogue() }
                        )

                        AIToolButton(
                            title: "Generate Titles",
                            icon: "textformat",
                            description: "Suggest compelling titles",
                            action: { viewModel.aiGenerateTitles() }
                        )
                    }

                    Divider()

                    // Custom prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Request")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        TextField("Ask AI anything about your writing...", text: $aiPrompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)

                        Button(action: {
                            viewModel.aiCustomRequest(prompt: aiPrompt)
                            aiPrompt = ""
                        }) {
                            Label("Send", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(aiPrompt.isEmpty)
                    }

                    // AI Response area
                    if !viewModel.aiResponse.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("AI Response")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: { viewModel.insertAIResponse() }) {
                                    Label("Insert", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }

                            Text(viewModel.aiResponse)
                                .font(.body)
                                .padding(12)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Recent AI Suggestions
                    if !viewModel.recentAISuggestions.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recent Suggestions")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: { viewModel.loadMoreSuggestions() }) {
                                    Text("View All")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            ForEach(viewModel.recentAISuggestions.prefix(5), id: \.id) { suggestion in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(suggestion.toolUsed)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text(formatSuggestionDate(suggestion.timestamp))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(suggestion.response)
                                        .font(.caption)
                                        .lineLimit(3)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .cornerRadius(6)
                            }
                        }
                    }
                    
                    // AI Tool Usage Stats
                    if !viewModel.toolUsageStats.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tool Usage Statistics")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(viewModel.toolUsageStats.prefix(5), id: \.toolName) { stat in
                                HStack {
                                    Text(stat.toolName)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("\(stat.usageCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    private func formatSuggestionDate(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - AI Quick Action Button

@available(iOS 16.0, macOS 13.0, *)
struct AIQuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Tool Button

@available(iOS 16.0, macOS 13.0, *)
struct AIToolButton: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Focus Mode View

/// Distraction-free writing view for iPad Pro
@available(iOS 16.0, macOS 13.0, *)
struct FocusModeView: View {
    @ObservedObject var viewModel: WritersAppViewModel
    @FocusState private var isEditorFocused: Bool
    @State private var showControls = false

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            // Editor
            ScrollView {
                VStack(alignment: .center) {
                    TextEditor(text: $viewModel.currentDocumentContent)
                        .font(.system(size: 20, design: .serif))
                        .lineSpacing(10)
                        .frame(maxWidth: 680)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 60)
                        .focused($isEditorFocused)
                }
            }

            // Floating word count
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Text("\(viewModel.wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding()
                        .opacity(showControls ? 1 : 0.3)
                }
            }

            // Exit button
            VStack {
                HStack {
                    Spacer()

                    Button(action: { viewModel.toggleFocusMode() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .opacity(showControls ? 1 : 0)
                }

                Spacer()
            }
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
        }
        .onAppear {
            isEditorFocused = true
        }
    }
}

// MARK: - View Model

/// View model for the iPad Pro writers app
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class WritersAppViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var currentDocumentTitle: String = "Untitled"
    @Published public var currentDocumentContent: String = ""
    @Published public var showAIPanel: Bool = true
    @Published public var isFocusMode: Bool = false
    @Published public var isSaving: Bool = false
    @Published public var aiResponse: String = ""
    @Published public var showWordCountSheet: Bool = false
    @Published public var showDocumentInfoSheet: Bool = false

    // Statistics
    @Published public var wordCount: Int = 0
    @Published public var characterCount: Int = 0
    @Published public var readingTime: Int = 1
    @Published public var wordCountGoal: Int? = nil
    
    // AI Suggestions and Stats
    @Published public var recentAISuggestions: [AISuggestion] = []
    @Published public var toolUsageStats: [AIToolUsageStats] = []
    @Published public var currentSessionStats: SessionStats?

    // Layout
    @Published public var bodyFontSize: Double = 17
    @Published public var lineSpacing: Double = 8
    @Published public var editorPadding = EdgeInsets(top: 20, leading: 40, bottom: 20, trailing: 40)

    // MARK: - Managers

    public let multitaskingManager = MultitaskingManager()
    public let keyboardShortcutManager = KeyboardShortcutManager()
    public let applePencilManager = ApplePencilManager()

    // MARK: - Private Properties

    private var currentDocument: Document?
    private var writersApp: WritersApp?

    // MARK: - Initialization

    public init() {}

    public func initialize() {
        writersApp = WritersApp()
        updateStatistics()
        
        // Initialize a demo user session for testing database features
        // NOTE: In production, this should use a stable user identifier
        // from authentication/user management system
        let demoUserId = UUID()
        writersApp?.startSession(userId: demoUserId, multitaskingMode: "Split View")
        
        // Load initial data
        loadRecentSuggestions()
        loadToolUsageStats()
    }

    // MARK: - Document Operations

    public func createNewDocument() {
        currentDocument = writersApp?.createBlankDocument(title: "Untitled", category: .other)
        currentDocumentTitle = currentDocument?.title ?? "Untitled"
        currentDocumentContent = currentDocument?.content ?? ""
        updateStatistics()
    }

    public func saveDocument() {
        guard var doc = currentDocument else { return }
        doc.title = currentDocumentTitle
        doc.content = currentDocumentContent
        doc.metadata.modified = Date()
        currentDocument = doc

        isSaving = true

        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isSaving = false
        }
    }

    public func exportDocument() {
        guard let doc = currentDocument else { return }

        let exportedContent = writersApp?.exportDocument(id: doc.id, format: .markdown)

        if let content = exportedContent {
            UIPasteboard.general.string = content
            print("Document exported as Markdown and copied to clipboard")
        } else {
            print("Failed to export document")
        }
    }

    /// Presents the document information interface, showing the current document's metadata and available actions such as export and metadata editing.
    public func showDocumentInfo() {
        showDocumentInfoSheet = true
    }

    /// Shows the word count detail sheet.
    /// Sets the view model's sheet visibility flag so the WordCountDetailView is presented.
    public func showWordCount() {
        showWordCountSheet = true
    }

    // MARK: - Formatting

    public func toggleBold() {
        let trimmed = currentDocumentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && trimmed.count > 4 {
            // Remove bold formatting
            let withoutMarkers = String(trimmed.dropFirst(2).dropLast(2))
            currentDocumentContent = withoutMarkers
        } else {
            // Add bold formatting
            currentDocumentContent = "**\(currentDocumentContent)**"
        }
        updateStatistics()
    }

    public func toggleItalic() {
        let trimmed = currentDocumentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("*") && trimmed.hasSuffix("*") && !trimmed.hasPrefix("**") && trimmed.count > 2 {
            // Remove italic formatting
            let withoutMarkers = String(trimmed.dropFirst().dropLast())
            currentDocumentContent = withoutMarkers
        } else {
            // Add italic formatting
            currentDocumentContent = "*\(currentDocumentContent)*"
        }
        updateStatistics()
    }

    public func toggleUnderline() {
        let trimmed = currentDocumentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<u>") && trimmed.hasSuffix("</u>") && trimmed.count > 7 {
            // Remove underline formatting
            let withoutMarkers = String(trimmed.dropFirst(3).dropLast(4))
            currentDocumentContent = withoutMarkers
        } else {
            // Add underline formatting using HTML (native Markdown has no underline)
            currentDocumentContent = "<u>\(currentDocumentContent)</u>"
        }
        updateStatistics()
    }

    public func applyHeading(level: Int) {
        let trimmed = currentDocumentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let headingPrefix = String(repeating: "#", count: level)

        // Check if already a heading and remove existing heading level
        if trimmed.hasPrefix("#") {
            let components = trimmed.split(separator: " ", maxSplits: 1)
            let content = components.count > 1 ? String(components[1]) : trimmed
            currentDocumentContent = "\(headingPrefix) \(content)"
        } else {
            currentDocumentContent = "\(headingPrefix) \(currentDocumentContent)"
        }
        updateStatistics()
    }

    public func applyBodyStyle() {
        // Reset to plain text (remove markdown formatting markers)
        var plainText = currentDocumentContent

        // Remove heading markers at line start
        if let regex = try? NSRegularExpression(pattern: "^#+\\s+", options: []) {
            let range = NSRange(plainText.startIndex..<plainText.endIndex, in: plainText)
            plainText = regex.stringByReplacingMatches(in: plainText, options: [], range: range, withTemplate: "")
        }

        // Remove bold formatting (**text**)
        if plainText.hasPrefix("**") && plainText.hasSuffix("**") && plainText.count > 4 {
            plainText = String(plainText.dropFirst(2).dropLast(2))
        }

        // Remove italic formatting (*text*)
        if plainText.hasPrefix("*") && plainText.hasSuffix("*") && plainText.count > 2 && !plainText.hasPrefix("**") {
            plainText = String(plainText.dropFirst().dropLast())
        }

        // Remove underline formatting (<u>text</u>)
        if plainText.hasPrefix("<u>") && plainText.hasSuffix("</u>") && plainText.count > 7 {
            plainText = String(plainText.dropFirst(3).dropLast(4))
        }

        currentDocumentContent = plainText
        updateStatistics()
    }

    public func toggleBulletList() {
        let lines = currentDocumentContent.split(separator: "\n", omittingEmptySubsequences: false)
        let formattedLines = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") {
                return String(line.dropFirst(2))
            } else if !trimmed.isEmpty {
                return "- \(line)"
            }
            return String(line)
        }
        currentDocumentContent = formattedLines.joined(separator: "\n")
        updateStatistics()
    }

    public func toggleNumberedList() {
        let lines = currentDocumentContent.split(separator: "\n", omittingEmptySubsequences: false)
        var itemNumber = 1
        let formattedLines = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Check if line starts with any number followed by ". "
            if trimmed.first?.isNumber == true {
                // Try to extract and remove existing number
                let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                if parts.count >= 2 && parts[0].allSatisfy({ $0.isNumber }) && parts[1].hasPrefix(" ") {
                    // Remove existing number
                    let content = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    let result = "\(itemNumber). \(content)"
                    itemNumber += 1
                    return result
                }
            }
            if !trimmed.isEmpty {
                let result = "\(itemNumber). \(trimmed)"
                itemNumber += 1
                return result
            }
            return String(line)
        }
        currentDocumentContent = formattedLines.joined(separator: "\n")
        updateStatistics()
    }

    // MARK: - View Controls

    public func toggleAIPanel() {
        withAnimation {
            showAIPanel.toggle()
        }
    }

    public func toggleFocusMode() {
        withAnimation {
            isFocusMode.toggle()
        }
    }

    // MARK: - AI Operations

    public func aiContinueWriting() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.continueDocument(
                    documentId: doc.id,
                    context: currentDocumentContent,
                    appendToDocument: false
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiImproveText() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.improveDocument(
                    documentId: doc.id,
                    context: currentDocumentContent,
                    replaceContent: false
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiExpandText() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.generateDocumentTitles(
                    documentId: doc.id,
                    context: currentDocumentContent
                ) ?? []
                await MainActor.run {
                    aiResponse = response.joined(separator: "\n")
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiSimplifyText() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.getAssistance(
                    documentId: doc.id,
                    type: .custom("Simplify the following text to be easier to understand:\n\(currentDocumentContent)"),
                    context: currentDocumentContent
                ) ?? AIResponse(text: "")
                await MainActor.run {
                    aiResponse = response.text
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiCheckGrammar() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.aiService?.checkGrammar(text: currentDocumentContent) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiSummarize() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.aiService?.summarize(text: currentDocumentContent) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiBrainstorm() {
        Task {
            do {
                let response = try await writersApp?.brainstormIdeas(
                    topic: currentDocumentTitle,
                    context: currentDocumentContent
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiGenerateOutline() {
        Task {
            do {
                let response = try await writersApp?.generateOutline(
                    concept: currentDocumentTitle,
                    context: currentDocumentContent
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiDevelopCharacter() {
        Task {
            do {
                let response = try await writersApp?.developCharacter(
                    characterConcept: currentDocumentTitle,
                    context: currentDocumentContent
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiImproveDialogue() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.aiService?.improveDialogue(
                    text: currentDocumentContent,
                    context: currentDocumentTitle
                ) ?? ""
                await MainActor.run {
                    aiResponse = response
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiGenerateTitles() {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.generateDocumentTitles(
                    documentId: doc.id,
                    context: currentDocumentContent
                ) ?? []
                await MainActor.run {
                    aiResponse = response.joined(separator: "\n")
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func aiCustomRequest(prompt: String) {
        guard let doc = currentDocument else { return }
        Task {
            do {
                let response = try await writersApp?.getAssistance(
                    documentId: doc.id,
                    type: .custom(prompt),
                    context: currentDocumentContent
                ) ?? AIResponse(text: "")
                await MainActor.run {
                    aiResponse = response.text
                }
            } catch {
                await MainActor.run {
                    aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    public func insertAIResponse() {
        currentDocumentContent += "\n\n" + aiResponse
        aiResponse = ""
        updateStatistics()
    }
    
    // MARK: - Database Operations
    
    public func loadRecentSuggestions() {
        if let userId = writersApp?.currentUserId {
            do {
                recentAISuggestions = try writersApp?.getAISuggestions(userId: userId, limit: 10, offset: 0) ?? []
            } catch {
                print("Failed to load AI suggestions: \(error)")
            }
        }
    }
    
    public func loadToolUsageStats() {
        if let userId = writersApp?.currentUserId {
            do {
                toolUsageStats = try writersApp?.getAIToolUsageStats(userId: userId) ?? []
            } catch {
                print("Failed to load tool usage stats: \(error)")
            }
        }
    }
    
    public func loadSessionStats() {
        if let userId = writersApp?.currentUserId {
            do {
                currentSessionStats = try writersApp?.getSessionStats(userId: userId)
            } catch {
                print("Failed to load session stats: \(error)")
            }
        }
    }
    
    public func loadMoreSuggestions() {
        // Navigate to a full view of all suggestions
        // This would typically present a sheet or navigate to a new screen
    }

    // MARK: - Multitasking

    public func updateMultitaskingState(size: CGSize) {
        multitaskingManager.updateState(
            availableWidth: size.width,
            availableHeight: size.height
        )

        let layout = multitaskingManager.getRecommendedLayout()
        let fonts = multitaskingManager.getRecommendedFontSizes()

        bodyFontSize = fonts.body
        lineSpacing = (fonts.lineHeight - 1) * bodyFontSize

        if !layout.showAIPanel {
            showAIPanel = false
        }
    }

    // MARK: - Statistics

    private func updateStatistics() {
        let words = currentDocumentContent.components(separatedBy: .whitespacesAndNewlines)
        wordCount = words.filter { !$0.isEmpty }.count
        characterCount = currentDocumentContent.count
        readingTime = max(1, wordCount / 200)
    }
}

// MARK: - Template Category Extension

extension TemplateCategory {
    var iconName: String {
        switch self {
        case .novel: return "book.closed"
        case .shortStory: return "text.book.closed"
        case .screenplay: return "film"
        case .blogPost: return "globe"
        case .article: return "newspaper"
        case .essay: return "doc.text"
        case .poetry: return "quote.bubble"
        case .businessLetter: return "envelope"
        case .proposal: return "doc.badge.plus"
        case .resume: return "person.text.rectangle"
        case .other: return "folder"
        }
    }

    var displayName: String {
        switch self {
        case .novel: return "Novel"
        case .shortStory: return "Short Story"
        case .screenplay: return "Screenplay"
        case .blogPost: return "Blog Post"
        case .article: return "Article"
        case .essay: return "Essay"
        case .poetry: return "Poetry"
        case .businessLetter: return "Business Letter"
        case .proposal: return "Proposal"
        case .resume: return "Resume"
        case .other: return "Other"
        }
    }
}

#endif
