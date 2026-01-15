import Foundation

/// Represents a writing template with structure and placeholders
public struct Template: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: TemplateCategory
    public let description: String
    public let content: String
    public let placeholders: [Placeholder]
    public let metadata: TemplateMetadata

    public init(
        id: UUID = UUID(),
        name: String,
        category: TemplateCategory,
        description: String,
        content: String,
        placeholders: [Placeholder],
        metadata: TemplateMetadata = TemplateMetadata()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.content = content
        self.placeholders = placeholders
        self.metadata = metadata
    }

    /// Creates a document from this template with filled placeholders
    public func createDocument(with values: [String: String]) -> Document {
        // Use regex-based atomic replacement to prevent nested placeholder substitution
        let pattern = "\\{\\{([^}]+)\\}\\}"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // Fallback to original content if regex fails
            return Document(
                title: values["title"] ?? name,
                content: content,
                templateId: id,
                category: category
            )
        }

        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))

        // Replace placeholders in reverse order to maintain correct offsets
        var processedContent = content
        for match in matches.reversed() {
            let keyRange = match.range(at: 1)
            let fullRange = match.range(at: 0)

            if keyRange.location != NSNotFound {
                let key = nsContent.substring(with: keyRange)
                if let value = values[key] {
                    let range = Range(fullRange, in: processedContent)!
                    processedContent.replaceSubrange(range, with: value)
                }
            }
        }

        return Document(
            title: values["title"] ?? name,
            content: processedContent,
            templateId: id,
            category: category
        )
    }
}

/// Template categories for organization
public enum TemplateCategory: String, Codable, CaseIterable {
    case novel = "Novel"
    case shortStory = "Short Story"
    case screenplay = "Screenplay"
    case blogPost = "Blog Post"
    case article = "Article"
    case essay = "Essay"
    case poetry = "Poetry"
    case businessLetter = "Business Letter"
    case proposal = "Proposal"
    case resume = "Resume"
    case other = "Other"
}

/// Placeholder for template substitution
public struct Placeholder: Codable, Identifiable {
    public let id: UUID
    public let key: String
    public let label: String
    public let description: String
    public let defaultValue: String?
    public let required: Bool

    public init(
        id: UUID = UUID(),
        key: String,
        label: String,
        description: String = "",
        defaultValue: String? = nil,
        required: Bool = true
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.description = description
        self.defaultValue = defaultValue
        self.required = required
    }
}

/// Metadata for templates
public struct TemplateMetadata: Codable {
    public let created: Date
    public let modified: Date
    public let author: String?
    public let version: String
    public let tags: [String]

    public init(
        created: Date = Date(),
        modified: Date = Date(),
        author: String? = nil,
        version: String = "1.0",
        tags: [String] = []
    ) {
        self.created = created
        self.modified = modified
        self.author = author
        self.version = version
        self.tags = tags
    }
}
