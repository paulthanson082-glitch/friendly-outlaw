import SwiftUI
import WritersApp

// MARK: - DocumentEditorView

struct DocumentEditorView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let document: Document

    @State private var title: String
    @State private var content: String
    @State private var showAISheet = false
    @State private var aiResult = ""
    @State private var isLoadingAI = false
    @State private var aiError: String?

    init(document: Document) {
        self.document = document
        _title = State(initialValue: document.title)
        _content = State(initialValue: document.content)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TextField("Title", text: $title)
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top, 12)

            Divider()
                .padding(.top, 8)

            TextEditor(text: $content)
                .padding(.horizontal, 12)
                .padding(.top, 4)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(title.isEmpty ? "Untitled" : title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { save() }
            }
            if viewModel.isAIEnabled {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showAISheet = true
                    } label: {
                        Label("AI Assist", systemImage: "sparkles")
                    }
                }
            }
        }
        .onDisappear { save() }
        .sheet(isPresented: $showAISheet) {
            AIAssistSheet(document: currentDocument, isLoading: $isLoadingAI, result: $aiResult, error: $aiError)
                .environmentObject(viewModel)
        }
        .overlay {
            if isLoadingAI {
                ProgressView("Thinking…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private var currentDocument: Document {
        var updated = document
        updated.title = title
        updated.content = content
        return updated
    }

    private func save() {
        viewModel.updateDocument(currentDocument)
    }
}

// MARK: - AIAssistSheet

struct AIAssistSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let document: Document
    @Binding var isLoading: Bool
    @Binding var result: String
    @Binding var error: String?

    @State private var selectedAction: AIAction = .continueWriting
    @State private var showResult = false

    enum AIAction: String, CaseIterable {
        case continueWriting = "Continue Writing"
        case improve = "Improve"
        case brainstorm = "Brainstorm Ideas"
        case outline = "Generate Outline"

        var systemImage: String {
            switch self {
            case .continueWriting: return "pencil"
            case .improve:         return "wand.and.stars"
            case .brainstorm:      return "lightbulb"
            case .outline:         return "list.bullet"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List(AIAction.allCases, id: \.self) { action in
                Button {
                    run(action)
                } label: {
                    Label(action.rawValue, systemImage: action.systemImage)
                }
            }
            .navigationTitle("AI Assist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showResult) {
                AIResultView(result: result)
            }
        }
    }

    private func run(_ action: AIAction) {
        isLoading = true
        Task {
            do {
                switch action {
                case .continueWriting:
                    result = try await viewModel.writers.continueDocument(documentId: document.id)
                case .improve:
                    result = try await viewModel.writers.improveDocument(documentId: document.id)
                case .brainstorm:
                    result = try await viewModel.writers.brainstormIdeas(topic: document.title)
                case .outline:
                    result = try await viewModel.writers.generateOutline(concept: document.title)
                }
                await MainActor.run {
                    isLoading = false
                    showResult = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - AIResultView

struct AIResultView: View {
    @Environment(\.dismiss) private var dismiss
    let result: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(result)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("AI Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
