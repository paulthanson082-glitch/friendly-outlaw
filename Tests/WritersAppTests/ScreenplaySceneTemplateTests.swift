import XCTest
@testable import WritersApp

// MARK: - Screenplay Scene Template Tests
//
// PR changes to TemplateManager.swift:
// - Renamed template from "Screenplay" to "Screenplay Scene"
// - Added `character_state` placeholder (optional, empty default) and {{character_state}} token
// - Added `shot_description` placeholder (optional) and {{shot_description}} token
// - Template now has 10 placeholders (up from 8)

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

    // MARK: - Template Rename: "Screenplay" → "Screenplay Scene"

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

    func testScreenplaySceneIsFoundBySearchingScene() {
        let results = manager.searchTemplates(query: "Scene")
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" },
            "Searching for 'Scene' must return the 'Screenplay Scene' template")
    }

    // MARK: - New Placeholder: character_state

    func testScreenplaySceneHasCharacterStatePlaceholder() {
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

    func testCharacterStatePlaceholderHasEmptyStringDefault() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let placeholder = template.placeholders.first { $0.key == "character_state" }
        XCTAssertEqual(placeholder?.defaultValue, "",
            "character_state placeholder must have an empty string as its default value")
    }

    func testTemplateContentContainsCharacterStateToken() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertTrue(template.content.contains("{{character_state}}"),
            "Template content must contain the {{character_state}} token added in this PR")
    }

    // MARK: - New Placeholder: shot_description

    func testScreenplaySceneHasShotDescriptionPlaceholder() {
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

    func testTemplateContentContainsShotDescriptionToken() {
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

    // MARK: - Pre-existing Placeholders Still Present

    func testScreenplaySceneRetainsSceneHeadingPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "scene_heading" })
    }

    func testScreenplaySceneRetainsActionPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "action" })
    }

    func testScreenplaySceneRetainsCharacterPlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "character" })
    }

    func testScreenplaySceneRetainsDialoguePlaceholder() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        XCTAssertTrue(template.placeholders.contains { $0.key == "dialogue" })
    }

    func testScreenplaySceneRetainsTransitionPlaceholderWithDefaultValue() {
        guard let template = screenplayTemplate() else { return XCTFail("Template not found") }
        let placeholder = template.placeholders.first { $0.key == "transition" }
        XCTAssertNotNil(placeholder)
        XCTAssertEqual(placeholder?.defaultValue, "CUT TO:",
            "transition placeholder must retain 'CUT TO:' as its default value")
    }

    // MARK: - Template Category

    func testScreenplaySceneIsInScreenplayCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        XCTAssertEqual(template.category, .screenplay,
            "Template category must still be .screenplay after the rename")
    }

    func testGetTemplatesByCategoryReturnsScreenplayScene() {
        let results = manager.getTemplates(for: .screenplay)
        XCTAssertTrue(results.contains { $0.name == "Screenplay Scene" },
            "getTemplates(for: .screenplay) must return the 'Screenplay Scene' template")
    }

    // MARK: - Template Content Tokens

    func testTemplateContentContainsAllRequiredTokens() {
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

    // MARK: - Boundary / Regression

    /// Verifies that the new placeholders appear between existing dialogue elements.
    func testCharacterStatePlaceholderAppearsBeforeDialogueInContent() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay Scene template not found")
        }
        let content = template.content
        let characterRange = content.range(of: "{{character}}")
        let characterStateRange = content.range(of: "{{character_state}}")
        let dialogueRange = content.range(of: "{{dialogue}}")
        XCTAssertNotNil(characterRange)
        XCTAssertNotNil(characterStateRange)
        XCTAssertNotNil(dialogueRange)
        if let charEnd = characterRange?.upperBound,
           let stateStart = characterStateRange?.lowerBound,
           let stateEnd = characterStateRange?.upperBound,
           let dialogueStart = dialogueRange?.lowerBound {
            XCTAssertLessThan(charEnd, stateStart,
                "{{character}} must appear before {{character_state}} in the template content")
            XCTAssertLessThan(stateEnd, dialogueStart,
                "{{character_state}} must appear before {{dialogue}} in the template content")
        }
    }
}