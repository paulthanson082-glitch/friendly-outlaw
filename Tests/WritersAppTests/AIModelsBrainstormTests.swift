import XCTest
@testable import WritersApp

// MARK: - CategorizedIdea Tests
// Tests for the updated CategorizedIdea struct which no longer conforms to Identifiable
// and no longer has a UUID id property (removed in this PR).

final class CategorizedIdeaBrainstormTests: XCTestCase {

    func testInitStoresTitle() {
        let idea = CategorizedIdea(title: "Magic System", description: "A unique rule-based magic", isSpeculative: false)
        XCTAssertEqual(idea.title, "Magic System")
    }

    func testInitStoresDescription() {
        let idea = CategorizedIdea(title: "Title", description: "Detailed description text", isSpeculative: false)
        XCTAssertEqual(idea.description, "Detailed description text")
    }

    func testInitStoresIsSpeculativeFalse() {
        let idea = CategorizedIdea(title: "T", description: "D", isSpeculative: false)
        XCTAssertFalse(idea.isSpeculative)
    }

    func testInitStoresIsSpeculativeTrue() {
        let idea = CategorizedIdea(title: "T", description: "D", isSpeculative: true)
        XCTAssertTrue(idea.isSpeculative)
    }

    func testDoesNotHaveIdProperty() {
        // CategorizedIdea no longer has an id property; this test confirms
        // it compiles and works without one.
        let idea = CategorizedIdea(title: "Check", description: "No id here", isSpeculative: false)
        // Mirror to confirm no "id" property
        let mirror = Mirror(reflecting: idea)
        let hasId = mirror.children.contains { $0.label == "id" }
        XCTAssertFalse(hasId, "CategorizedIdea should not have an id property after PR changes")
    }

    func testCodableRoundTrip() throws {
        let original = CategorizedIdea(title: "Foreshadowing Device", description: "A subtle hint at the ending", isSpeculative: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.isSpeculative, original.isSpeculative)
    }

    func testCodableRoundTripSpeculativeIdea() throws {
        let original = CategorizedIdea(title: "Alternate Timeline", description: "What if the war never happened?", isSpeculative: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)
        XCTAssertTrue(decoded.isSpeculative)
    }

    func testCodableRoundTripNonSpeculativeIdea() throws {
        let original = CategorizedIdea(title: "Established Lore", description: "Dragons existed 1000 years ago", isSpeculative: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)
        XCTAssertFalse(decoded.isSpeculative)
    }

    func testCodableEncodedJSONDoesNotContainIdKey() throws {
        let idea = CategorizedIdea(title: "No ID Idea", description: "Should not have id in JSON", isSpeculative: false)
        let data = try JSONEncoder().encode(idea)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["id"], "CategorizedIdea JSON should not contain an 'id' key")
    }

    func testCodableWithEmptyTitle() throws {
        let original = CategorizedIdea(title: "", description: "Some description", isSpeculative: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)
        XCTAssertEqual(decoded.title, "")
    }

    func testCodableWithEmptyDescription() throws {
        let original = CategorizedIdea(title: "Title", description: "", isSpeculative: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CategorizedIdea.self, from: data)
        XCTAssertEqual(decoded.description, "")
    }
}

// MARK: - IdeaCategory Tests
// Tests for the updated IdeaCategory struct which no longer conforms to Identifiable
// and no longer has a UUID id property (removed in this PR).

final class IdeaCategoryBrainstormTests: XCTestCase {

    func testInitStoresName() {
        let category = IdeaCategory(name: "Plot Ideas", description: "Story arc suggestions", ideas: [])
        XCTAssertEqual(category.name, "Plot Ideas")
    }

    func testInitStoresDescription() {
        let category = IdeaCategory(name: "N", description: "Detailed explanation of this category", ideas: [])
        XCTAssertEqual(category.description, "Detailed explanation of this category")
    }

    func testInitStoresIdeas() {
        let idea1 = CategorizedIdea(title: "Idea 1", description: "D1", isSpeculative: false)
        let idea2 = CategorizedIdea(title: "Idea 2", description: "D2", isSpeculative: true)
        let category = IdeaCategory(name: "Mixed", description: "Mixed speculative", ideas: [idea1, idea2])
        XCTAssertEqual(category.ideas.count, 2)
        XCTAssertEqual(category.ideas[0].title, "Idea 1")
        XCTAssertEqual(category.ideas[1].title, "Idea 2")
    }

    func testInitWithEmptyIdeas() {
        let category = IdeaCategory(name: "Empty", description: "No ideas yet", ideas: [])
        XCTAssertTrue(category.ideas.isEmpty)
    }

    func testDoesNotHaveIdProperty() {
        let category = IdeaCategory(name: "Check", description: "No id here", ideas: [])
        let mirror = Mirror(reflecting: category)
        let hasId = mirror.children.contains { $0.label == "id" }
        XCTAssertFalse(hasId, "IdeaCategory should not have an id property after PR changes")
    }

