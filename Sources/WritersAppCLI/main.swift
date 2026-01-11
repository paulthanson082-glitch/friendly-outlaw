import Foundation
import WritersApp

// MARK: - CLI Application

@main
struct WritersAppCLI {
    static func main() async {
        var app = WritersApp()

        print("╔══════════════════════════════════════╗")
        print("║     Writers App with Templates       ║")
        print("║        Swift Edition with AI         ║")
        print("╚══════════════════════════════════════╝")
        print()

        // Check for API key in environment
        if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
            print("✓ AI features enabled (Claude API)\n")
            let config = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
            app.enableAI(configuration: config)
        } else {
            print("ⓘ AI features disabled (set ANTHROPIC_API_KEY to enable)\n")
        }

        // Show menu
        var running = true
        while running {
            print("\nMain Menu:")
            print("1. Browse Templates")
            print("2. Create Document from Template")
            print("3. Create Blank Document")
            print("4. View All Documents")
            print("5. View Statistics")
            print("6. Search Templates")
            print("7. Search Documents")

            if app.isAIEnabled {
                print("\nAI Features:")
                print("10. Continue Writing (AI)")
                print("11. Improve Document (AI)")
                print("12. Generate Title Ideas (AI)")
                print("13. Analyze Document (AI)")
                print("14. Brainstorm Ideas (AI)")
                print("15. Develop Character (AI)")
                print("16. Generate Outline (AI)")
            }

            print("\n0. Exit")
            print()
            print("Enter choice: ", terminator: "")

            guard let choice = readLine(), let option = Int(choice) else {
                print("Invalid input. Please enter a number.")
                continue
            }

            switch option {
            case 1:
                browseTemplates(app: app)
            case 2:
                createDocumentFromTemplate(app: app)
            case 3:
                createBlankDocument(app: app)
            case 4:
                viewAllDocuments(app: app)
            case 5:
                viewStatistics(app: app)
            case 6:
                searchTemplates(app: app)
            case 7:
                searchDocuments(app: app)
            case 10:
                await continueWritingWithAI(app: app)
            case 11:
                await improveDocumentWithAI(app: app)
            case 12:
                await generateTitlesWithAI(app: app)
            case 13:
                await analyzeDocumentWithAI(app: app)
            case 14:
                await brainstormIdeasWithAI(app: app)
            case 15:
                await developCharacterWithAI(app: app)
            case 16:
                await generateOutlineWithAI(app: app)
            case 0:
                running = false
                print("\nThank you for using Writers App!")
            default:
                print("Invalid option. Please try again.")
            }
        }
    }
}

func browseTemplates(app: WritersApp) {
    print("\n=== Available Templates ===\n")
    let templates = app.templateManager.getAllTemplates()

    for (index, template) in templates.enumerated() {
        print("\(index + 1). \(template.name)")
        print("   Category: \(template.category.rawValue)")
        print("   Description: \(template.description)")
        print("   Placeholders: \(template.placeholders.count)")
        print()
    }
}

func createDocumentFromTemplate(app: WritersApp) {
    print("\n=== Create Document from Template ===\n")

    let templates = app.templateManager.getAllTemplates()
    for (index, template) in templates.enumerated() {
        print("\(index + 1). \(template.name)")
    }

    print("\nSelect template number: ", terminator: "")
    guard let input = readLine(),
          let templateIndex = Int(input),
          templateIndex > 0,
          templateIndex <= templates.count else {
        print("Invalid selection.")
        return
    }

    let template = templates[templateIndex - 1]
    print("\nTemplate: \(template.name)")
    print("Fill in the following placeholders:\n")

    var values: [String: String] = [:]

    for placeholder in template.placeholders {
        print("\(placeholder.label):", terminator: " ")
        if !placeholder.description.isEmpty {
            print("(\(placeholder.description))", terminator: " ")
        }
        if let defaultValue = placeholder.defaultValue {
            print("[default: \(defaultValue)]", terminator: " ")
        }
        print()

        if let value = readLine(), !value.isEmpty {
            values[placeholder.key] = value
        } else if let defaultValue = placeholder.defaultValue {
            values[placeholder.key] = defaultValue
        } else if placeholder.required {
            print("This field is required!")
            return
        }
    }

    if let document = app.createDocumentFromTemplate(templateId: template.id, values: values) {
        print("\n✓ Document created successfully!")
        print("Title: \(document.title)")
        print("Word Count: \(document.wordCount)")
        print("ID: \(document.id)")
    } else {
        print("\n✗ Failed to create document.")
    }
}

