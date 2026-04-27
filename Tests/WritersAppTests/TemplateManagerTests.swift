import XCTest
@testable import WritersApp

// MARK: - TemplateManager Tests
// Tests focused on PR changes to the screenplay template:
// - Renamed template from "Screenplay" to "Screenplay Scene"
// - Added `character_state` placeholder (optional, empty default) and {{character_state}} token
// - Added `shot_description` placeholder (optional) and {{shot_description}} token
// - Template now has 10 placeholders (up from 8)

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

    // MARK: - Screenplay Scene Template: PR Changes

    private func screenplayTemplate() -> Template? {
        return manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }

    func testScreenplayTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(), "Screenplay Scene template must exist in defaults")
    }

    func testOldScreenplayNameNoLongerExists() {
        let old = manager.getAllTemplates().first { $0.name == "Screenplay" }
        XCTAssertNil(old, "The old 'Screenplay' template name must not exist after the PR rename")
    }

    /// PR change: character_state placeholder was added to the screenplay template.
    func testScreenplayTemplateHasCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasCharacterState = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertTrue(hasCharacterState,
            "PR adds 'character_state' placeholder to the Screenplay Scene template")
    }

    /// character_state placeholder must be optional.
    func testCharacterStatePlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "character_state placeholder must be optional (required=false)")
    }

    /// character_state placeholder must have an empty string default.
    func testCharacterStatePlaceholderHasEmptyDefault() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertEqual(placeholder?.defaultValue, "",
            "character_state placeholder must have empty string default")
    }

    /// PR change: shot_description placeholder was added to the screenplay template.
    func testScreenplayTemplateHasShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasShotDescription = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertTrue(hasShotDescription,
            "PR adds 'shot_description' placeholder to the Screenplay Scene template")
    }

    /// shot_description placeholder must be optional.
    func testShotDescriptionPlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "shot_description" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "shot_description placeholder must be optional (required=false)")
    }

    /// PR change: {{character_state}} token was added to the screenplay template content.
    func testScreenplayTemplateContentContainsCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain the {{character_state}} token added in this PR")
    }

    /// PR change: {{shot_description}} token was added to the screenplay template content.
    func testScreenplayTemplateContentContainsShotDescriptionToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{shot_description}}"),
            "Template content must contain the {{shot_description}} token added in this PR")
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

    /// After the PR, the screenplay template has exactly 10 placeholders (added character_state + shot_description).
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