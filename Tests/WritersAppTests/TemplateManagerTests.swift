import XCTest
@testable import WritersApp

/// Tests for TemplateManager, focused on the Screenplay Scene template's
/// character_state and parenthetical placeholder configuration.
final class TemplateManagerTests: XCTestCase {
    var templateManager: TemplateManager!

    override func setUp() {
        super.setUp()
        templateManager = TemplateManager()
    }

    override func tearDown() {
        templateManager = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func screenplayTemplate() throws -> Template {
        let templates = templateManager.getTemplates(for: .screenplay)
        guard let template = templates.first else {
            XCTFail("No screenplay template found")
            throw XCTestError(.failureWhileWaiting)
        }
        return template
    }

    private func placeholder(key: String, in template: Template) -> Placeholder? {
        return template.placeholders.first { $0.key == key }
    }

    // MARK: - character_state placeholder

    func testScreenplayCharacterStatePlaceholderKey() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        XCTAssertNotNil(ph, "Screenplay template must contain a 'character_state' placeholder")
        XCTAssertEqual(ph?.key, "character_state")
    }

    func testScreenplayCharacterStatePlaceholderLabel() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        XCTAssertEqual(ph?.label, "Character State")
    }

    func testScreenplayCharacterStatePlaceholderDescription() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        XCTAssertEqual(ph?.description, "Physical action or emotion")
    }

    func testScreenplayCharacterStatePlaceholderIsNotRequired() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        XCTAssertEqual(ph?.required, false,
                       "character_state should be optional (required: false)")
    }

    func testScreenplayCharacterStatePlaceholderDefaultValueIsEmptyString() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        // defaultValue must be "" (empty string), not nil
        XCTAssertNotNil(ph?.defaultValue,
                        "character_state defaultValue should be set (empty string), not nil")
        XCTAssertEqual(ph?.defaultValue, "",
                       "character_state defaultValue should be an empty string")
    }

    // MARK: - parenthetical placeholder

    func testScreenplayParentheticalPlaceholderKey() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        XCTAssertNotNil(ph, "Screenplay template must contain a 'parenthetical' placeholder")
        XCTAssertEqual(ph?.key, "parenthetical")
    }

    func testScreenplayParentheticalPlaceholderLabel() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        XCTAssertEqual(ph?.label, "Parenthetical")
    }

    func testScreenplayParentheticalPlaceholderDescription() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        XCTAssertEqual(ph?.description, "How the dialogue is delivered")
    }

    func testScreenplayParentheticalPlaceholderIsNotRequired() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        XCTAssertEqual(ph?.required, false,
                       "parenthetical should be optional (required: false)")
    }

    func testScreenplayParentheticalPlaceholderDefaultValueIsEmptyString() throws {
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        // defaultValue must be "" (empty string), not nil
        XCTAssertNotNil(ph?.defaultValue,
                        "parenthetical defaultValue should be set (empty string), not nil")
        XCTAssertEqual(ph?.defaultValue, "",
                       "parenthetical defaultValue should be an empty string")
    }

    // MARK: - Distinguish from nil-default optional placeholders

    func testScreenplayCharacterStatePlaceholderDefaultValueIsNotNil() throws {
        // Regression: parameter reordering must not collapse defaultValue to its
        // zero-value (nil). Verify the empty-string default is preserved.
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_state", in: template)
        XCTAssertFalse(ph?.defaultValue == nil,
                       "character_state defaultValue must not be nil after parameter reorder")
    }

    func testScreenplayParentheticalPlaceholderDefaultValueIsNotNil() throws {
        // Regression: same guard for parenthetical.
        let template = try screenplayTemplate()
        let ph = placeholder(key: "parenthetical", in: template)
        XCTAssertFalse(ph?.defaultValue == nil,
                       "parenthetical defaultValue must not be nil after parameter reorder")
    }

    // MARK: - Contrast with optional-but-no-default placeholders

    func testScreenplayCharacter2PlaceholderHasNilDefaultValue() throws {
        // character_2 is optional but has no defaultValue — confirms our assertions
        // above are discriminating and not trivially true for all optional placeholders.
        let template = try screenplayTemplate()
        let ph = placeholder(key: "character_2", in: template)
        XCTAssertNotNil(ph, "Screenplay template must contain a 'character_2' placeholder")
        XCTAssertEqual(ph?.required, false)
        XCTAssertNil(ph?.defaultValue,
                     "character_2 has no default value and should remain nil")
    }

    func testScreenplayDialogue2PlaceholderHasNilDefaultValue() throws {
        // dialogue_2 is optional but has no defaultValue.
        let template = try screenplayTemplate()
        let ph = placeholder(key: "dialogue_2", in: template)
        XCTAssertNotNil(ph, "Screenplay template must contain a 'dialogue_2' placeholder")
        XCTAssertEqual(ph?.required, false)
        XCTAssertNil(ph?.defaultValue,
                     "dialogue_2 has no default value and should remain nil")
    }

    // MARK: - Contrast with non-empty default value placeholder

    func testScreenplayTransitionPlaceholderDefaultValue() throws {
        // transition has defaultValue "CUT TO:" — confirms defaultValue="" is meaningfully
        // different from a non-empty default, and both survive the parameter ordering.
        let template = try screenplayTemplate()
        let ph = placeholder(key: "transition", in: template)
        XCTAssertNotNil(ph, "Screenplay template must contain a 'transition' placeholder")
        XCTAssertEqual(ph?.defaultValue, "CUT TO:",
                       "transition defaultValue should be 'CUT TO:'")
    }

    // MARK: - Required placeholders are not accidentally made optional

    func testScreenplayRequiredPlaceholdersRemainRequired() throws {
        let template = try screenplayTemplate()
        let requiredKeys = ["scene_heading", "action", "character", "dialogue"]
        for key in requiredKeys {
            let ph = placeholder(key: key, in: template)
            XCTAssertNotNil(ph, "Expected required placeholder '\(key)' to exist")
            XCTAssertEqual(ph?.required, true,
                           "Placeholder '\(key)' should be required")
        }
    }

    // MARK: - Placeholder ordering in template

    func testScreenplayCharacterStatePrecedesDialogue() throws {
        // Structural check: character_state appears before dialogue in the placeholder list,
        // matching the screenplay scene order.
        let template = try screenplayTemplate()
        let keys = template.placeholders.map { $0.key }
        guard let characterStateIndex = keys.firstIndex(of: "character_state"),
              let dialogueIndex = keys.firstIndex(of: "dialogue") else {
            XCTFail("Expected both 'character_state' and 'dialogue' placeholders")
            return
        }
        XCTAssertLessThan(characterStateIndex, dialogueIndex,
                          "character_state should appear before dialogue in placeholder list")
    }

    func testScreenplayParentheticalPrecedesDialogue2() throws {
        // parenthetical appears before dialogue_2, matching screenplay scene structure.
        let template = try screenplayTemplate()
        let keys = template.placeholders.map { $0.key }
        guard let parentheticalIndex = keys.firstIndex(of: "parenthetical"),
              let dialogue2Index = keys.firstIndex(of: "dialogue_2") else {
            XCTFail("Expected both 'parenthetical' and 'dialogue_2' placeholders")
            return
        }
        XCTAssertLessThan(parentheticalIndex, dialogue2Index,
                          "parenthetical should appear before dialogue_2 in placeholder list")
    }

    // MARK: - Total optional placeholder count in screenplay template

    func testScreenplayTemplateOptionalPlaceholderCount() throws {
        // The screenplay template defines exactly 5 optional placeholders:
        // character_state, character_2, parenthetical, dialogue_2, shot_description.
        let template = try screenplayTemplate()
        let optionalPlaceholders = template.placeholders.filter { !$0.required }
        XCTAssertEqual(optionalPlaceholders.count, 5,
                       "Screenplay template should have exactly 5 optional placeholders")
    }

    func testScreenplayTemplateOptionalWithEmptyDefaultCount() throws {
        // Exactly 2 optional placeholders have an explicit empty-string defaultValue:
        // character_state and parenthetical.
        let template = try screenplayTemplate()
        let emptyDefaultOptional = template.placeholders.filter {
            !$0.required && $0.defaultValue == ""
        }
        XCTAssertEqual(emptyDefaultOptional.count, 2,
                       "Exactly character_state and parenthetical should be optional with empty defaultValue")
        let keys = Set(emptyDefaultOptional.map { $0.key })
        XCTAssertEqual(keys, ["character_state", "parenthetical"])
    }
}