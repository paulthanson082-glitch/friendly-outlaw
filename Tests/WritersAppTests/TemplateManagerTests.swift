import XCTest
@testable import WritersApp

// MARK: - TemplateManager Tests
// Tests focused on PR changes to the screenplay template:
// - Removed `character_state` placeholder and {{character_state}} from content
// - Removed `shot_description` placeholder and {{shot_description}} from content

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

    // MARK: - Screenplay Template: Removed Placeholders (PR Change)

    private func screenplayTemplate() -> Template? {
        return manager.getAllTemplates().first { $0.name == "Screenplay" }
    }

    func testScreenplayTemplateExists() {
        XCTAssertNotNil(screenplayTemplate(), "Screenplay template must exist in defaults")
    }

    /// PR change: character_state placeholder was removed from the screenplay template.
    func testScreenplayTemplateDoesNotHaveCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        let hasCharacterState = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertFalse(hasCharacterState,
            "character_state placeholder must have been removed from the screenplay template in this PR")
    }

    /// PR change: shot_description placeholder was removed from the screenplay template.
    func testScreenplayTemplateDoesNotHaveShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        let hasShotDescription = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertFalse(hasShotDescription,
            "shot_description placeholder must have been removed from the screenplay template in this PR")
    }

    /// PR change: {{character_state}} token was removed from the screenplay template content.
    func testScreenplayTemplateContentDoesNotContainCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertFalse(template.content.contains("{{character_state}}"),
            "Template content must not contain {{character_state}} token after PR removal")
    }

    /// PR change: {{shot_description}} token was removed from the screenplay template content.
    func testScreenplayTemplateContentDoesNotContainShotDescriptionToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertFalse(template.content.contains("{{shot_description}}"),
            "Template content must not contain {{shot_description}} token after PR removal")
    }

    // MARK: - Screenplay Template: Required Placeholders Still Present

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

    /// After the PR, the screenplay template has exactly 8 placeholders (removed 2 of 10).
    func testScreenplayTemplateHasExactPlaceholderCount() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertEqual(template.placeholders.count, 8,
            "After removing character_state and shot_description, screenplay template should have 8 placeholders")
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
}