import XCTest
@testable import WritersApp

// MARK: - TemplateManager Tests
// Tests focused on PR changes to the screenplay template:
// - Template renamed from "Screenplay" to "Screenplay Scene"
// - ADDED `character_state` placeholder and {{character_state}} token to content
// - ADDED `shot_description` placeholder and {{shot_description}} token to content

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

    // MARK: - Screenplay Template: Added Placeholders (PR Change)

    private func screenplayTemplate() -> Template? {
        return manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }

    func testScreenplayTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(), "Screenplay Scene template must exist in defaults")
    }

    /// PR change: character_state placeholder was ADDED to the screenplay template.
    func testScreenplayTemplateHasCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasCharacterState = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertTrue(hasCharacterState,
            "character_state placeholder must be present in the screenplay template after this PR")
    }

    /// PR change: shot_description placeholder was ADDED to the screenplay template.
    func testScreenplayTemplateHasShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasShotDescription = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertTrue(hasShotDescription,
            "shot_description placeholder must be present in the screenplay template after this PR")
    }

    /// PR change: {{character_state}} token was ADDED to the screenplay template content.
    func testScreenplayTemplateContentContainsCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain {{character_state}} token after PR addition")
    }

    /// PR change: {{shot_description}} token was ADDED to the screenplay template content.
    func testScreenplayTemplateContentContainsShotDescriptionToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{shot_description}}"),
            "Template content must contain {{shot_description}} token after PR addition")
    }

    // MARK: - Screenplay Template: Required Placeholders Still Present

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

    /// After the PR, the screenplay template has exactly 10 placeholders (added character_state and shot_description).
    func testScreenplayTemplateHasExactPlaceholderCount() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.placeholders.count, 10,
            "After adding character_state and shot_description, screenplay template should have 10 placeholders")
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

    /// character_state placeholder is marked as not required (optional field).
    func testCharacterStatePlaceholderIsNotRequired() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertNotNil(placeholder, "character_state placeholder must exist")
        XCTAssertFalse(placeholder?.required ?? true,
            "character_state placeholder must be optional (required = false)")
    }

    /// shot_description placeholder is marked as not required (optional field).
    func testShotDescriptionPlaceholderIsNotRequired() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "shot_description" }
        XCTAssertNotNil(placeholder, "shot_description placeholder must exist")
        XCTAssertFalse(placeholder?.required ?? true,
            "shot_description placeholder must be optional (required = false)")
    }

    // MARK: - Screenplay Template: Name Change (PR Change)

    /// PR change: template was renamed from "Screenplay" to "Screenplay Scene".
    func testOldScreenplayNameNoLongerExists() {
        let oldTemplate = manager.getAllTemplates().first { $0.name == "Screenplay" }
        XCTAssertNil(oldTemplate,
            "Template with old name 'Screenplay' must not exist after rename to 'Screenplay Scene'")
    }

    func testScreenplaySceneNameExists() {
        let newTemplate = manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
        XCTAssertNotNil(newTemplate,
            "Template with new name 'Screenplay Scene' must exist after rename")
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
