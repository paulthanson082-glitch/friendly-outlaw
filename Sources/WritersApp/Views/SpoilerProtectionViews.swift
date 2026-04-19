#if canImport(SwiftUI)
import SwiftUI

// MARK: - Spoiler View Model

/// Observable view model for spoiler management. Platform-independent: runs on
/// both iPadOS (presented as a sheet) and macOS (presented as an inspector or
/// separate window).
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public class SpoilerViewModel: ObservableObject {
    @Published public var tags: [SpoilerTag] = []
    @Published public var showAddSheet = false
    @Published public var showExportSheet = false
    @Published public var exportedContent = ""
    @Published public var selectedFormat: SpoilerMarkupFormat = .markdown

    private let spoilerService: SpoilerProtectionService
    public var documentId: UUID?
    public var documentContent: String = ""

    public init(spoilerService: SpoilerProtectionService) {
        self.spoilerService = spoilerService
    }

    public func loadTags() {
        guard let docId = documentId else { tags = []; return }
        tags = spoilerService.getSpoilerTags(forDocument: docId)
    }

    public func addTag(startOffset: Int, endOffset: Int, description: String, severity: SpoilerSeverity) {
        guard let docId = documentId else { return }
        spoilerService.tagSpoiler(
            in: docId,
            startOffset: startOffset,
            endOffset: endOffset,
            description: description,
            severity: severity
        )
        loadTags()
    }

    public func removeTag(id: UUID) {
        spoilerService.removeSpoilerTag(id: id)
        loadTags()
    }

    public func generateRedacted() -> String {
        guard let docId = documentId else { return documentContent }
        return spoilerService.redactSpoilers(in: documentContent, document: docId)
    }

    public func generateExport(format: SpoilerMarkupFormat) -> String {
        guard let docId = documentId else { return documentContent }
        return spoilerService.exportWithSpoilerMarkup(
            content: documentContent,
            document: docId,
            format: format
        )
    }
}

// MARK: - Spoiler Manager View

/// Lists all spoiler tags for a document, with add/remove and export actions.
/// Adaptive: works as a sheet on iPad Pro and as an inspector or window on macOS.
@available(iOS 16.0, macOS 13.0, *)
public struct SpoilerManagerView: View {
    @ObservedObject public var viewModel: SpoilerViewModel