func createBlankDocument(app: WritersApp) {
    print("\n=== Create Blank Document ===\n")

    print("Enter title: ", terminator: "")
    guard let title = readLine(), !title.isEmpty else {
        print("Title is required.")
        return
    }

    print("\nSelect category:")
    for (index, category) in TemplateCategory.allCases.enumerated() {
        print("\(index + 1). \(category.rawValue)")
    }
    print("\nCategory number: ", terminator: "")

    guard let input = readLine(),
          let categoryIndex = Int(input),
          categoryIndex > 0,
          categoryIndex <= TemplateCategory.allCases.count else {
        print("Invalid selection.")
        return
    }

    let category = TemplateCategory.allCases[categoryIndex - 1]
    let document = app.createBlankDocument(title: title, category: category)

    print("\n✓ Blank document created!")
    print("Title: \(document.title)")
    print("Category: \(document.category.rawValue)")
    print("ID: \(document.id)")
}

func viewAllDocuments(app: WritersApp) {
    print("\n=== All Documents ===\n")

    let documents = app.documentManager.getAllDocuments()

    if documents.isEmpty {
        print("No documents found. Create one to get started!")
        return
    }

    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title)")
        print("   Category: \(document.category.rawValue)")
        print("   Words: \(document.wordCount)")
        print("   Modified: \(formatDate(document.metadata.modified))")
        print()
    }
}

func viewStatistics(app: WritersApp) {
    print("\n=== Application Statistics ===\n")

    let stats = app.getStatistics()

    print("Total Documents: \(stats.totalDocuments)")
    print("Total Word Count: \(stats.totalWordCount)")
    print("Average Words per Document: \(stats.averageWordCount)")
    print("Available Templates: \(stats.totalTemplates)")

    print("\nDocuments by Category:")
    for (category, count) in stats.documentsByCategory.sorted(by: { $0.value > $1.value }) {
        print("  \(category.rawValue): \(count)")
    }
    print()
}

func searchTemplates(app: WritersApp) {
    print("\n=== Search Templates ===\n")
    print("Enter search query: ", terminator: "")

    guard let query = readLine(), !query.isEmpty else {
        print("Search query cannot be empty.")
        return
    }

    let results = app.templateManager.searchTemplates(query: query)

    if results.isEmpty {
        print("\nNo templates found matching '\(query)'")
        return
    }

    print("\nFound \(results.count) template(s):\n")
    for (index, template) in results.enumerated() {
        print("\(index + 1). \(template.name)")
        print("   Category: \(template.category.rawValue)")
        print("   Description: \(template.description)")
        print()
    }
}

