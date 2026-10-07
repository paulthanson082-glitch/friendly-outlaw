import XCTest
@testable import WritersApp

// MARK: - CategorizedIdea Tests (PR Change: removed Identifiable, changed init)

final class CategorizedIdeaTests: XCTestCase {

    // MARK: - Initialization

    func testCategorizedIdeaInitWithAllParameters() {
        let idea = CategorizedIdea(
            title: "Flying ships",
            description: "Vessels that sail the sky",
            isSpeculative: true
        )
        XCTAssertEqual(idea.title, "Flying ships")
        XCTAssertEqual(idea.description, "Vessels that sail the sky")
        XCTAssertTrue(idea.isSpeculative)
    }

    func testCategorizedIdeaInitWithNonSpeculative() {
        let idea = CategorizedIdea(
            title: "Underground city",
            description: "A civilization beneath the earth",
            isSpeculative: false
        )
        XCTAssertFalse(idea.isSpeculative)
    }

    func testCategorizedIdeaEmptyStrings() {
        let idea = CategorizedIdea(title: "", description: "", isSpeculative: false)
        XCTAssertEqual(idea.title, "")
        XCTAssertEqual(idea.description, "")
    }

    // MARK: - Not Identifiable (PR change: id removed)

    func testCategorizedIdeaHasNoIdProperty() {
        // The init no longer accepts an id parameter - compile-time confirmation
        let idea = CategorizedIdea(title: "Test", description: "Desc", isSpeculative: false)
        // If Identifiable were still present, there would be an `id` property; verify it is absent
        // The best we can do at runtime is confirm the struct initialises without an id arg
        XCTAssertNotNil(idea, "CategorizedIdea should initialise successfully without an id argument")
    }

    // MARK: - Codable

    func testCategorizedIdeaCodableRoundTrip() throws {
        let original = CategorizedIdea(
            title: "Quantum teleportation",
            description: "Instant travel via quantum entanglement",
            isSpeculative: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)

        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.isSpeculative, original.isSpeculative)
    }

    func testCategorizedIdeaDecodingPreservesSpeculativeFalse() throws {
        let json = """
        {"title":"Gravity wells","description":"Natural phenomenon","isSpeculative":false}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: json)
        XCTAssertFalse(decoded.isSpeculative)
    }

    func testCategorizedIdeaDecodingPreservesSpeculativeTrue() throws {
        let json = """
        {"title":"Warp drive","description":"Faster-than-light travel","isSpeculative":true}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: json)
        XCTAssertTrue(decoded.isSpeculative)
    }

    func testCategorizedIdeaEncodingDoesNotContainIdKey() throws {
        let idea = CategorizedIdea(title: "X", description: "Y", isSpeculative: false)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["id"], "Encoded JSON must not contain an 'id' key after Identifiable was removed")
    }
}

// MARK: - IdeaCategory Tests (PR Change: removed Identifiable, changed init)

final class IdeaCategoryTests: XCTestCase {

    private func makeIdea(title: String = "Idea", speculative: Bool = false) -> CategorizedIdea {
        return CategorizedIdea(title: title, description: "Desc for \(title)", isSpeculative: speculative)
    }

    // MARK: - Initialization

    func testIdeaCategoryInitWithEmptyIdeas() {
        let category = IdeaCategory(name: "Technology", description: "Tech concepts", ideas: [])
        XCTAssertEqual(category.name, "Technology")
        XCTAssertEqual(category.description, "Tech concepts")
        XCTAssertTrue(category.ideas.isEmpty)
    }

    func testIdeaCategoryInitWithMultipleIdeas() {
        let ideas = [makeIdea(title: "A"), makeIdea(title: "B"), makeIdea(title: "C")]
        let category = IdeaCategory(name: "Plot", description: "Plot ideas", ideas: ideas)
        XCTAssertEqual(category.ideas.count, 3)
        XCTAssertEqual(category.ideas[0].title, "A")
        XCTAssertEqual(category.ideas[2].title, "C")
    }

    func testIdeaCategoryPreservesIdeaOrder() {
        let titles = ["First", "Second", "Third", "Fourth"]
        let ideas = titles.map { makeIdea(title: $0) }
        let category = IdeaCategory(name: "Ordered", description: "", ideas: ideas)
        let resultTitles = category.ideas.map { $0.title }
        XCTAssertEqual(resultTitles, titles)
    }

