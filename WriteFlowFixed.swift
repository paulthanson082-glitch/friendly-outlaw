import SwiftUI

// MARK: - Models

struct Document: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var template: Template?
    var dateCreated: Date
    var dateModified: Date
    var wordCount: Int {
        content.split(separator: " ").count
    }

    // Hashable conformance
    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum Template: String, Codable, CaseIterable {
    case blank = "Blank Document"
    case essay = "Essay"
    case blogPost = "Blog Post"
    case resume = "Resume"
    case coverLetter = "Cover Letter"
    case businessLetter = "Business Letter"
    case screenplay = "Screenplay"
    case poem = "Poem"

    var icon: String {
        switch self {
        case .blank: return "doc"
        case .essay: return "doc.text"
        case .blogPost: return "newspaper"
        case .resume: return "person.text.rectangle"
        case .coverLetter: return "envelope"
        case .businessLetter: return "doc.richtext"
        case .screenplay: return "film"
        case .poem: return "quote.bubble"
        }
    }

    var defaultContent: String {
        switch self {
        case .blank:
            return ""
        case .essay:
            return """
            Essay Title

            Introduction
            Begin with a hook to capture reader attention...

            Body Paragraph 1
            Main point with supporting evidence...

            Body Paragraph 2
            Second main point...

            Body Paragraph 3
            Third main point...

            Conclusion
            Summarize key points and leave lasting impression...
            """
        case .blogPost:
            return """
            Blog Post Title

            Introduction
            Hook your readers with an engaging opening...

            Main Content
            Share your insights, tips, or story...

            Key Takeaways
            • Point 1
            • Point 2
            • Point 3

            Conclusion
            Call to action or closing thoughts...
            """
        case .resume:
            return """
            [Your Name]
            [Email] | [Phone] | [LinkedIn]

            PROFESSIONAL SUMMARY
            Brief overview of your skills and experience...

            EXPERIENCE
            Job Title - Company Name (Date - Date)
            • Achievement or responsibility
            • Achievement or responsibility

            EDUCATION
            Degree - Institution (Year)

            SKILLS
            • Skill 1
            • Skill 2
            • Skill 3
            """
        case .coverLetter:
            return """
            [Your Name]
            [Your Address]
            [Email] | [Phone]

            [Date]

            [Hiring Manager's Name]
            [Company Name]
            [Company Address]

            Dear [Hiring Manager],

            Opening paragraph introducing yourself...

            Middle paragraph highlighting qualifications...

            Closing paragraph expressing interest...

            Sincerely,
            [Your Name]
            """
        case .businessLetter:
            return """
            [Your Company]
            [Address]
            [Phone] | [Email]

            [Date]

            [Recipient Name]
            [Company]
            [Address]

            Dear [Recipient],

            Opening paragraph stating purpose...

            Body paragraph with details...

            Closing paragraph with action items...

            Best regards,
            [Your Name]
            [Title]
            """
        case .screenplay:
            return """
            FADE IN:

            INT. LOCATION - DAY

            Description of the scene setting...

            CHARACTER NAME
            (direction)
            Dialogue goes here.

            CHARACTER NAME 2
            Response dialogue.

            ACTION LINE
            Description of what happens next.

            FADE OUT.
            """
        case .poem:
            return """
            [Poem Title]

            First stanza begins here,
            With rhythm and with rhyme,
            Let words flow naturally,
            One line at a time.

            Second stanza follows through,
            Express what's in your heart,
            Poetry is freedom,
            A creative art.
            """
        }
    }
}

// MARK: - View Model

class DocumentStore: ObservableObject {
    @Published var documents: [Document] = []
    @Published var selectedDocument: Document?

    init() {
        loadSampleDocuments()
    }

    func loadSampleDocuments() {
        let sample = Document(
            id: UUID(),
            title: "Welcome Document",
            content: "Welcome to WriteFlow! Start writing or choose a template to begin.",
            template: .blank,
            dateCreated: Date(),
            dateModified: Date()
        )
        documents.append(sample)
        selectedDocument = sample
    }

    func createDocument(template: Template) {
        let newDoc = Document(
            id: UUID(),
            title: template == .blank ? "Untitled Document" : template.rawValue,
            content: template.defaultContent,
            template: template,
            dateCreated: Date(),
            dateModified: Date()
        )
        documents.insert(newDoc, at: 0)
        selectedDocument = newDoc
    }

    func updateDocument(_ document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDoc = document
            updatedDoc.dateModified = Date()
            documents[index] = updatedDoc
            selectedDocument = updatedDoc
        }
    }

    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
        if selectedDocument?.id == document.id {
            selectedDocument = documents.first
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var store = DocumentStore()
    @State private var showingTemplates = false
    @State private var showingWordCount = false
    @State private var searchText = ""

    var filteredDocuments: [Document] {
        if searchText.isEmpty {
            return store.documents
        }
        return store.documents.filter { doc in
            doc.title.localizedCaseInsensitiveContains(searchText) ||
            doc.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $store.selectedDocument) {
                ForEach(filteredDocuments) { document in
                    DocumentRow(document: document)
                        .tag(document)
                }
                .onDelete(perform: deleteDocuments)
            }
            .searchable(text: $searchText, prompt: "Search documents")
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("New Document", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatePickerView(store: store, isPresented: $showingTemplates)
            }
        } detail: {
            if let document = store.selectedDocument {
                EditorView(document: document, store: store)
                    .id(document.id)  // Force view recreation when document changes
            } else {
                EmptyStateView(showingTemplates: $showingTemplates)
            }
        }
    }

    func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            store.deleteDocument(filteredDocuments[index])
        }
    }
}