    public init(viewModel: SpoilerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.tags.isEmpty {
                    emptyState
                } else {
                    tagList
                }
            }
            .navigationTitle("Spoiler Guard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showAddSheet, onDismiss: { viewModel.loadTags() }) {
                AddSpoilerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                SpoilerExportView(content: viewModel.exportedContent, format: viewModel.selectedFormat)
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "eye.slash.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No Spoiler Tags")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tag plot-critical passages to protect readers\nfrom accidental spoilers.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                viewModel.showAddSheet = true
            } label: {
                Label("Add First Tag", systemImage: "plus.circle.fill")
                    .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding()
    }

    private var tagList: some View {
        List {
            Section("Protected Regions (\(viewModel.tags.count))") {
                ForEach(viewModel.tags) { tag in
                    SpoilerTagRow(tag: tag, content: viewModel.documentContent) {
                        viewModel.removeTag(id: tag.id)
                    }
                }
            }

            Section("Export with Markup") {
                exportRow(format: .markdown,
                          icon: "text.badge.checkmark",
                          label: "Markdown")
                exportRow(format: .html,
                          icon: "chevron.left.forwardslash.chevron.right",
                          label: "HTML")
                exportRow(format: .plainText,
                          icon: "doc.plaintext",
                          label: "Plain Text")
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showAddSheet = true
            } label: {
                Label("Add Spoiler Tag", systemImage: "plus")
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }

    private func exportRow(format: SpoilerMarkupFormat, icon: String, label: String) -> some View {
        Button {
            viewModel.selectedFormat = format
            viewModel.exportedContent = viewModel.generateExport(format: format)
            viewModel.showExportSheet = true
        } label: {
            Label(label, systemImage: icon)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Spoiler Tag Row

@available(iOS 16.0, macOS 13.0, *)
struct SpoilerTagRow: View {
    let tag: SpoilerTag
    let content: String
    let onDelete: () -> Void

    private var previewText: String {
        let scalars = Array(content.unicodeScalars)
        let start = max(0, min(tag.startOffset, scalars.count))
        let end = max(start, min(tag.endOffset, scalars.count))
        guard end > start else { return "(empty range)" }
        let snippet = String(String.UnicodeScalarView(scalars[start..<end]))
        return snippet.count > 60
            ? String(snippet.prefix(60)) + "…"
            : snippet
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            severityBadge
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                if !tag.description.isEmpty {
                    Text(tag.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Text(previewText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text("Chars \(tag.startOffset)–\(tag.endOffset)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var severityBadge: some View {
        Text(tag.severity.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severityColor.opacity(0.15))
            .foregroundColor(severityColor)
            .cornerRadius(4)
    }

    private var severityColor: Color {
        switch tag.severity {
        case .minor:    return .blue
        case .moderate: return .orange
        case .major:    return .red
        }
    }
}

// MARK: - Add Spoiler View

@available(iOS 16.0, macOS 13.0, *)
struct AddSpoilerView: View {
    @ObservedObject var viewModel: SpoilerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var startOffset: String = "0"
    @State private var endOffset: String = ""
    @State private var description: String = ""
    @State private var severity: SpoilerSeverity = .moderate

    private var contentLength: Int {
        viewModel.documentContent.unicodeScalars.count
    }

    private var isValid: Bool {
        guard let s = Int(startOffset), let e = Int(endOffset) else { return false }
        return e > s && s >= 0 && e <= contentLength
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Start offset")
                        Spacer()
                        TextField("0", text: $startOffset)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .frame(width: 90)
                    }
                    HStack {
                        Text("End offset")
                        Spacer()
                        TextField("e.g. \(min(contentLength, 50))", text: $endOffset)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .frame(width: 90)
                    }
                    Text("Document length: \(contentLength) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Character Range")
                }

                Section {
                    TextField("e.g. Villain's true identity", text: $description)
                    Picker("Severity", selection: $severity) {
                        ForEach(SpoilerSeverity.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle("Add Spoiler Tag")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let s = Int(startOffset), let e = Int(endOffset) {
                            viewModel.addTag(
                                startOffset: s,
                                endOffset: e,
                                description: description,
                                severity: severity
                            )
                        }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #else
        .frame(minWidth: 380, idealWidth: 420, minHeight: 360)
        #endif
    }
}

// MARK: - Spoiler Export View

@available(iOS 16.0, macOS 13.0, *)
struct SpoilerExportView: View {
    let content: String
    let format: SpoilerMarkupFormat
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var formatName: String {
        switch format {
        case .markdown:  return "Markdown"
        case .html:      return "HTML"
        case .plainText: return "Plain Text"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
                    .padding()
            }
            .navigationTitle("Export — \(formatName)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyToClipboard(content)
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.large])
        #else
        .frame(minWidth: 540, idealWidth: 640, minHeight: 480)
        #endif
    }

    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}

// MARK: - macOS Entry Point

/// Standalone macOS window for spoiler management on MacBook Pro.
/// Embed this in a `WindowGroup` or present it as a separate scene.
@available(macOS 13.0, *)
public struct MacSpoilerWindow: View {
    @StateObject private var spoilerVM: SpoilerViewModel

    public init(
        spoilerService: SpoilerProtectionService,
        documentId: UUID?,
        documentContent: String
    ) {
        let vm = SpoilerViewModel(spoilerService: spoilerService)
        vm.documentId = documentId
        vm.documentContent = documentContent
        _spoilerVM = StateObject(wrappedValue: vm)
    }

    public var body: some View {
        SpoilerManagerView(viewModel: spoilerVM)
            .frame(minWidth: 480, idealWidth: 560, minHeight: 520)
            .onAppear { spoilerVM.loadTags() }
    }
}

#endif