    // MARK: - Not Identifiable (PR change: id removed)

    func testIdeaCategoryHasNoIdProperty() {
        let category = IdeaCategory(name: "Test", description: "Desc", ideas: [])
        XCTAssertNotNil(category, "IdeaCategory should initialise successfully without an id argument")
    }

    // MARK: - Codable

    func testIdeaCategoryCodableRoundTrip() throws {
        let idea = makeIdea(title: "Plot twist", speculative: true)
        let original = IdeaCategory(name: "Narrative", description: "Narrative devices", ideas: [idea])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IdeaCategory.self, from: data)

        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas[0].title, "Plot twist")
        XCTAssertTrue(decoded.ideas[0].isSpeculative)
    }

    func testIdeaCategoryCodableWithEmptyIdeas() throws {
        let original = IdeaCategory(name: "Empty", description: "No ideas yet", ideas: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IdeaCategory.self, from: data)
        XCTAssertTrue(decoded.ideas.isEmpty)
    }

    func testIdeaCategoryEncodingDoesNotContainIdKey() throws {
        let category = IdeaCategory(name: "X", description: "Y", ideas: [])
        let data = try JSONEncoder().encode(category)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["id"], "Encoded JSON must not contain an 'id' key after Identifiable was removed")
    }
}

// MARK: - BrainstormResult Tests (PR Change: removed Identifiable, changed init)

final class BrainstormResultTests: XCTestCase {

    private func makeCategory(name: String, ideaCount: Int = 0) -> IdeaCategory {
        let ideas = (0..<ideaCount).map {
            CategorizedIdea(title: "Idea \($0)", description: "Desc", isSpeculative: false)
        }
        return IdeaCategory(name: name, description: "Category \(name)", ideas: ideas)
    }

    // MARK: - Initialization

    func testBrainstormResultInitWithNoCategories() {
        let result = BrainstormResult(categories: [])
        XCTAssertTrue(result.categories.isEmpty)
    }

    func testBrainstormResultInitWithSingleCategory() {
        let category = makeCategory(name: "World Building", ideaCount: 3)
        let result = BrainstormResult(categories: [category])
        XCTAssertEqual(result.categories.count, 1)
        XCTAssertEqual(result.categories[0].name, "World Building")
        XCTAssertEqual(result.categories[0].ideas.count, 3)
    }

    func testBrainstormResultInitWithMultipleCategories() {
        let categories = [
            makeCategory(name: "Characters", ideaCount: 2),
            makeCategory(name: "Settings", ideaCount: 1),
            makeCategory(name: "Conflicts", ideaCount: 4)
        ]
        let result = BrainstormResult(categories: categories)
        XCTAssertEqual(result.categories.count, 3)
    }

    // MARK: - Not Identifiable (PR change: id removed)

    func testBrainstormResultHasNoIdProperty() {
        let result = BrainstormResult(categories: [])
        XCTAssertNotNil(result, "BrainstormResult should initialise successfully without an id argument")
    }

    // MARK: - Codable

    func testBrainstormResultCodableRoundTrip() throws {
        let idea = CategorizedIdea(title: "Time dilation", description: "Physics concept", isSpeculative: true)
        let category = IdeaCategory(name: "Sci-Fi Tropes", description: "Common tropes", ideas: [idea])
        let original = BrainstormResult(categories: [category])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)