func searchDocuments(app: WritersApp) {
    print("\n=== Search Documents ===\n")
    print("Enter search query: ", terminator: "")

    guard let query = readLine(), !query.isEmpty else {
        print("Search query cannot be empty.")
        return
    }

    let results = app.documentManager.searchDocuments(query: query)

    if results.isEmpty {
        print("\nNo documents found matching '\(query)'")
        return
    }

    print("\nFound \(results.count) document(s):\n")
    for (index, document) in results.enumerated() {
        print("\(index + 1). \(document.title)")
        print("   Category: \(document.category.rawValue)")
        print("   Words: \(document.wordCount)")
        print()
    }
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

// MARK: - AI Features

func continueWritingWithAI(app: WritersApp) async {
    print("\n=== Continue Writing with AI ===\n")

    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available. Create one first!")
        return
    }

    print("Select document:")
    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title) (\(document.wordCount) words)")
    }

    print("\nDocument number: ", terminator: "")
    guard let input = readLine(),
          let docIndex = Int(input),
          docIndex > 0,
          docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }

    let document = documents[docIndex - 1]

    print("\nAppend to document? (y/n): ", terminator: "")
    let shouldAppend = readLine()?.lowercased() == "y"

    print("\n⏳ Generating continuation...")

    do {
        let continuation = try await app.continueDocument(
            documentId: document.id,
            appendToDocument: shouldAppend
        )
        print("\n✓ AI Generated Continuation:\n")
        print(continuation)
        print()

        if shouldAppend {
            print("✓ Content appended to document!")
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func improveDocumentWithAI(app: WritersApp) async {
    print("\n=== Improve Document with AI ===\n")

    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available. Create one first!")
        return
    }

    print("Select document:")
    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title) (\(document.wordCount) words)")
    }

    print("\nDocument number: ", terminator: "")
    guard let input = readLine(),
          let docIndex = Int(input),
          docIndex > 0,
          docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }

    let document = documents[docIndex - 1]

    print("\nReplace original content? (y/n): ", terminator: "")
    let shouldReplace = readLine()?.lowercased() == "y"

    print("\n⏳ Improving text...")

    do {
        let improved = try await app.improveDocument(
            documentId: document.id,
            replaceContent: shouldReplace
        )
        print("\n✓ AI Improved Version:\n")
        print(improved)
        print()

        if shouldReplace {
            print("✓ Document updated with improved version!")
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func generateTitlesWithAI(app: WritersApp) async {
    print("\n=== Generate Title Ideas with AI ===\n")

    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available. Create one first!")
        return
    }

    print("Select document:")
    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title) (\(document.wordCount) words)")
    }

    print("\nDocument number: ", terminator: "")
    guard let input = readLine(),
          let docIndex = Int(input),
          docIndex > 0,
          docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }

    let document = documents[docIndex - 1]

    print("\n⏳ Generating title ideas...")

    do {
        let titles = try await app.generateDocumentTitles(documentId: document.id)
        print("\n✓ Title Suggestions:\n")
        for (index, title) in titles.enumerated() {
            print("\(index + 1). \(title)")
        }
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func analyzeDocumentWithAI(app: WritersApp) async {
    print("\n=== Analyze Document with AI ===\n")

    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available. Create one first!")
        return
    }

    print("Select document:")
    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title) (\(document.wordCount) words)")
    }

    print("\nDocument number: ", terminator: "")
    guard let input = readLine(),
          let docIndex = Int(input),
          docIndex > 0,
          docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }

    let document = documents[docIndex - 1]

    print("\n⏳ Analyzing document...")

    do {
        let analysis = try await app.analyzeDocument(documentId: document.id)
        print("\n✓ Document Analysis:\n")
        print(analysis.analysis)
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func brainstormIdeasWithAI(app: WritersApp) async {
    print("\n=== Brainstorm Ideas with AI ===\n")

    print("Enter topic or concept: ", terminator: "")
    guard let topic = readLine(), !topic.isEmpty else {
        print("Topic is required.")
        return
    }

    print("\n⏳ Brainstorming ideas...")

    do {
        let ideas = try await app.brainstormIdeas(topic: topic)
        print("\n✓ Ideas:\n")
        print(ideas)
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func developCharacterWithAI(app: WritersApp) async {
    print("\n=== Develop Character with AI ===\n")

    print("Enter character concept or description: ", terminator: "")
    guard let concept = readLine(), !concept.isEmpty else {
        print("Character concept is required.")
        return
    }

    print("\n⏳ Developing character...")

    do {
        let development = try await app.developCharacter(characterConcept: concept)
        print("\n✓ Character Development:\n")
        print(development)
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func generateOutlineWithAI(app: WritersApp) async {
    print("\n=== Generate Outline with AI ===\n")

    print("Enter story or article concept: ", terminator: "")
    guard let concept = readLine(), !concept.isEmpty else {
        print("Concept is required.")
        return
    }

    print("\n⏳ Generating outline...")

    do {
        let outline = try await app.generateOutline(concept: concept)
        print("\n✓ Outline:\n")
        print(outline)
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}
