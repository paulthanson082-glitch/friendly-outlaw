import XCTest
@testable import WritersApp

// MARK: - TemplateManager Tests
// The Screenplay template is named "Screenplay" and has 8 placeholders:
// scene_heading, action, character, dialogue, character_2, parenthetical, dialogue_2, transition.

final class TemplateManagerTests: XCTestCase {

    var manager: TemplateManager!

    override func setUp() {
        super.setUp()
        manager = TemplateManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Screenplay Template

    private func screenplayTemplate() -> Template? {
        return manager.getAllTemplates().first { $0.name == "Screenplay" }
    }

    func testScreenplayTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(), "Screenplay template must exist in defaults")
    }

    func testScreenplayTemplateHasSceneHeadingPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "scene_heading" })
    }

    func testScreenplayTemplateHasActionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "action" })
    }

    func testScreenplayTemplateHasCharacterPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "character" })
    }

    func testScreenplayTemplateHasDialoguePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue" })
    }

    func testScreenplayTemplateHasTransitionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "transition" })
    }

    func testScreenplayTemplateHasCharacter2Placeholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "character_2" })
    }

    func testScreenplayTemplateHasParentheticalPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "parenthetical" })
    }

    func testScreenplayTemplateHasDialogue2Placeholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue_2" })
    }

    func testScreenplayTemplateHasExactPlaceholderCount() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertEqual(template.placeholders.count, 8,
            "Screenplay template should have exactly 8 placeholders")
    }

    func testScreenplayTemplateContentContainsRequiredTokens() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertTrue(template.content.contains("{{scene_heading}}"))
        XCTAssertTrue(template.content.contains("{{action}}"))
        XCTAssertTrue(template.content.contains("{{character}}"))
        XCTAssertTrue(template.content.contains("{{dialogue}}"))
        XCTAssertTrue(template.content.contains("{{transition}}"))
    }

    func testScreenplayTemplateIsInScreenplayCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertEqual(template.category, .screenplay)
    }

    func testScreenplaySceneNameDoesNotExist() {
        let sceneTemplate = manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
        XCTAssertNil(sceneTemplate,
            "Template with name 'Screenplay Scene' must not exist; template is named 'Screenplay'")
    }

    // MARK: - Other Default Templates Unaffected

    func testNovelChapterTemplateExists() {
        let template = manager.getAllTemplates().first { $0.name == "Novel Chapter" }
        XCTAssertNotNil(template)
    }

    func testShortStoryTemplateExists() {
        let template = manager.getAllTemplates().first { $0.name == "Short Story" }
        XCTAssertNotNil(template)
    }

    func testBlogPostTemplateExists() {
        let template = manager.getAllTemplates().first { $0.name == "Blog Post" }
        XCTAssertNotNil(template)
    }

    // MARK: - Template Manager CRUD (regression)

    func testAddAndRetrieveCustomTemplate() {
        let custom = Template(
            name: "My Custom",
            category: .other,
            description: "Custom template",
            content: "Hello {{name}}",
            placeholders: [Placeholder(key: "name", label: "Name")],
            metadata: TemplateMetadata(tags: ["custom"])
        )
        manager.addTemplate(custom)
        let retrieved = manager.getTemplate(id: custom.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "My Custom")
    }

    func testSearchTemplateByName() {
        let results = manager.searchTemplates(query: "Screenplay")
        XCTAssertTrue(results.contains { $0.name == "Screenplay" })
    }

    func testGetTemplatesByCategory() {
        let results = manager.getTemplates(for: .screenplay)
        XCTAssertTrue(results.contains { $0.name == "Screenplay" })
    }

    // MARK: - AI Template Generation Tests

    func testCreateTemplateFromAIBasicConversion() {
        let generated = GeneratedTemplate(
            name: "Test Novel Outline",
            category: "Novel",
            placeholders: [
                GeneratedPlaceholder(name: "SETUP", description: "Story setup", exampleText: "Once upon a time..."),
                GeneratedPlaceholder(name: "CONFLICT", description: "Main conflict", exampleText: "But then...")
            ],
            structure: "# Setup\n{{SETUP}}\n\n# Conflict\n{{CONFLICT}}"
        )

        do {
            let template = try manager.createTemplateFromAI(generated: generated)

            XCTAssertEqual(template.name, "Test Novel Outline")
            XCTAssertEqual(template.category, .novel)
            XCTAssertEqual(template.placeholders.count, 2)
            XCTAssertTrue(template.content.contains("{{SETUP}}"))
            XCTAssertTrue(template.content.contains("{{CONFLICT}}"))
        } catch {
            XCTFail("Failed to create template from AI: \(error)")
        }
    }

    func testCreateTemplateFromAIPreservesStructure() {
        let testStructure = """
        # Part 1: Introduction
        {{INTRODUCTION}}

        # Part 2: Development
        {{DEVELOPMENT}}

        # Part 3: Conclusion
        {{CONCLUSION}}
        """

        let generated = GeneratedTemplate(
            name: "Article Template",
            category: "Article",
            placeholders: [
                GeneratedPlaceholder(name: "INTRODUCTION", description: "Opening", exampleText: "Start here"),
                GeneratedPlaceholder(name: "DEVELOPMENT", description: "Main content", exampleText: "Content"),
                GeneratedPlaceholder(name: "CONCLUSION", description: "Closing", exampleText: "End here")
            ],
            structure: testStructure
        )

        do {
            let template = try manager.createTemplateFromAI(generated: generated)
            XCTAssertEqual(template.content, testStructure)
        } catch {
            XCTFail("Failed to create template: \(error)")
        }
    }

    func testCreateTemplateFromAIConvertsPlaceholders() {
        let generated = GeneratedTemplate(
            name: "Blog Post",
            category: "Blog Post",
            placeholders: [
                GeneratedPlaceholder(name: "TITLE", description: "Post title", exampleText: "My Blog Post")
            ],
            structure: "# {{TITLE}}"
        )

        do {
            let template = try manager.createTemplateFromAI(generated: generated)

            // Check that placeholders were converted properly
            XCTAssertEqual(template.placeholders.count, 1)
            let placeholder = template.placeholders[0]
            XCTAssertEqual(placeholder.key, "title") // Converted to lowercase
            XCTAssertEqual(placeholder.label, "TITLE") // Original name
            XCTAssertEqual(placeholder.description, "Post title")
            XCTAssertEqual(placeholder.defaultValue, "My Blog Post") // exampleText becomes defaultValue
        } catch {
            XCTFail("Failed to create template: \(error)")
        }
    }

    func testCreateTemplateFromAIGeneratesUniqueIds() {
        let generated = GeneratedTemplate(
            name: "Unique Template",
            category: "Other",
            placeholders: [],
            structure: "# Template"
        )

        do {
            let template1 = try manager.createTemplateFromAI(generated: generated)
            let template2 = try manager.createTemplateFromAI(generated: generated)

            // IDs should be different
            XCTAssertNotEqual(template1.id, template2.id)
            // Names should be the same
            XCTAssertEqual(template1.name, template2.name)
        } catch {
            XCTFail("Failed to create templates: \(error)")
        }
    }

    func testCreateTemplateFromAIStoresTemplate() {
        let generated = GeneratedTemplate(
            name: "Stored Template",
            category: "Essay",
            placeholders: [],
            structure: "# Essay"
        )

        do {
            let created = try manager.createTemplateFromAI(generated: generated)

            // Template should be retrievable
            let retrieved = manager.getTemplate(id: created.id)
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved?.name, "Stored Template")
        } catch {
            XCTFail("Failed to create template: \(error)")
        }
    }

    func testCreateTemplateFromAIAddsAIGeneratedTag() {
        let generated = GeneratedTemplate(
            name: "Tagged Template",
            category: "Novel",
            placeholders: [],
            structure: "# Template"
        )

        do {
            let template = try manager.createTemplateFromAI(generated: generated)

            XCTAssertTrue(template.metadata.tags.contains("ai-generated"))
            XCTAssertTrue(template.metadata.tags.contains("novel"))
        } catch {
            XCTFail("Failed to create template: \(error)")
        }
    }

    func testCreateTemplateFromAIWithUnknownCategory() {
        let generated = GeneratedTemplate(
            name: "Unknown Category",
            category: "UnknownType",
            placeholders: [],
            structure: "# Template"
        )

        do {
            let template = try manager.createTemplateFromAI(generated: generated)

            // Should default to .other category
            XCTAssertEqual(template.category, .other)
        } catch {
            XCTFail("Failed to create template: \(error)")
        }
    }
}
