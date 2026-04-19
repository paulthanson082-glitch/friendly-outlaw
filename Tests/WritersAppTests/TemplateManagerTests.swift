import XCTest
@testable import WritersApp

/// Tests for TemplateManager PR changes:
/// - Screenplay Scene template removed {{character_state}} and {{shot_description}} placeholders
/// - Screenplay Scene template content no longer contains those placeholder markers
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

    // MARK: - Screenplay template exists

    func testScreenplayTemplateIsPresent() {
        let screenplay = getScreenplayTemplate()
        XCTAssertNotNil(screenplay, "Screenplay Scene template should be available by default")
    }

    func testScreenplayTemplateHasCorrectCategory() {
        let screenplay = getScreenplayTemplate()
        XCTAssertEqual(screenplay?.category, .screenplay)
    }

    // MARK: - Removed placeholders (PR change)

    func testScreenplayTemplateDoesNotHaveCharacterStatePlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        let hasCharacterState = screenplay.placeholders.contains { $0.key == "character_state" }
        XCTAssertFalse(hasCharacterState,
                       "character_state placeholder should be removed from screenplay template")
    }

    func testScreenplayTemplateDoesNotHaveShotDescriptionPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        let hasShotDescription = screenplay.placeholders.contains { $0.key == "shot_description" }
        XCTAssertFalse(hasShotDescription,
                       "shot_description placeholder should be removed from screenplay template")
    }

    func testScreenplayTemplateContentDoesNotContainCharacterStateMarker() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertFalse(screenplay.content.contains("{{character_state}}"),
                       "Screenplay template content must not reference {{character_state}}")
    }

    func testScreenplayTemplateContentDoesNotContainShotDescriptionMarker() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertFalse(screenplay.content.contains("{{shot_description}}"),
                       "Screenplay template content must not reference {{shot_description}}")
    }

    // MARK: - Required placeholders still present

    func testScreenplayTemplateHasSceneHeadingPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "scene_heading" },
                      "scene_heading placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasActionPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "action" },
                      "action placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasCharacterPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "character" },
                      "character placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasDialoguePlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "dialogue" },
                      "dialogue placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasTransitionPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "transition" },
                      "transition placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasOptionalSecondCharacterPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "character_2" },
                      "character_2 (optional) placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasParentheticalPlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "parenthetical" },
                      "parenthetical placeholder must remain in screenplay template")
    }

    func testScreenplayTemplateHasSecondDialoguePlaceholder() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        XCTAssertTrue(screenplay.placeholders.contains { $0.key == "dialogue_2" },
                      "dialogue_2 placeholder must remain in screenplay template")
    }

    // MARK: - Placeholder count (8 after removing 2)

    func testScreenplayTemplateHasExactlyEightPlaceholders() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        // scene_heading, action, character, dialogue, character_2, parenthetical, dialogue_2, transition
        XCTAssertEqual(screenplay.placeholders.count, 8,
                       "Screenplay template should have 8 placeholders after removing character_state and shot_description")
    }

    // MARK: - Content markers match placeholders

    func testScreenplayTemplateContentContainsAllRemainingPlaceholderKeys() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        // All required (non-optional) placeholder keys should appear in content
        let requiredKeys = ["scene_heading", "action", "character", "dialogue", "transition"]
        for key in requiredKeys {
            XCTAssertTrue(screenplay.content.contains("{{\(key)}}"),
                          "Screenplay content must contain {{\(key)}}")
        }
    }

    // MARK: - Transition placeholder has correct default value

    func testScreenplayTransitionPlaceholderHasDefaultValue() {
        guard let screenplay = getScreenplayTemplate() else {
            XCTFail("Screenplay template not found")
            return
        }
        let transition = screenplay.placeholders.first { $0.key == "transition" }
        XCTAssertEqual(transition?.defaultValue, "CUT TO:",
                       "Transition placeholder default value should be 'CUT TO:'")
    }

    // MARK: - Other templates unaffected

    func testNovelChapterTemplateIsUnchanged() {
        let novel = templateManager.getAllTemplates().first { $0.name == "Novel Chapter" }
        XCTAssertNotNil(novel, "Novel Chapter template should still exist")
    }

    func testBlogPostTemplateIsUnchanged() {
        let blog = templateManager.getAllTemplates().first { $0.name == "Blog Post" }
        XCTAssertNotNil(blog, "Blog Post template should still exist")
    }

    func testTotalDefaultTemplateCount() {
        // 7 default templates: Novel Chapter, Short Story, Screenplay Scene, Blog Post, Article, Poetry, Business Letter
        XCTAssertGreaterThanOrEqual(templateManager.getAllTemplates().count, 7,
                                    "At least 7 default templates expected")
    }

    // MARK: - TemplateManager CRUD basics

    func testAddAndRetrieveCustomTemplate() {
        let custom = Template(
            name: "Custom Test",
            category: .other,
            description: "A custom template for testing",
            content: "Hello {{name}}",
            placeholders: [
                Placeholder(key: "name", label: "Your Name")
            ]
        )
        templateManager.addTemplate(custom)
        let retrieved = templateManager.getTemplate(id: custom.id)
        XCTAssertEqual(retrieved?.name, "Custom Test")
    }

    func testSearchTemplatesByName() {
        let results = templateManager.searchTemplates(query: "Screenplay")
        XCTAssertGreaterThanOrEqual(results.count, 1)
        XCTAssertTrue(results.allSatisfy { $0.name.lowercased().contains("screenplay") ||
                      $0.description.lowercased().contains("screenplay") })
    }

    func testGetTemplatesByCategory() {
        let screenplayTemplates = templateManager.getTemplates(for: .screenplay)
        XCTAssertGreaterThanOrEqual(screenplayTemplates.count, 1)
        XCTAssertTrue(screenplayTemplates.allSatisfy { $0.category == .screenplay })
    }

    // MARK: - Helpers

    private func getScreenplayTemplate() -> Template? {
        templateManager.getAllTemplates().first { $0.name == "Screenplay Scene" }
    }
}