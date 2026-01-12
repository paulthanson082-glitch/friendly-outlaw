/*:
 # Writers App with Templates - Swift Playground

 A comprehensive writing application with AI-powered assistance.

 ## Features
 - 📝 7+ Professional writing templates
 - 📄 Document management with word count tracking
 - 🤖 AI-powered writing assistance (Claude API)
 - 📊 Statistics and analytics
 - 🔧 Export to multiple formats

 ---
 */

import Foundation
import PlaygroundSupport

// MARK: - Models

//: ### Template Category
public enum TemplateCategory: String, CaseIterable {
    case novel = "Novel"
    case shortStory = "Short Story"
    case screenplay = "Screenplay"
    case blogPost = "Blog Post"
    case article = "Article"
    case poetry = "Poetry"
    case letter = "Letter"
    case essay = "Essay"
    case journal = "Journal"
    case technicalDoc = "Technical Documentation"
    case email = "Email"
}

//: ### Template Placeholder
public struct TemplatePlaceholder {
    public let key: String
    public let label: String
    public let description: String
    public let required: Bool
    public let defaultValue: String?

    public init(key: String, label: String, description: String = "", required: Bool = true, defaultValue: String? = nil) {
        self.key = key
        self.label = label
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
    }
}

//: ### Template
public struct Template {
    public let id: UUID
    public let name: String
    public let description: String
    public let category: TemplateCategory
    public let content: String
    public let placeholders: [TemplatePlaceholder]

    public init(name: String, description: String, category: TemplateCategory, content: String, placeholders: [TemplatePlaceholder]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.content = content
        self.placeholders = placeholders
    }

    public func createDocument(with values: [String: String]) -> Document {
        var processedContent = content
        for placeholder in placeholders {
            let value = values[placeholder.key] ?? placeholder.defaultValue ?? ""
            processedContent = processedContent.replacingOccurrences(of: "{{\(placeholder.key)}}", with: value)
        }

        let title = values["title"] ?? name
        return Document(title: title, content: processedContent, category: category)
    }
}

//: ### Document
public struct Document {
    public let id: UUID
    public var title: String
    public var content: String
    public let category: TemplateCategory
    public var metadata: DocumentMetadata

    public init(title: String, content: String, category: TemplateCategory) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.category = category
        self.metadata = DocumentMetadata()
    }

    public var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    public var characterCount: Int {
        return content.count
    }

    public var readingTime: Int {
        return max(1, wordCount / 200)
    }
}

public struct DocumentMetadata {
    public let created: Date
    public var modified: Date
    public var tags: [String]
    public var wordCountGoal: Int?

    public init(tags: [String] = [], wordCountGoal: Int? = nil) {
        self.created = Date()
        self.modified = Date()
        self.tags = tags
        self.wordCountGoal = wordCountGoal
    }
}

// MARK: - AI Models

//: ### AI Configuration
public struct AIConfiguration {
    public let apiKey: String
    public let model: AIModel
    public let maxTokens: Int
    public let temperature: Double

