import XCTest
@testable import WritersApp

// MARK: - TemplateManager Tests
// Tests focused on the screenplay template (named "Screenplay Scene"):
// - Has `character_state` placeholder (optional, empty default)
// - Has `shot_description` placeholder (optional)
// - Template has 10 placeholders total

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

    // MARK: - Screenplay Scene Template

    private func screenplayTemplate() -> Template? {
        return manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }

    func testScreenplayTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(), "Screenplay Scene template must exist in defaults")
    }

    /// Template has character_state placeholder.
    func testScreenplayTemplateHasCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasCharacterState = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertTrue(hasCharacterState,
            "character_state placeholder must be present in the screenplay template")
    }

    /// Template has shot_description placeholder.
    func testScreenplayTemplateHasShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasShotDescription = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertTrue(hasShotDescription,
            "shot_description placeholder must be present in the screenplay template")
    }

    /// Template content contains {{character_state}} token.
    func testScreenplayTemplateContentContainsCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain {{character_state}} token")
    }

    /// Template content contains {{shot_description}} token.
    func testScreenplayTemplateContentContainsShotDescriptionToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{shot_description}}"),
            "Template content must contain {{shot_description}} token")
    }

    // MARK: - Screenplay Scene Template: Required Placeholders Still Present

    func testScreenplayTemplateHasSceneHeadingPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "scene_heading" })
    }

    func testScreenplayTemplateHasActionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "action" })
    }

    func testScreenplayTemplateHasCharacterPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "character" })
    }

    func testScreenplayTemplateHasDialoguePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue" })
    }

    func testScreenplayTemplateHasTransitionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "transition" })
    }

    func testScreenplayTemplateHasCharacter2Placeholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "character_2" })
    }

    func testScreenplayTemplateHasParentheticalPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "parenthetical" })
    }

    func testScreenplayTemplateHasDialogue2Placeholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue_2" })
    }

    /// The screenplay template has exactly 10 placeholders.
    func testScreenplayTemplateHasExactPlaceholderCount() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.placeholders.count, 10,
            "Screenplay Scene template should have 10 placeholders")
    }

    func testScreenplayTemplateContentContainsRequiredTokens() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{scene_heading}}"))
        XCTAssertTrue(template.content.contains("{{action}}"))
        XCTAssertTrue(template.content.contains("{{character}}"))
        XCTAssertTrue(template.content.contains("{{dialogue}}"))
        XCTAssertTrue(template.content.contains("{{transition}}"))
    }

    func testScreenplayTemplateIsInScreenplayCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.category, .screenplay)
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
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" })
    }

    func testGetTemplatesByCategory() {
        let results = manager.getTemplates(for: .screenplay)
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" })
    }
}