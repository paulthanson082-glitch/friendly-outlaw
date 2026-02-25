import SwiftUI
import WritersApp

// MARK: - DocumentsView

struct DocumentsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showNewDocument = false
    @State private var searchText = ""

    private var filtered: [Document] {
        guard !searchText.isEmpty else { return viewModel.documents }
        return viewModel.documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text",
                        description: Text("Tap + to create your first document.")
                    )
                } else {
                    List {
                        ForEach(filtered) { document in
                            NavigationLink {
                                DocumentEditorView(document: document)
                            } label: {
                                DocumentRowView(document: document)
                            }
                        }
                        .onDelete(perform: viewModel.deleteDocuments)
                    }
                    .searchable(text: $searchText, prompt: "Search documents")
                }
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewDocument = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewDocument) {
                NewDocumentView()
            }
        }
    }
}

// MARK: - DocumentRowView

struct DocumentRowView: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.title)
                .font(.headline)
            HStack {
                Text(document.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(document.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - NewDocumentView

struct NewDocumentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedCategory: TemplateCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createBlankDocument(title: title, category: selectedCategory)
                        dismiss()
                    }
                }
            }
        }
    }
}