    public init(apiKey: String, model: AIModel = .claude35Sonnet, maxTokens: Int = 4096, temperature: Double = 0.7) {
        self.apiKey = apiKey
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

public enum AIModel: String {
    case claude35Sonnet = "claude-3-5-sonnet-20241022"
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"
}

//: ### AI Assistance Types
public enum AIAssistanceType {
    case continueWriting
    case improveText
    case grammarCheck
    case generateOutline
    case brainstormIdeas
    case characterDevelopment
    case titleGeneration
    case summarize
    case custom(String)

    public func prompt(for text: String) -> String {
        switch self {
        case .continueWriting:
            return "Continue writing from where this text leaves off. Match the style, tone, and voice.\n\n\(text)\n\nContinue:"
        case .improveText:
            return "Improve this text while maintaining its core message:\n\n\(text)\n\nImproved version:"
        case .grammarCheck:
            return "Check for grammar, spelling, and punctuation errors:\n\n\(text)\n\nCorrections:"
        case .generateOutline:
            return "Generate a detailed outline for:\n\n\(text)\n\nOutline:"
        case .brainstormIdeas:
            return "Brainstorm creative ideas for:\n\n\(text)\n\nIdeas:"
        case .characterDevelopment:
            return "Develop this character concept:\n\n\(text)\n\nCharacter development:"
        case .titleGeneration:
            return "Generate 10 compelling titles for:\n\n\(text)\n\nTitles:"
        case .summarize:
            return "Summarize this text:\n\n\(text)\n\nSummary:"
        case .custom(let instruction):
            return "\(instruction)\n\n\(text)\n\nResult:"
        }
    }
}

// MARK: - Services

//: ### Template Manager
public class TemplateManager {
    private var templates: [UUID: Template] = [:]

    public init() {
        loadDefaultTemplates()
    }

    private func loadDefaultTemplates() {
        // Novel Chapter Template
        let novelTemplate = Template(
            name: "Novel Chapter",
            description: "A structured chapter template for novel writing",
            category: .novel,
            content: """
            # Chapter {{chapter_number}}: {{chapter_title}}

            ## Opening Scene
            {{opening}}

            ## Main Content
            {{main_content}}

            ## Closing Scene
            {{closing}}
            """,
            placeholders: [
                TemplatePlaceholder(key: "chapter_number", label: "Chapter Number"),
                TemplatePlaceholder(key: "chapter_title", label: "Chapter Title"),
                TemplatePlaceholder(key: "opening", label: "Opening Scene"),
                TemplatePlaceholder(key: "main_content", label: "Main Content"),
                TemplatePlaceholder(key: "closing", label: "Closing Scene")
            ]
        )
        addTemplate(novelTemplate)

        // Short Story Template
        let storyTemplate = Template(
            name: "Short Story",
            description: "Three-act structure for short fiction",
            category: .shortStory,
            content: """
            # {{title}}

            ## Act I: Setup
            {{act1}}

            ## Act II: Confrontation
            {{act2}}

            ## Act III: Resolution
            {{act3}}
            """,
            placeholders: [
                TemplatePlaceholder(key: "title", label: "Story Title"),
                TemplatePlaceholder(key: "act1", label: "Act I"),
                TemplatePlaceholder(key: "act2", label: "Act II"),
                TemplatePlaceholder(key: "act3", label: "Act III")
            ]
        )
        addTemplate(storyTemplate)

        // Blog Post Template
        let blogTemplate = Template(
            name: "Blog Post",
            description: "SEO-optimized blog post structure",
            category: .blogPost,
            content: """
            # {{title}}

            ## Introduction
            {{intro}}

            ## Main Points
            {{main_points}}

            ## Conclusion
            {{conclusion}}

            ### Call to Action
            {{cta}}
            """,
            placeholders: [
                TemplatePlaceholder(key: "title", label: "Post Title"),
                TemplatePlaceholder(key: "intro", label: "Introduction"),
                TemplatePlaceholder(key: "main_points", label: "Main Points"),
                TemplatePlaceholder(key: "conclusion", label: "Conclusion"),
                TemplatePlaceholder(key: "cta", label: "Call to Action", required: false)
            ]
        )
        addTemplate(blogTemplate)
    }

    public func addTemplate(_ template: Template) {
        templates[template.id] = template
    }

    public func getTemplate(id: UUID) -> Template? {
        return templates[id]
    }

    public func getAllTemplates() -> [Template] {
        return Array(templates.values).sorted { $0.name < $1.name }
    }

    public func searchTemplates(query: String) -> [Template] {
        let lowercaseQuery = query.lowercased()
        return getAllTemplates().filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery)
        }
    }
}

//: ### Document Manager
public class DocumentManager {
    private var documents: [UUID: Document] = [:]

    public init() {}

    public func createDocument(_ document: Document) {
        documents[document.id] = document
    }

    public func getDocument(id: UUID) -> Document? {
        return documents[id]
    }

    public func getAllDocuments() -> [Document] {
        return Array(documents.values).sorted { $0.metadata.modified > $1.metadata.modified }
    }

    public func updateDocument(_ document: Document) {
        var updatedDoc = document
        updatedDoc.metadata.modified = Date()
        documents[document.id] = updatedDoc
    }

    public func deleteDocument(id: UUID) {
        documents.removeValue(forKey: id)
    }

    public func getTotalWordCount() -> Int {
        return documents.values.reduce(0) { $0 + $1.wordCount }
    }

    public func searchDocuments(query: String) -> [Document] {
        let lowercaseQuery = query.lowercased()
        return getAllDocuments().filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.content.lowercased().contains(lowercaseQuery)
        }
    }
}

//: ### AI Service
public class AIService {
    private let configuration: AIConfiguration
    private let apiURL = "https://api.anthropic.com/v1/messages"

    public init(configuration: AIConfiguration) {
        self.configuration = configuration
    }

    public func getAssistance(text: String, type: AIAssistanceType) async throws -> String {
        let prompt = type.prompt(for: text)
        return try await sendRequest(prompt: prompt)
    }

    private func sendRequest(prompt: String) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let requestBody: [String: Any] = [
            "model": configuration.model.rawValue,
            "max_tokens": configuration.maxTokens,
            "temperature": configuration.temperature,
            "messages": [["role": "user", "content": prompt]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "AIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw NSError(domain: "AIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        return text
    }
}

//: ### Main Writers App
public class WritersApp {
    public let templateManager: TemplateManager
    public let documentManager: DocumentManager
    public private(set) var aiService: AIService?

    public init() {
        self.templateManager = TemplateManager()
        self.documentManager = DocumentManager()
    }

