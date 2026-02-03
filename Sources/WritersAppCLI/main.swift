import Foundation
import WritersApp

// MARK: - CLI Application

@main
struct WritersAppCLI {
    static func main() async {
        var app = WritersApp()

        print("╔══════════════════════════════════════╗")
        print("║     Writers App with Templates       ║")
        print("║      Swift Edition with AI & Plugins ║")
        print("╚══════════════════════════════════════╝")
        print()

        // Check for API key in environment
        if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
            print("✓ AI features enabled (Claude API)")
            let config = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
            app.enableAI(configuration: config)
        } else {
            print("ⓘ AI features disabled (set ANTHROPIC_API_KEY to enable)")
        }

        // Initialize Claude Memory plugin
        do {
            try await app.enableMemoryPlugin()
            print("✓ Claude Memory plugin enabled\n")
        } catch {
            print("ⓘ Memory plugin initialization failed: \(error.localizedDescription)\n")
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

            if app.isMemoryPluginEnabled {
                print("\nMemory Plugin:")
                print("20. Store Memory")
                print("21. Retrieve Memory")
                print("22. Search Memories")
                print("23. List Memories")
                print("24. Clear Memory")
                print("25. Memory Statistics")
            }

            print("\nPlugin Management:")
            print("30. List Plugins")

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
            case 20:
                await storeMemory(app: app)
            case 21:
                await retrieveMemory(app: app)
            case 22:
                await searchMemories(app: app)
            case 23:
                await listMemories(app: app)
            case 24:
                await clearMemory(app: app)
            case 25:
                await viewMemoryStats(app: app)
            case 30:
                listPlugins(app: app)
            case 0:
                await app.shutdownPlugins()
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

// MARK: - Memory Plugin Functions

func storeMemory(app: WritersApp) async {
    print("\n=== Store Memory ===\n")

    print("Enter memory key: ", terminator: "")
    guard let key = readLine(), !key.isEmpty else {
        print("Key is required.")
        return
    }

    print("Enter memory value: ", terminator: "")
    guard let value = readLine(), !value.isEmpty else {
        print("Value is required.")
        return
    }

    print("Enter category (default: general): ", terminator: "")
    let categoryInput = readLine() ?? ""
    let category = categoryInput.isEmpty ? "general" : categoryInput

    print("Enter tags (comma-separated, optional): ", terminator: "")
    let tagsInput = readLine() ?? ""
    let tags = tagsInput.isEmpty ? [] : tagsInput.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

    print("Enter importance (0.0-1.0, default: 0.5): ", terminator: "")
    let importanceStr = readLine() ?? "0.5"
    let importance = Double(importanceStr) ?? 0.5

    do {
        try await app.storeMemory(key: key, value: value, category: category, tags: tags, importance: importance)
        print("\n✓ Memory stored successfully!")
        print("  Key: \(key)")
        print("  Category: \(category)")
        if !tags.isEmpty {
            print("  Tags: \(tags.joined(separator: ", "))")
        }
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func retrieveMemory(app: WritersApp) async {
    print("\n=== Retrieve Memory ===\n")

    print("Enter memory key: ", terminator: "")
    guard let key = readLine(), !key.isEmpty else {
        print("Key is required.")
        return
    }

    do {
        if let value = try await app.retrieveMemory(key: key) {
            print("\n✓ Memory found:")
            print("  Key: \(key)")
            print("  Value: \(value)")
            print()
        } else {
            print("\nMemory not found for key: \(key)")
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func searchMemories(app: WritersApp) async {
    print("\n=== Search Memories ===\n")

    print("Enter search query: ", terminator: "")
    guard let query = readLine(), !query.isEmpty else {
        print("Query is required.")
        return
    }

    print("Filter by category (optional, press Enter to skip): ", terminator: "")
    let categoryInput = readLine()
    let category: String? = categoryInput?.isEmpty == true ? nil : categoryInput

    do {
        let results = try await app.searchMemories(query: query, category: category, limit: 10)

        if results.isEmpty {
            print("\nNo memories found matching '\(query)'")
            return
        }

        print("\n✓ Found \(results.count) memory/memories:\n")
        for (index, result) in results.enumerated() {
            let key = result["key"] as? String ?? "unknown"
            let value = result["value"] as? String ?? ""
            let score = result["score"] as? Double ?? 0.0
            let memCategory = result["category"] as? String ?? "general"

            print("\(index + 1). \(key)")
            print("   Category: \(memCategory)")
            print("   Score: \(String(format: "%.2f", score))")
            print("   Value: \(value.prefix(100))\(value.count > 100 ? "..." : "")")
            print()
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func listMemories(app: WritersApp) async {
    print("\n=== List Memories ===\n")

    print("Filter by category (optional, press Enter to skip): ", terminator: "")
    let categoryInput = readLine()
    let category: String? = categoryInput?.isEmpty == true ? nil : categoryInput

    print("Sort by (created/accessed/importance, default: created): ", terminator: "")
    let sortByInput = readLine() ?? ""
    let sortBy = sortByInput.isEmpty ? "created" : sortByInput

    do {
        let memories = try await app.listMemories(category: category, limit: 50, sortBy: sortBy)

        if memories.isEmpty {
            print("\nNo memories found.")
            return
        }

        print("\n✓ Found \(memories.count) memory/memories:\n")
        for (index, memory) in memories.enumerated() {
            let key = memory["key"] as? String ?? "unknown"
            let memCategory = memory["category"] as? String ?? "general"
            let importance = memory["importance"] as? Double ?? 0.5
            let accessCount = memory["accessCount"] as? Int ?? 0
            let created = memory["created"] as? String ?? "unknown"

            print("\(index + 1). \(key)")
            print("   Category: \(memCategory)")
            print("   Importance: \(String(format: "%.1f", importance))")
            print("   Access Count: \(accessCount)")
            print("   Created: \(created)")
            print()
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func clearMemory(app: WritersApp) async {
    print("\n=== Clear Memory ===\n")

    print("Options:")
    print("1. Clear specific memory by key")
    print("2. Clear all memories in a category")
    print("3. Clear ALL memories")
    print("\nSelect option: ", terminator: "")

    guard let input = readLine(), let option = Int(input) else {
        print("Invalid input.")
        return
    }

    do {
        var cleared = 0

        switch option {
        case 1:
            print("Enter memory key to clear: ", terminator: "")
            guard let key = readLine(), !key.isEmpty else {
                print("Key is required.")
                return
            }
            cleared = try await app.clearMemory(key: key)

        case 2:
            print("Enter category to clear: ", terminator: "")
            guard let category = readLine(), !category.isEmpty else {
                print("Category is required.")
                return
            }
            cleared = try await app.clearMemory(category: category)

        case 3:
            print("Are you sure you want to clear ALL memories? (yes/no): ", terminator: "")
            guard readLine()?.lowercased() == "yes" else {
                print("Operation cancelled.")
                return
            }
            cleared = try await app.clearMemory()

        default:
            print("Invalid option.")
            return
        }

        print("\n✓ Cleared \(cleared) memory/memories.")
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func viewMemoryStats(app: WritersApp) async {
    print("\n=== Memory Statistics ===\n")

    do {
        let stats = try await app.getMemoryStats()

        let totalMemories = stats["totalMemories"] as? Int ?? 0
        let totalAccessCount = stats["totalAccessCount"] as? Int ?? 0
        let avgImportance = stats["averageImportance"] as? Double ?? 0.0
        let categoryCounts = stats["categoryCounts"] as? [String: Int] ?? [:]

        print("Total Memories: \(totalMemories)")
        print("Total Access Count: \(totalAccessCount)")
        print("Average Importance: \(String(format: "%.2f", avgImportance))")

        if !categoryCounts.isEmpty {
            print("\nMemories by Category:")
            for (category, count) in categoryCounts.sorted(by: { $0.value > $1.value }) {
                print("  \(category): \(count)")
            }
        }
        print()
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

// MARK: - Plugin Management

func listPlugins(app: WritersApp) {
    print("\n=== Installed Plugins ===\n")

    let plugins = app.getPlugins()

    if plugins.isEmpty {
        print("No plugins installed.")
        return
    }

    for (index, plugin) in plugins.enumerated() {
        print("\(index + 1). \(plugin.name) (v\(plugin.version))")
        print("   ID: \(plugin.id)")
        print("   Status: \(plugin.isEnabled ? "Enabled" : "Disabled")")
        print("   Description: \(plugin.description)")
        print("   Capabilities: \(plugin.capabilities.map { $0.rawValue }.joined(separator: ", "))")
        print()
    }
}
