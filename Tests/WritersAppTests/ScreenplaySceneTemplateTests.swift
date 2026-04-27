import XCTest
@testable import WritersApp

// MARK: - Screenplay Template Tests
//
// The Screenplay template is named "Screenplay" and has 8 placeholders:
// scene_heading, action, character, dialogue, character_2, parenthetical, dialogue_2, transition.

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
        manager.getAllTemplates().first { $0.name == "Screenplay" }
    }

    // MARK: - Template exists by name "Screenplay"

    func testScreenplaySceneTemplateExistsByNewName() {
        XCTAssertNotNil(screenplayTemplate(),
            "Template must be accessible by the name 'Screenplay'")
    }

    func testOldScreenplayNameNoLongerExists() {
        let oldTemplate = manager.getAllTemplates().first { $0.name == "Screenplay Scene" }
        XCTAssertNil(oldTemplate,
            "There must be no template named 'Screenplay Scene'")
    }

    func testScreenplaySceneIsFoundBySearchingScreenplay() {
        let results = manager.searchTemplates(query: "Screenplay")
        XCTAssertTrue(results.contains { $0.name == "Screenplay" },
            "Searching for 'Screenplay' must return the 'Screenplay' template")
    }

    func testScreenplaySceneIsFoundBySearchingScene() {
        let results = manager.searchTemplates(query: "scene")
        XCTAssertTrue(results.contains { $0.name == "Screenplay" },
            "Searching for 'scene' must return the 'Screenplay' template")
    }

    // MARK: - Total Placeholder Count

    func testScreenplaySceneTemplateHasTenPlaceholders() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertEqual(template.placeholders.count, 8,
            "The Screenplay template must have exactly 8 placeholders")
    }

    func testScreenplaySceneTemplateHasAllExpectedPlaceholderKeys() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        let keys = Set(template.placeholders.map { $0.key })
        let expected: Set<String> = [
            "scene_heading", "action", "character", "dialogue",
            "character_2", "parenthetical", "dialogue_2", "transition"
        ]
        XCTAssertEqual(keys, expected,
            "Template must have exactly the expected 8 placeholder keys")
    }

    // MARK: - Pre-existing Placeholders Present

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
            "transition placeholder must have 'CUT TO:' as its default value")
    }

    // MARK: - Template Category

    func testScreenplaySceneIsInScreenplayCategory() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        XCTAssertEqual(template.category, .screenplay,
            "Template category must be .screenplay")
    }

    func testGetTemplatesByCategoryReturnsScreenplayScene() {
        let results = manager.getTemplates(for: .screenplay)
        XCTAssertTrue(results.contains { $0.name == "Screenplay" },
            "getTemplates(for: .screenplay) must return the 'Screenplay' template")
    }

    // MARK: - Template Content Tokens

    func testTemplateContentContainsAllRequiredTokens() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        let requiredTokens = [
            "{{scene_heading}}",
            "{{action}}",
            "{{character}}",
            "{{dialogue}}",
            "{{transition}}"
        ]
        for token in requiredTokens {
            XCTAssertTrue(template.content.contains(token),
                "Template content must contain \(token)")
        }
    }

    // MARK: - Boundary / Regression

    func testCharacterStatePlaceholderAppearsBeforeDialogueInContent() {
        guard let template = screenplayTemplate() else {
            return XCTFail("Screenplay template not found")
        }
        let content = template.content
        let characterRange = content.range(of: "{{character}}")
        let dialogueRange = content.range(of: "{{dialogue}}")
        XCTAssertNotNil(characterRange)
        XCTAssertNotNil(dialogueRange)
        if let charEnd = characterRange?.upperBound,
           let dialogueStart = dialogueRange?.lowerBound {
            XCTAssertLessThan(charEnd, dialogueStart,
                "{{character}} must appear before {{dialogue}} in the template content")
        }
    }
}
