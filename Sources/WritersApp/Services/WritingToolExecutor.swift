import Foundation

/// Built-in tool executor for writing-related tools.
///
/// Provides tools that Claude can use during the tool loop to interact with
/// the app's documents, templates, and text analysis capabilities.
public class WritingToolExecutor: AIToolExecutor {
    private let documentManager: DocumentManager
    private let templateManager: TemplateManager

    public init(documentManager: DocumentManager, templateManager: TemplateManager) {
        self.documentManager = documentManager
        self.templateManager = templateManager
    }

    // MARK: - Tool Definitions

    /// The set of built-in writing tools available for AI tool use
    public static var tools: [ToolDefinition] {
        return [
            ToolDefinition(
                name: "get_word_count",
                description: "Count the number of words in a given text",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "text": [
                            "type": "string",
                            "description": "The text to count words in"
                        ]
                    ],
                    "required": ["text"]
                ]
            ),
            ToolDefinition(
                name: "search_documents",
                description: "Search through existing documents by query string",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "query": [
                            "type": "string",
                            "description": "Search query to find documents"
                        ]
                    ],
                    "required": ["query"]
                ]
            ),
            ToolDefinition(
                name: "get_document",
                description: "Retrieve a document by its title",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "The title of the document to retrieve"
                        ]
                    ],
                    "required": ["title"]
                ]
            ),
            ToolDefinition(
                name: "calculate_reading_time",
                description: "Calculate the estimated reading time for a text",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "text": [
                            "type": "string",
                            "description": "The text to calculate reading time for"
                        ]
                    ],
                    "required": ["text"]
                ]
            ),
            ToolDefinition(
                name: "list_templates",
                description: "List available writing templates, optionally filtered by category",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "category": [
                            "type": "string",
                            "description": "Optional category to filter templates (novel, shortStory, screenplay, blogPost, article, essay, poetry, businessLetter, proposal, resume, other)"
                        ]
                    ],
                    "required": [] as [String]
                ]
            )
        ]
    }

    // MARK: - Tool Execution

    public func executeTool(name: String, input: [String: Any]) async throws -> String {
        switch name {
        case "get_word_count":
            return try executeGetWordCount(input: input)
        case "search_documents":
            return try executeSearchDocuments(input: input)
        case "get_document":
            return try executeGetDocument(input: input)
        case "calculate_reading_time":
            return try executeCalculateReadingTime(input: input)
        case "list_templates":
            return executeListTemplates(input: input)
        default:
            throw AIServiceError.toolExecutionFailed(
                toolName: name,
                reason: "Unknown tool"
            )
        }
    }

    // MARK: - Individual Tool Implementations

    private func executeGetWordCount(input: [String: Any]) throws -> String {
        guard let text = input["text"] as? String else {
            throw AIServiceError.toolExecutionFailed(
                toolName: "get_word_count",
                reason: "Missing 'text' parameter"
            )
        }
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return "\(words.count) words"
    }

    private func executeSearchDocuments(input: [String: Any]) throws -> String {
        guard let query = input["query"] as? String else {
            throw AIServiceError.toolExecutionFailed(
                toolName: "search_documents",
                reason: "Missing 'query' parameter"
            )
        }
        let results = documentManager.searchDocuments(query: query)
        if results.isEmpty {
            return "No documents found matching '\(query)'"
        }
        return results.map { doc in
            "- \(doc.title) (\(doc.wordCount) words, \(doc.category.rawValue))"
        }.joined(separator: "\n")
    }

    private func executeGetDocument(input: [String: Any]) throws -> String {
        guard let title = input["title"] as? String else {
            throw AIServiceError.toolExecutionFailed(
                toolName: "get_document",
                reason: "Missing 'title' parameter"
            )
        }
        let docs = documentManager.searchDocuments(query: title)
        guard let doc = docs.first(where: {
            $0.title.lowercased() == title.lowercased()
        }) ?? docs.first else {
            return "Document not found: '\(title)'"
        }
        return """
        Title: \(doc.title)
        Category: \(doc.category.rawValue)
        Word Count: \(doc.wordCount)
        Content:
        \(doc.content)
        """
    }

    private func executeCalculateReadingTime(input: [String: Any]) throws -> String {
        guard let text = input["text"] as? String else {
            throw AIServiceError.toolExecutionFailed(
                toolName: "calculate_reading_time",
                reason: "Missing 'text' parameter"
            )
        }
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let minutes = max(1, wordCount / 200)
        return "Estimated reading time: \(minutes) minute\(minutes == 1 ? "" : "s") (\(wordCount) words at ~200 words per minute)"
    }

    private func executeListTemplates(input: [String: Any]) -> String {
        let category = input["category"] as? String
        var templates = templateManager.getAllTemplates()
        if let cat = category, let templateCategory = TemplateCategory(rawValue: cat) {
            templates = templates.filter { $0.category == templateCategory }
        }
        if templates.isEmpty {
            return "No templates found"
        }
        return templates.map { template in
            "- \(template.name) (\(template.category.rawValue)): \(template.description)"
        }.joined(separator: "\n")
    }
}