// MARK: - Document Row

struct DocumentRow: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let template = document.template {
                    Image(systemName: template.icon)
                        .foregroundColor(.blue)
                }
                Text(document.title)
                    .font(.headline)
            }

            Text(document.content.prefix(50) + (document.content.count > 50 ? "..." : ""))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text("\(document.wordCount) words")
                Spacer()
                Text(document.dateModified, style: .relative)
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Template Picker

struct TemplatePickerView: View {
    @ObservedObject var store: DocumentStore
    @Binding var isPresented: Bool

    let columns = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Template.allCases, id: \.self) { template in
                        TemplateCard(template: template) {
                            store.createDocument(template: template)
                            isPresented = false
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: Template
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text(template.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Editor View

struct EditorView: View {
    let document: Document
    @ObservedObject var store: DocumentStore

    @State private var editableTitle: String
    @State private var editableContent: String
    @State private var showingTools = false
    @State private var selectedTool: WritingTool?

    init(document: Document, store: DocumentStore) {
        self.document = document
        self.store = store
        _editableTitle = State(initialValue: document.title)
        _editableContent = State(initialValue: document.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                TextField("Document Title", text: $editableTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                    .onChange(of: editableTitle) { _ in saveDocument() }

                Spacer()

                Menu {
                    Button {
                        selectedTool = .wordCount
                    } label: {
                        Label("Word Count", systemImage: "number")
                    }

                    Button {
                        selectedTool = .findReplace
                    } label: {
                        Label("Find & Replace", systemImage: "magnifyingglass")
                    }

                    Button {
                        selectedTool = .formatting
                    } label: {
                        Label("Formatting", systemImage: "textformat")
                    }
                } label: {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }
            }
            .padding()

            Divider()

            // Editor
            TextEditor(text: $editableContent)
                .font(.body)
                .padding()
                .onChange(of: editableContent) { _ in saveDocument() }

            // Status Bar
            HStack {
                if let template = document.template {
                    Label(template.rawValue, systemImage: template.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(editableContent.split(separator: " ").count) words")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text("\(editableContent.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .sheet(item: $selectedTool) { tool in
            WritingToolView(tool: tool, content: $editableContent)
        }
    }

    func saveDocument() {
        var updatedDoc = document
        updatedDoc.title = editableTitle
        updatedDoc.content = editableContent
        store.updateDocument(updatedDoc)
    }
}

// MARK: - Writing Tools

enum WritingTool: Identifiable {
    case wordCount
    case findReplace
    case formatting

    var id: String {
        switch self {
        case .wordCount: return "wordCount"
        case .findReplace: return "findReplace"
        case .formatting: return "formatting"
        }
    }

    var title: String {
        switch self {
        case .wordCount: return "Word Count"
        case .findReplace: return "Find & Replace"
        case .formatting: return "Formatting Tools"
        }
    }
}

struct WritingToolView: View {
    let tool: WritingTool
    @Binding var content: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch tool {
                case .wordCount:
                    WordCountView(content: content)
                case .findReplace:
                    FindReplaceView(content: $content)
                case .formatting:
                    FormattingView(content: $content)
                }
            }
            .navigationTitle(tool.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WordCountView: View {
    let content: String

    var words: Int {
        content.split(separator: " ").count
    }

    var characters: Int {
        content.count
    }

    var charactersNoSpaces: Int {
        content.filter { !$0.isWhitespace }.count
    }

    var sentences: Int {
        content.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.isEmpty }.count
    }

    var paragraphs: Int {
        content.components(separatedBy: "\n\n").filter { !$0.isEmpty }.count
    }

    var readingTime: Int {
        max(1, words / 200)  // Prevent division issues and ensure minimum 1 minute
    }

    var body: some View {
        List {
            StatRow(label: "Words", value: "\(words)")
            StatRow(label: "Characters", value: "\(characters)")
            StatRow(label: "Characters (no spaces)", value: "\(charactersNoSpaces)")
            StatRow(label: "Sentences", value: "\(sentences)")
            StatRow(label: "Paragraphs", value: "\(paragraphs)")

            Section("Reading Time") {
                StatRow(label: "Estimated reading time", value: "\(readingTime) min")
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct FindReplaceView: View {
    @Binding var content: String
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var caseSensitive = false

    var body: some View {
        Form {
            Section {
                TextField("Find", text: $findText)
                TextField("Replace with", text: $replaceText)
                Toggle("Case Sensitive", isOn: $caseSensitive)
            }

            Section {
                Button("Replace All") {
                    if caseSensitive {
                        content = content.replacingOccurrences(of: findText, with: replaceText)
                    } else {
                        content = content.replacingOccurrences(
                            of: findText,
                            with: replaceText,
                            options: .caseInsensitive
                        )
                    }
                }
                .disabled(findText.isEmpty)
            }
        }
    }
}

struct FormattingView: View {
    @Binding var content: String

    var body: some View {
        List {
            Section("Text Transform") {
                Button("UPPERCASE") {
                    content = content.uppercased()
                }
                Button("lowercase") {
                    content = content.lowercased()
                }
                Button("Title Case") {
                    content = content.capitalized
                }
            }

            Section("Spacing") {
                Button("Remove Extra Spaces") {
                    content = content.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                }
                Button("Single Line Breaks") {
                    content = content.replacingOccurrences(
                        of: "\n\n+",
                        with: "\n",
                        options: .regularExpression
                    )
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    @Binding var showingTemplates: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Document Selected")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose a document from the sidebar or create a new one")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingTemplates = true
            } label: {
                Label("New Document", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