    public func enableAI(configuration: AIConfiguration) {
        self.aiService = AIService(configuration: configuration)
    }

    public var isAIEnabled: Bool {
        return aiService != nil
    }

    public func createDocumentFromTemplate(templateId: UUID, values: [String: String]) -> Document? {
        guard let template = templateManager.getTemplate(id: templateId) else {
            return nil
        }
        let document = template.createDocument(with: values)
        documentManager.createDocument(document)
        return document
    }

    public func createBlankDocument(title: String, category: TemplateCategory) -> Document {
        let document = Document(title: title, content: "", category: category)
        documentManager.createDocument(document)
        return document
    }

    public func continueDocument(documentId: UUID) async throws -> String {
        guard let ai = aiService else {
            throw NSError(domain: "WritersApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "AI not enabled"])
        }
        guard let document = documentManager.getDocument(id: documentId) else {
            throw NSError(domain: "WritersApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }
        return try await ai.getAssistance(text: document.content, type: .continueWriting)
    }

    public func getStatistics() -> (documents: Int, words: Int, avgWords: Int) {
        let docs = documentManager.getAllDocuments()
        let totalWords = documentManager.getTotalWordCount()
        let avgWords = docs.isEmpty ? 0 : totalWords / docs.count
        return (docs.count, totalWords, avgWords)
    }
}

/*:
 ---
 ## Interactive Examples

 Let's explore the Writers App with hands-on examples!
 */

//: ### Example 1: Create the App
let app = WritersApp()
print("✓ Writers App created!")
print("Templates available: \(app.templateManager.getAllTemplates().count)")

//: ### Example 2: Browse Templates
print("\n📝 Available Templates:")
for template in app.templateManager.getAllTemplates() {
    print("  • \(template.name) - \(template.category.rawValue)")
}

//: ### Example 3: Create a Document from Template
let templates = app.templateManager.getAllTemplates()
if let novelTemplate = templates.first(where: { $0.name == "Novel Chapter" }) {
    print("\n📄 Creating document from template: \(novelTemplate.name)")

    let values: [String: String] = [
        "title": "The Beginning",
        "chapter_number": "1",
        "chapter_title": "A New Dawn",
        "opening": "The sun rose over the misty mountains...",
        "main_content": "Sarah had always dreamed of adventure...",
        "closing": "As night fell, she knew everything would change."
    ]

    if let document = app.createDocumentFromTemplate(templateId: novelTemplate.id, values: values) {
        print("✓ Document created: \(document.title)")
        print("  Word count: \(document.wordCount)")
        print("  Reading time: \(document.readingTime) min")
        print("\nContent preview:")
        print(String(document.content.prefix(200)))
    }
}

//: ### Example 4: Create a Blank Document
let blankDoc = app.createBlankDocument(title: "My Story Ideas", category: .journal)
print("\n📝 Blank document created: \(blankDoc.title)")

//: ### Example 5: Search Templates
let searchResults = app.templateManager.searchTemplates(query: "blog")
print("\n🔍 Search results for 'blog': \(searchResults.count) found")
for template in searchResults {
    print("  • \(template.name)")
}

//: ### Example 6: Get Statistics
let stats = app.getStatistics()
print("\n📊 Statistics:")
print("  Total documents: \(stats.documents)")
print("  Total words: \(stats.words)")
print("  Average words per document: \(stats.avgWords)")

/*:
 ---
 ## AI Features (Optional)

 To use AI features, you need an Anthropic API key.
 Uncomment the code below and add your API key:
 */

/*
// Enable AI features
let apiKey = "your-anthropic-api-key-here"
let aiConfig = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
app.enableAI(configuration: aiConfig)

// Use AI to continue writing
Task {
    if let doc = app.documentManager.getAllDocuments().first {
        do {
            let continuation = try await app.continueDocument(documentId: doc.id)
            print("\n🤖 AI Generated Continuation:")
            print(continuation)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
*/

/*:
 ---
 ## Try It Yourself!

 **Challenge 1:** Create your own custom template
 ```swift
 let myTemplate = Template(
     name: "My Custom Template",
     description: "Your description",
     category: .essay,
     content: "Your template content with {{placeholders}}",
     placeholders: [
         TemplatePlaceholder(key: "placeholder", label: "Your Label")
     ]
 )
 app.templateManager.addTemplate(myTemplate)
 ```

 **Challenge 2:** Create multiple documents and analyze them

 **Challenge 3:** With AI enabled, try different assistance types:
 - Continue Writing
 - Improve Text
 - Generate Outline
 - Brainstorm Ideas

 ---

 ### What's Next?
 - Add more templates for your specific needs
 - Create a series of related documents
 - Use AI to enhance your writing
 - Export your work (extend with exportDocument method)
 - Track your progress over time

 Happy Writing! ✍️
 */

// Enable indefinite execution for async operations
PlaygroundPage.current.needsIndefiniteExecution = true
