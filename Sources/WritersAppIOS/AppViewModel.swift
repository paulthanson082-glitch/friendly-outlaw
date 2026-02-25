import Foundation
import WritersApp

// MARK: - AppViewModel

/// Central view model that wraps WritersApp for SwiftUI consumption.
@MainActor
public final class AppViewModel: ObservableObject {

    // MARK: - Public State

    @Published public var documents: [Document] = []
    @Published public var templates: [Template] = []
    @Published public var isAIEnabled: Bool = false

    // MARK: - Private

    public let writers: WritersApp

    private let apiKeyDefaultsKey = "writerapp_ai_key"

    // MARK: - Init

    public init() {
        self.writers = WritersApp()
        restoreAIIfAvailable()
        refresh()
    }

    // MARK: - Data

    public func refresh() {
        documents = writers.documentManager.getAllDocuments()
        templates = writers.templateManager.getAllTemplates()
    }

    // MARK: - AI

    private func restoreAIIfAvailable() {
        guard let saved = UserDefaults.standard.string(forKey: apiKeyDefaultsKey),
              !saved.isEmpty else { return }
        applyAIConfig(apiKey: saved)
    }

    public func enableAI(apiKey: String) {
        guard !apiKey.isEmpty else { return }
        applyAIConfig(apiKey: apiKey)
        if writers.isAIEnabled {
            UserDefaults.standard.set(apiKey, forKey: apiKeyDefaultsKey)
        }
    }

    public func disableAI() {
        writers.disableAI()
        isAIEnabled = false
        UserDefaults.standard.removeObject(forKey: apiKeyDefaultsKey)
    }

    private func applyAIConfig(apiKey: String) {
        let config = AIConfiguration(
            apiKey: apiKey,
            model: .claude35Sonnet,
            maxTokens: 4096,
            temperature: 0.7
        )
        writers.enableAI(configuration: config)
        isAIEnabled = writers.isAIEnabled
    }

    // MARK: - Documents

    @discardableResult
    public func createBlankDocument(title: String, category: TemplateCategory) -> Document {
        let doc = writers.createBlankDocument(title: title.isEmpty ? "Untitled" : title, category: category)
        refresh()
        return doc
    }

    @discardableResult
    public func createFromTemplate(templateId: UUID, values: [String: String]) -> Document? {
        guard let doc = writers.createDocumentFromTemplate(templateId: templateId, values: values) else {
            return nil
        }
        refresh()
        return doc
    }

    public func updateDocument(_ document: Document) {
        writers.documentManager.updateDocument(document)
        refresh()
    }

    public func deleteDocuments(at offsets: IndexSet) {
        for index in offsets {
            writers.documentManager.deleteDocument(id: documents[index].id)
        }
        refresh()
    }
}