    func testCodableRoundTrip() throws {
        let idea = CategorizedIdea(title: "Subplot twist", description: "Villain was a mentor", isSpeculative: false)
        let original = IdeaCategory(name: "Twists", description: "Unexpected story turns", ideas: [idea])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IdeaCategory.self, from: data)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.ideas.count, 1)
        XCTAssertEqual(decoded.ideas[0].title, idea.title)
    }

    func testCodableRoundTripWithMultipleIdeas() throws {
        let ideas = [
            CategorizedIdea(title: "A", description: "Alpha", isSpeculative: false),
            CategorizedIdea(title: "B", description: "Beta", isSpeculative: true),
            CategorizedIdea(title: "C", description: "Gamma", isSpeculative: false)
        ]
        let original = IdeaCategory(name: "Alphabet", description: "Letter ideas", ideas: ideas)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IdeaCategory.self, from: data)
        XCTAssertEqual(decoded.ideas.count, 3)
        XCTAssertEqual(decoded.ideas[1].isSpeculative, true)
    }

    func testCodableEncodedJSONDoesNotContainIdKey() throws {
        let category = IdeaCategory(name: "Test", description: "Test category", ideas: [])
        let data = try JSONEncoder().encode(category)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["id"], "IdeaCategory JSON should not contain an 'id' key")
    }
}

// MARK: - BrainstormResult Tests
// Tests for the updated BrainstormResult struct which no longer conforms to Identifiable
// and no longer has a UUID id property (removed in this PR).

final class BrainstormResultCodableTests: XCTestCase {

    func testInitStoresCategories() {
        let cat1 = IdeaCategory(name: "Plot", description: "Plot ideas", ideas: [])
        let cat2 = IdeaCategory(name: "Character", description: "Character ideas", ideas: [])
        let result = BrainstormResult(categories: [cat1, cat2])
        XCTAssertEqual(result.categories.count, 2)
    }

    func testInitWithEmptyCategories() {
        let result = BrainstormResult(categories: [])
        XCTAssertTrue(result.categories.isEmpty)
    }

    func testDoesNotHaveIdProperty() {
        let result = BrainstormResult(categories: [])
        let mirror = Mirror(reflecting: result)
        let hasId = mirror.children.contains { $0.label == "id" }
        XCTAssertFalse(hasId, "BrainstormResult should not have an id property after PR changes")
    }

    func testCodableRoundTrip() throws {
        let idea = CategorizedIdea(title: "The Twist", description: "Character was dead all along", isSpeculative: true)
        let category = IdeaCategory(name: "Thriller Twists", description: "Shock value moments", ideas: [idea])
        let original = BrainstormResult(categories: [category])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertEqual(decoded.categories.count, 1)
        XCTAssertEqual(decoded.categories[0].name, "Thriller Twists")
        XCTAssertEqual(decoded.categories[0].ideas[0].title, "The Twist")
        XCTAssertTrue(decoded.categories[0].ideas[0].isSpeculative)
    }

    func testCodableRoundTripWithMultipleCategories() throws {
        let categories = [
            IdeaCategory(name: "Plot", description: "P", ideas: [
                CategorizedIdea(title: "P1", description: "Plot idea 1", isSpeculative: false)
            ]),
            IdeaCategory(name: "Theme", description: "T", ideas: [
                CategorizedIdea(title: "T1", description: "Theme idea 1", isSpeculative: true),
                CategorizedIdea(title: "T2", description: "Theme idea 2", isSpeculative: false)
            ]),
            IdeaCategory(name: "Character", description: "C", ideas: [])
        ]
        let original = BrainstormResult(categories: categories)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertEqual(decoded.categories.count, 3)
        XCTAssertEqual(decoded.categories[1].ideas.count, 2)
        XCTAssertTrue(decoded.categories[1].ideas[0].isSpeculative)
        XCTAssertTrue(decoded.categories[2].ideas.isEmpty)
    }

    func testCodableEncodedJSONDoesNotContainIdKey() throws {
        let result = BrainstormResult(categories: [])
        let data = try JSONEncoder().encode(result)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNil(json?["id"], "BrainstormResult JSON should not contain an 'id' key")
    }

    func testCodablePreservesNestedIdeaSpeculativeFlag() throws {
        let ideas = [
            CategorizedIdea(title: "Safe", description: "Established fact", isSpeculative: false),
            CategorizedIdea(title: "Risky", description: "Wild guess", isSpeculative: true)
        ]
        let result = BrainstormResult(categories: [
            IdeaCategory(name: "Mixed", description: "Mix", ideas: ideas)
        ])
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertFalse(decoded.categories[0].ideas[0].isSpeculative)
        XCTAssertTrue(decoded.categories[0].ideas[1].isSpeculative)
    }

    // Boundary: single category with single idea
    func testSingleCategorySingleIdea() throws {
        let idea = CategorizedIdea(title: "Only Idea", description: "The one", isSpeculative: false)
        let result = BrainstormResult(categories: [
            IdeaCategory(name: "Solo", description: "One idea only", ideas: [idea])
        ])
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(BrainstormResult.self, from: data)
        XCTAssertEqual(decoded.categories.count, 1)
        XCTAssertEqual(decoded.categories[0].ideas.count, 1)
        XCTAssertEqual(decoded.categories[0].ideas[0].title, "Only Idea")
    }
}