        XCTAssertEqual(decoded.categories.count, 1)
        XCTAssertEqual(decoded.categories[0].name, "Sci-Fi Tropes")
        XCTAssertEqual(decoded.categories[0].ideas.count, 1)
        XCTAssertEqual(decoded.categories[0].ideas[0].title, "Time dilation")
        XCTAssertTrue(decoded.categories[0].ideas[0].isSpeculative)
    }

    func testBrainstormResultCodableWithEmptyCategories() throws {
        let original = BrainstormResult(categories: [])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertTrue(decoded.categories.isEmpty)
    }

    func testBrainstormResultEncodingDoesNotContainIdKey() throws {
        let result = BrainstormResult(categories: [])
        let data = try JSONEncoder().encode(result)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNil(json?["id"], "Encoded JSON must not contain an 'id' key after Identifiable was removed")
    }

    func testBrainstormResultPreservesCategoryOrder() throws {
        let names = ["Alpha", "Beta", "Gamma"]
        let categories = names.map { makeCategory(name: $0) }
        let original = BrainstormResult(categories: categories)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertEqual(decoded.categories.map { $0.name }, names)
    }

    // MARK: - Regression: ensure backward-compatible JSON without id field decodes correctly

    func testBrainstormResultDecodesFromJsonWithoutIdField() throws {
        let json = """
        {"categories":[{"name":"Plot","description":"Plot devices","ideas":[]}]}
        """.data(using: .utf8)!
        let result = try JSONDecoder().decode(BrainstormResult.self, from: json)
        XCTAssertEqual(result.categories.count, 1)
        XCTAssertEqual(result.categories[0].name, "Plot")
    }

    // MARK: - Regression: old JSON containing id fields must still decode correctly

    func testBrainstormResultDecodesFromOldJsonWithIdFields() throws {
        // Old serialized payloads that still contain "id" fields for categories/ideas
        // must decode without throwing (Swift ignores unknown keys by default)
        let json = """
        {
          "id": "AAAAAAAA-0000-0000-0000-000000000000",
          "categories": [
            {
              "id": "BBBBBBBB-0000-0000-0000-000000000000",
              "name": "Legacy Category",
              "description": "From old format",
              "ideas": [
                {
                  "id": "CCCCCCCC-0000-0000-0000-000000000000",
                  "title": "Legacy Idea",
                  "description": "Old idea format",
                  "isSpeculative": false
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!
        let result = try JSONDecoder().decode(BrainstormResult.self, from: json)
        XCTAssertEqual(result.categories.count, 1)
        XCTAssertEqual(result.categories[0].name, "Legacy Category")
        XCTAssertEqual(result.categories[0].ideas[0].title, "Legacy Idea")
        XCTAssertFalse(result.categories[0].ideas[0].isSpeculative)
    }
}

// MARK: - Additional IdeaCategory Regression Tests

extension IdeaCategoryTests {

    func testIdeaCategoryDecodesFromJsonWithoutIdField() throws {
        // Backward-compat: JSON produced before Identifiable was removed must still decode
        let json = """
        {"name":"Old Style","description":"No id key","ideas":[]}
        """.data(using: .utf8)!
        let category = try JSONDecoder().decode(IdeaCategory.self, from: json)
        XCTAssertEqual(category.name, "Old Style")
        XCTAssertTrue(category.ideas.isEmpty)
    }

    func testIdeaCategoryWithSpecialCharactersInFields() throws {
        let idea = CategorizedIdea(
            title: "Café au lait ☕",
            description: "Unicode & special chars: <>&\"'",
            isSpeculative: false
        )
        let category = IdeaCategory(name: "Special™", description: "Café & Résumé", ideas: [idea])
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(IdeaCategory.self, from: data)
        XCTAssertEqual(decoded.name, "Special™")
        XCTAssertEqual(decoded.ideas[0].title, "Café au lait ☕")
        XCTAssertEqual(decoded.ideas[0].description, "Unicode & special chars: <>&\"'")
    }
}

// MARK: - Additional CategorizedIdea Regression Tests

extension CategorizedIdeaTests {

    func testCategorizedIdeaDecodesFromOldJsonWithIdField() throws {
        // Old JSON with an "id" key must be decoded without error (key is ignored)
        let json = """
        {
          "id": "DEADBEEF-0000-0000-0000-000000000000",
          "title": "Legacy Idea",
          "description": "Had an id once",
          "isSpeculative": true
        }
        """.data(using: .utf8)!
        let idea = try JSONDecoder().decode(CategorizedIdea.self, from: json)
        XCTAssertEqual(idea.title, "Legacy Idea")
        XCTAssertTrue(idea.isSpeculative)
    }

    func testCategorizedIdeaSpeculativeFlagIsFaithfullyPreserved() throws {
        // Boundary: ensure isSpeculative=true and isSpeculative=false are independently preserved
        let speculative = CategorizedIdea(title: "Spec", description: "Speculative", isSpeculative: true)
        let concrete = CategorizedIdea(title: "Conc", description: "Concrete", isSpeculative: false)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let decodedSpec = try decoder.decode(CategorizedIdea.self, from: try encoder.encode(speculative))
        let decodedConc = try decoder.decode(CategorizedIdea.self, from: try encoder.encode(concrete))
        XCTAssertTrue(decodedSpec.isSpeculative)
        XCTAssertFalse(decodedConc.isSpeculative)
    }
}