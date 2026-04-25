import XCTest
@testable import WritersApp

// MARK: - Screenplay Scene Template Tests
//
// This PR renamed the template from "Screenplay" to "Screenplay Scene" and added two new
// placeholders: `character_state` and `shot_description`. The template content now also
// includes the {{character_state}} and {{shot_description}} tokens.
//
// These tests verify the actual source-code behavior (10 placeholders, both tokens present
// in content), matching the WritersAppTests expectations.

final class ScreenplaySceneTemplateTests: XCTestCase {

    private var manager: TemplateManager!

    override func setUp() {
        super.setUp()
        manager = TemplateManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func screenplayTemplate() -> Template? {
        manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }

    // MARK: - Template Name

    func testScreenplaySceneTemplateExistsByNewName() {
        XCTAssertNotNil(screenplayTemplate(),
            "Template must be accessible by the new name 'Screenplay Scene' after the PR rename")
    }

    func testOldScreenplayNameNoLongerExists() {
        let oldTemplate = manager.getAllTemplates().first { $0.name == "Screenplay" }
        XCTAssertNil(oldTemplate,
            "The old template name 'Screenplay' must no longer exist after the PR rename")
    }

    func testScreenplaySceneIsFoundBySearchingScreenplay() {
        let results = manager.searchTemplates(query: "Screenplay")
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" },
            "Searching for 'Screenplay' must return the 'Screenplay Scene' template")
    }

    // MARK: - New Placeholders: character_state

    func testScreenplaySceneTemplateHasCharacterStatePlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasCharacterState = template.placeholders.contains { $0.key == "character_state" }
        XCTAssertTrue(hasCharacterState,
            "PR adds 'character_state' placeholder to the Screenplay Scene template")
    }

    func testCharacterStatePlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "character_state placeholder must be optional (required=false)")
    }

    func testCharacterStatePlaceholderHasEmptyDefaultValue() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertEqual(placeholder?.defaultValue, "",
            "character_state placeholder must have an empty string default value")
    }

    func testScreenplaySceneContentContainsCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain the {{character_state}} token added in this PR")
    }

    // MARK: - New Placeholders: shot_description

    func testScreenplaySceneTemplateHasShotDescriptionPlaceholder() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let hasShotDescription = template.placeholders.contains { $0.key == "shot_description" }
        XCTAssertTrue(hasShotDescription,
            "PR adds 'shot_description' placeholder to the Screenplay Scene template")
    }

    func testShotDescriptionPlaceholderIsOptional() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "shot_description" }
        XCTAssertNotNil(placeholder)
        XCTAssertFalse(placeholder?.required ?? true,
            "shot_description placeholder must be optional (required=false)")
    }

    func testScreenplaySceneContentContainsShotDescriptionToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{shot_description}}"),
            "Template content must contain the {{shot_description}} token added in this PR")
    }

    // MARK: - Total Placeholder Count

    func testScreenplaySceneTemplateHasTenPlaceholders() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.placeholders.count, 10,
            "After adding character_state and shot_description, the template must have exactly 10 placeholders")
    }

    func testScreenplaySceneTemplateHasAllExpectedPlaceholderKeys() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let keys = Set(template.placeholders.map { $0.key })
        let expected: Set<String> = [
            "scene_heading", "action", "character", "dialogue",
            "character_2", "parenthetical", "dialogue_2", "transition",
            "character_state", "shot_description"
        ]
        XCTAssertEqual(keys, expected,
            "Template must have exactly the expected 10 placeholder keys")
    }

    // MARK: - Existing Placeholders Not Removed

    func testScreenplaySceneRetainsSceneHeadingPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "scene_heading" })
    }

    func testScreenplaySceneRetainsActionPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "action" })
    }

    func testScreenplaySceneRetainsDialoguePlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue" })
    }

    func testScreenplaySceneRetainsTransitionPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "transition" })
    }

    // MARK: - Template Category

    func testScreenplaySceneTemplateIsInScreenplayCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.category, .screenplay,
            "Template category must still be .screenplay after the rename")
    }

    // MARK: - Template Content Tokens

    func testScreenplaySceneContentContainsAllRequiredTokens() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let requiredTokens = [
            "{{scene_heading}}",
            "{{action}}",
            "{{character}}",
            "{{dialogue}}",
            "{{transition}}",
            "{{character_state}}",
            "{{shot_description}}"
        ]
        for token in requiredTokens {
            XCTAssertTrue(template.content.contains(token),
                "Template content must contain \(token)")
        }
    }

    // MARK: - Retrieved by Category

    func testGetTemplatesByCategoryReturnsScreenplayScene() {
        let results = manager.getTemplates(for: .screenplay)
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" },
            "getTemplates(for: .screenplay) must return the 'Screenplay Scene' template")
    }
}