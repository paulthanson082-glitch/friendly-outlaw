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

    // MARK: - Hanson Letter Template

    func testHansonLetterTemplateExists() {
        let template = manager.getAllTemplates().first { $0.name == "Hanson Letter" }
        XCTAssertNotNil(template, "Hanson Letter template must exist in defaults")
    }

    func testHansonLetterTemplateIsBusinessLetter() {
        guard let template = manager.getAllTemplates().first(where: { $0.name == "Hanson Letter" }) else {
            return XCTFail("Hanson Letter template not found")
        }
        XCTAssertEqual(template.category, .businessLetter)
    }

    func testHansonLetterTemplateHasRequiredPlaceholders() {
        guard let template = manager.getAllTemplates().first(where: { $0.name == "Hanson Letter" }) else {
            return XCTFail("Hanson Letter template not found")
        }
        let requiredKeys = ["sender_name", "recipient_name", "date", "opening", "closing"]
        for key in requiredKeys {
            XCTAssertTrue(template.placeholders.contains { $0.key == key },
                         "Hanson Letter must have placeholder: \(key)")
        }
    }
}
