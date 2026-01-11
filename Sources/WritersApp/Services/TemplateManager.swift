import Foundation

/// Manages template storage, retrieval, and operations
public class TemplateManager {
    private var templates: [UUID: Template]

    public init() {
        self.templates = [:]
        loadDefaultTemplates()
    }

    // MARK: - Template Management

    /// Adds a new template
    public func addTemplate(_ template: Template) {
        templates[template.id] = template
    }

    /// Retrieves a template by ID
    public func getTemplate(id: UUID) -> Template? {
        return templates[id]
    }

    /// Retrieves all templates
    public func getAllTemplates() -> [Template] {
        return Array(templates.values).sorted { $0.name < $1.name }
    }

    /// Retrieves templates by category
    public func getTemplates(for category: TemplateCategory) -> [Template] {
        return templates.values.filter { $0.category == category }
            .sorted { $0.name < $1.name }
    }

    /// Searches templates by name or description
    public func searchTemplates(query: String) -> [Template] {
        let lowercaseQuery = query.lowercased()
        return templates.values.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery)
        }.sorted { $0.name < $1.name }
    }

    /// Updates an existing template
    public func updateTemplate(_ template: Template) {
        templates[template.id] = template
    }

    /// Deletes a template
    public func deleteTemplate(id: UUID) {
        templates.removeValue(forKey: id)
    }

    // MARK: - Default Templates

    private func loadDefaultTemplates() {
        // Novel Chapter Template
        let novelTemplate = Template(
            name: "Novel Chapter",
            category: .novel,
            description: "Standard chapter template for novel writing",
            content: """
            # Chapter {{chapter_number}}: {{chapter_title}}

            {{opening_scene}}

            ---

            {{main_content}}

            ---

            {{closing_scene}}
            """,
            placeholders: [
                Placeholder(key: "chapter_number", label: "Chapter Number"),
                Placeholder(key: "chapter_title", label: "Chapter Title"),
                Placeholder(key: "opening_scene", label: "Opening Scene"),
                Placeholder(key: "main_content", label: "Main Content"),
                Placeholder(key: "closing_scene", label: "Closing Scene")
            ],
            metadata: TemplateMetadata(tags: ["fiction", "novel", "chapter"])
        )

        // Short Story Template
        let shortStoryTemplate = Template(
            name: "Short Story",
            category: .shortStory,
            description: "Three-act structure for short stories",
            content: """
            # {{title}}
            by {{author}}

            ## Act I: Setup
            {{act_one}}

            ## Act II: Confrontation
            {{act_two}}

            ## Act III: Resolution
            {{act_three}}

            ---

            Word Count: ~{{target_words}} words
            """,
            placeholders: [
                Placeholder(key: "title", label: "Story Title"),
                Placeholder(key: "author", label: "Author Name"),
                Placeholder(key: "act_one", label: "Act I Content"),
                Placeholder(key: "act_two", label: "Act II Content"),
                Placeholder(key: "act_three", label: "Act III Content"),
                Placeholder(key: "target_words", label: "Target Word Count", defaultValue: "5000")
            ],
            metadata: TemplateMetadata(tags: ["fiction", "short-story"])
        )

        // Screenplay Scene Template
        let screenplayTemplate = Template(
            name: "Screenplay Scene",
            category: .screenplay,
            description: "Standard screenplay scene format",
            content: """
            {{scene_heading}}

            {{action}}

            {{character}}
            {{dialogue}}

            {{character_2}}
            ({{parenthetical}})
            {{dialogue_2}}

            {{transition}}
            """,
            placeholders: [
                Placeholder(key: "scene_heading", label: "Scene Heading", description: "INT/EXT. LOCATION - TIME"),
                Placeholder(key: "action", label: "Action/Description"),
                Placeholder(key: "character", label: "Character Name"),
                Placeholder(key: "dialogue", label: "Dialogue"),
                Placeholder(key: "character_2", label: "Second Character", required: false),
                Placeholder(key: "parenthetical", label: "Parenthetical", required: false),
                Placeholder(key: "dialogue_2", label: "Second Dialogue", required: false),
                Placeholder(key: "transition", label: "Transition", defaultValue: "CUT TO:")
            ],
            metadata: TemplateMetadata(tags: ["screenplay", "script", "scene"])
        )

        // Blog Post Template
        let blogTemplate = Template(
            name: "Blog Post",
            category: .blogPost,
            description: "SEO-optimized blog post structure",
            content: """
            # {{title}}

            **Published:** {{date}}
            **Author:** {{author}}
            **Tags:** {{tags}}

            ## Introduction
            {{introduction}}

            ## {{section_1_title}}
            {{section_1_content}}

            ## {{section_2_title}}
            {{section_2_content}}

            ## {{section_3_title}}
            {{section_3_content}}

            ## Conclusion
            {{conclusion}}

            ---

            **Call to Action:** {{cta}}
            """,
            placeholders: [
                Placeholder(key: "title", label: "Post Title"),
                Placeholder(key: "date", label: "Publication Date"),
                Placeholder(key: "author", label: "Author"),
                Placeholder(key: "tags", label: "Tags"),
                Placeholder(key: "introduction", label: "Introduction"),
                Placeholder(key: "section_1_title", label: "Section 1 Title"),
                Placeholder(key: "section_1_content", label: "Section 1 Content"),
                Placeholder(key: "section_2_title", label: "Section 2 Title"),
                Placeholder(key: "section_2_content", label: "Section 2 Content"),
                Placeholder(key: "section_3_title", label: "Section 3 Title"),
                Placeholder(key: "section_3_content", label: "Section 3 Content"),
                Placeholder(key: "conclusion", label: "Conclusion"),
                Placeholder(key: "cta", label: "Call to Action")
            ],
            metadata: TemplateMetadata(tags: ["blog", "article", "seo"])
        )

        // Article Template
        let articleTemplate = Template(
            name: "Article",
            category: .article,
            description: "Professional article with research structure",
            content: """
            # {{title}}
            ## {{subtitle}}

            **Author:** {{author}}
            **Date:** {{date}}

            ### Abstract
            {{abstract}}

            ### Introduction
            {{introduction}}

            ### Background
            {{background}}

            ### Main Discussion
            {{main_discussion}}

            ### Analysis
            {{analysis}}

            ### Conclusion
            {{conclusion}}

            ### References
            {{references}}
            """,
            placeholders: [
                Placeholder(key: "title", label: "Article Title"),
                Placeholder(key: "subtitle", label: "Subtitle", required: false),
                Placeholder(key: "author", label: "Author"),
                Placeholder(key: "date", label: "Date"),
                Placeholder(key: "abstract", label: "Abstract"),
                Placeholder(key: "introduction", label: "Introduction"),
                Placeholder(key: "background", label: "Background"),
                Placeholder(key: "main_discussion", label: "Main Discussion"),
                Placeholder(key: "analysis", label: "Analysis"),
                Placeholder(key: "conclusion", label: "Conclusion"),
                Placeholder(key: "references", label: "References")
            ],
            metadata: TemplateMetadata(tags: ["article", "research", "academic"])
        )

        // Poetry Template
        let poetryTemplate = Template(
            name: "Poetry",
            category: .poetry,
            description: "Structured poetry template",
            content: """
            # {{title}}
            *by {{author}}*

            {{stanza_1}}

            {{stanza_2}}

            {{stanza_3}}

            {{stanza_4}}

            ---
            *{{dedication}}*
            """,
            placeholders: [
                Placeholder(key: "title", label: "Poem Title"),
                Placeholder(key: "author", label: "Poet Name"),
                Placeholder(key: "stanza_1", label: "First Stanza"),
                Placeholder(key: "stanza_2", label: "Second Stanza"),
                Placeholder(key: "stanza_3", label: "Third Stanza", required: false),
                Placeholder(key: "stanza_4", label: "Fourth Stanza", required: false),
                Placeholder(key: "dedication", label: "Dedication", required: false)
            ],
            metadata: TemplateMetadata(tags: ["poetry", "verse"])
        )

        // Business Letter Template
        let businessLetterTemplate = Template(
            name: "Business Letter",
            category: .businessLetter,
            description: "Professional business letter format",
            content: """
            {{sender_name}}
            {{sender_address}}
            {{sender_city_state_zip}}
            {{sender_email}}
            {{sender_phone}}

            {{date}}

            {{recipient_name}}
            {{recipient_title}}
            {{recipient_company}}
            {{recipient_address}}
            {{recipient_city_state_zip}}

            Dear {{salutation}},

            {{opening_paragraph}}

            {{body_paragraph_1}}

            {{body_paragraph_2}}

            {{closing_paragraph}}

            Sincerely,

            {{sender_name}}
            {{sender_title}}
            """,
            placeholders: [
                Placeholder(key: "sender_name", label: "Your Name"),
                Placeholder(key: "sender_address", label: "Your Address"),
                Placeholder(key: "sender_city_state_zip", label: "Your City, State ZIP"),
                Placeholder(key: "sender_email", label: "Your Email"),
                Placeholder(key: "sender_phone", label: "Your Phone"),
                Placeholder(key: "date", label: "Date"),
                Placeholder(key: "recipient_name", label: "Recipient Name"),
                Placeholder(key: "recipient_title", label: "Recipient Title"),
                Placeholder(key: "recipient_company", label: "Company Name"),
                Placeholder(key: "recipient_address", label: "Company Address"),
                Placeholder(key: "recipient_city_state_zip", label: "City, State ZIP"),
                Placeholder(key: "salutation", label: "Salutation", defaultValue: "Mr./Ms. Last Name"),
                Placeholder(key: "opening_paragraph", label: "Opening Paragraph"),
                Placeholder(key: "body_paragraph_1", label: "Body Paragraph 1"),
                Placeholder(key: "body_paragraph_2", label: "Body Paragraph 2", required: false),
                Placeholder(key: "closing_paragraph", label: "Closing Paragraph"),
                Placeholder(key: "sender_title", label: "Your Title")
            ],
            metadata: TemplateMetadata(tags: ["business", "letter", "professional"])
        )

        // Add all templates
        addTemplate(novelTemplate)
        addTemplate(shortStoryTemplate)
        addTemplate(screenplayTemplate)
        addTemplate(blogTemplate)
        addTemplate(articleTemplate)
        addTemplate(poetryTemplate)
        addTemplate(businessLetterTemplate)
    }
}
