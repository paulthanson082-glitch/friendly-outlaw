import Foundation
import WritersApp

// MARK: - CLI Application

// Global productivity managers
var focusManager = FocusSessionManager()
var goalManager = WritingGoalManager()
var analyticsService: ProductivityAnalytics!

@main
struct WritersAppCLI {
    static func main() async {
        let app = WritersApp()
        analyticsService = ProductivityAnalytics(focusManager: focusManager, goalManager: goalManager)

        // Parse command-line arguments
        let arguments = CommandLine.arguments
        
        // Handle command-line arguments
        if arguments.count > 1 {
            let command = arguments[1]
            
            switch command {
            case "--help", "-h":
                showHelp()
                return
            case "--list", "-l":
                listDocuments(app: app)
                return
            case "--open", "-o":
                if arguments.count < 3 {
                    print("Error: --open requires a document ID or title")
                    print("Usage: WritersAppCLI --open <document-id-or-title>")
                    return
                }
                await openDocumentByIdOrTitle(app: app, searchTerm: arguments[2])
                return
            case "--run", "-r":
                if arguments.count < 3 {
                    print("Error: --run requires a menu option number")
                    print("Usage: WritersAppCLI --run <option-number>")
                    return
                }
                await runMenuOption(app: app, optionString: arguments[2])
                return
            default:
                print("Unknown option: \(command)")
                print("Use --help for usage information")
                return
            }
        }

        print("╔══════════════════════════════════════╗")
        print("║     Writers App with Templates       ║")
        print("║   Swift Edition - Productivity Plus  ║")
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
            print("8. Open Document")

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

            print("\nProductivity Features:")
            print("40. Start Focus Session")
            print("41. View Current Session")
            print("42. End Focus Session")
            print("43. Focus Session Stats")
            print("44. Set Daily Writing Goal")
            print("45. View Goals & Progress")
            print("46. Record Progress")
            print("47. View Writing Streak")
            print("48. Productivity Report")
            print("49. Productivity Insights")

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
            case 8:
                await openDocument(app: app)
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
            case 40:
                startFocusSession(app: app)
            case 41:
                viewCurrentSession()
            case 42:
                endFocusSession(app: app)
            case 43:
                viewFocusSessionStats()
            case 44:
                setDailyWritingGoal()
            case 45:
                viewGoalsAndProgress()
            case 46:
                recordProgress()
            case 47:
                viewWritingStreak()
            case 48:
                viewProductivityReport()
            case 49:
                viewProductivityInsights()
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

func openDocument(app: WritersApp) async {
    print("\n=== Open Document ===\n")
    
    let documents = app.documentManager.getAllDocuments()
    
    if documents.isEmpty {
        print("No documents found. Create one to get started!")
        return
    }
    
    // Display list of documents
    for (index, document) in documents.enumerated() {
        print("\(index + 1). \(document.title)")
        print("   Category: \(document.category.rawValue)")
        print("   Words: \(document.wordCount)")
        print()
    }
    
    print("Enter document number to open (0 to cancel): ", terminator: "")
    guard let input = readLine(), let choice = Int(input) else {
        print("Invalid input.")
        return
    }
    
    if choice == 0 {
        return
    }
    
    guard choice > 0 && choice <= documents.count else {
        print("Invalid document number.")
        return
    }
    
    let documentId = documents[choice - 1].id
    
    // Display document details
    var viewingDocument = true
    while viewingDocument {
        // Fetch the latest version of the document
        guard let document = app.documentManager.getDocument(id: documentId) else {
            print("Document not found.")
            return
        }
        
        // Update last opened date on first view
        if document.metadata.lastOpened == nil {
            var updatedDocument = document
            updatedDocument.metadata.lastOpened = Date()
            app.documentManager.updateDocument(updatedDocument)
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("Document: \(document.title)")
        print(String(repeating: "=", count: 60))
        print()
        print("Category: \(document.category.rawValue)")
        print("Created: \(formatDate(document.metadata.created))")
        print("Modified: \(formatDate(document.metadata.modified))")
        if let lastOpened = document.metadata.lastOpened {
            print("Last Opened: \(formatDate(lastOpened))")
        }
        print()
        print("Word Count: \(document.wordCount)")
        print("Character Count: \(document.characterCount)")
        print("Reading Time: \(document.readingTime) min")
        
        if let goal = document.metadata.wordCountGoal {
            let progress = Double(document.wordCount) / Double(goal) * 100.0
            print("Goal Progress: \(document.wordCount)/\(goal) words (\(String(format: "%.1f", progress))%)")
        }
        
        if !document.metadata.tags.isEmpty {
            print("Tags: \(document.metadata.tags.joined(separator: ", "))")
        }
        
        if !document.metadata.notes.isEmpty {
            print("Notes: \(document.metadata.notes)")
        }
        
        print()
        print(String(repeating: "-", count: 60))
        print("CONTENT:")
        print(String(repeating: "-", count: 60))
        print()
        
        if document.content.isEmpty {
            print("[Empty document - no content yet]")
        } else {
            print(document.content)
        }
        
        print()
        print(String(repeating: "=", count: 60))
        print()
        
        // Document action menu
        print("Document Actions:")
        print("1. Edit Content")
        print("2. Export Document")
        print("3. Update Title")
        print("4. Add/Update Tags")
        print("5. Add/Update Notes")
        print("6. Set Word Count Goal")
        
        if app.isAIEnabled {
            print("\nAI Actions:")
            print("10. Continue Writing (AI)")
            print("11. Improve Document (AI)")
            print("12. Generate Title Ideas (AI)")
            print("13. Analyze Document (AI)")
        }
        
        print("\n0. Back to Main Menu")
        print()
        print("Enter choice: ", terminator: "")
        
        guard let actionInput = readLine(), let action = Int(actionInput) else {
            print("Invalid input.")
            continue
        }
        
        switch action {
        case 0:
            viewingDocument = false
            
        case 1:
            await editDocumentContent(app: app, documentId: documentId)
            
        case 2:
            exportDocument(app: app, documentId: documentId)
            
        case 3:
            updateDocumentTitle(app: app, documentId: documentId)
            
        case 4:
            updateDocumentTags(app: app, documentId: documentId)
            
        case 5:
            updateDocumentNotes(app: app, documentId: documentId)
            
        case 6:
            setDocumentWordGoal(app: app, documentId: documentId)
            
        case 10:
            if app.isAIEnabled {
                await continueWritingForDocument(app: app, documentId: documentId)
            } else {
                print("AI features are not enabled.")
            }
            
        case 11:
            if app.isAIEnabled {
                await improveSpecificDocument(app: app, documentId: documentId)
            } else {
                print("AI features are not enabled.")
            }
            
        case 12:
            if app.isAIEnabled {
                await generateTitlesForDocument(app: app, documentId: documentId)
            } else {
                print("AI features are not enabled.")
            }
            
        case 13:
            if app.isAIEnabled {
                await analyzeSpecificDocument(app: app, documentId: documentId)
            } else {
                print("AI features are not enabled.")
            }
            
        default:
            print("Invalid choice.")
        }
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

// MARK: - Document Action Functions

func editDocumentContent(app: WritersApp, documentId: UUID) async {
    guard var document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Edit Document Content ===\n")
    print("Current content:")
    print(String(repeating: "-", count: 60))
    print(document.content.isEmpty ? "[Empty]" : document.content)
    print(String(repeating: "-", count: 60))
    print()
    print("Enter new content (type END on a new line when finished):")
    
    var lines: [String] = []
    while true {
        guard let line = readLine() else { break }
        if line == "END" {
            break
        }
        lines.append(line)
    }
    
    let newContent = lines.joined(separator: "\n")
    document.content = newContent
    document.metadata.modified = Date()
    app.documentManager.updateDocument(document)
    
    print("\n✓ Document content updated!")
    print("New word count: \(document.wordCount)")
}

func exportDocument(app: WritersApp, documentId: UUID) {
    print("\n=== Export Document ===\n")
    print("Select format:")
    print("1. Markdown")
    print("2. Plain Text")
    print("3. HTML")
    print()
    print("Enter choice: ", terminator: "")
    
    guard let input = readLine(), let choice = Int(input) else {
        print("Invalid input.")
        return
    }
    
    let format: ExportFormat
    let ext: String
    
    switch choice {
    case 1:
        format = .markdown
        ext = "md"
    case 2:
        format = .plainText
        ext = "txt"
    case 3:
        format = .html
        ext = "html"
    default:
        print("Invalid choice.")
        return
    }
    
    guard let content = app.exportDocument(id: documentId, format: format) else {
        print("Failed to export document.")
        return
    }
    
    guard let document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    let filename = document.title.replacingOccurrences(of: " ", with: "_") + "." + ext
    print("\nExported content:\n")
    print(String(repeating: "=", count: 60))
    print(content)
    print(String(repeating: "=", count: 60))
    print("\n✓ Document exported as: \(filename)")
}

func updateDocumentTitle(app: WritersApp, documentId: UUID) {
    guard var document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Update Title ===\n")
    print("Current title: \(document.title)")
    print("Enter new title: ", terminator: "")
    
    guard let newTitle = readLine(), !newTitle.isEmpty else {
        print("Invalid title.")
        return
    }
    
    document.title = newTitle
    document.metadata.modified = Date()
    app.documentManager.updateDocument(document)
    
    print("\n✓ Title updated!")
}

func updateDocumentTags(app: WritersApp, documentId: UUID) {
    guard var document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Update Tags ===\n")
    if !document.metadata.tags.isEmpty {
        print("Current tags: \(document.metadata.tags.joined(separator: ", "))")
    } else {
        print("No tags set.")
    }
    print("Enter tags (comma-separated): ", terminator: "")
    
    guard let input = readLine() else {
        print("Invalid input.")
        return
    }
    
    let tags = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    document.metadata.tags = tags
    document.metadata.modified = Date()
    app.documentManager.updateDocument(document)
    
    print("\n✓ Tags updated!")
}

func updateDocumentNotes(app: WritersApp, documentId: UUID) {
    guard var document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Update Notes ===\n")
    if !document.metadata.notes.isEmpty {
        print("Current notes: \(document.metadata.notes)")
    } else {
        print("No notes set.")
    }
    print("Enter notes: ", terminator: "")
    
    guard let notes = readLine() else {
        print("Invalid input.")
        return
    }
    
    document.metadata.notes = notes
    document.metadata.modified = Date()
    app.documentManager.updateDocument(document)
    
    print("\n✓ Notes updated!")
}

func setDocumentWordGoal(app: WritersApp, documentId: UUID) {
    guard var document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Set Word Count Goal ===\n")
    if let goal = document.metadata.wordCountGoal {
        print("Current goal: \(goal) words")
    } else {
        print("No goal set.")
    }
    print("Enter word count goal (0 to remove): ", terminator: "")
    
    guard let input = readLine(), let goal = Int(input) else {
        print("Invalid input.")
        return
    }
    
    document.metadata.wordCountGoal = goal > 0 ? goal : nil
    document.metadata.modified = Date()
    app.documentManager.updateDocument(document)
    
    print("\n✓ Word count goal updated!")
}

func continueWritingForDocument(app: WritersApp, documentId: UUID) async {
    guard let document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Continue Writing (AI) ===\n")
    
    if document.content.isEmpty {
        print("Document is empty. Please add some content first.")
        return
    }
    
    print("Generating continuation...")
    
    do {
        let continuation = try await app.continueDocument(documentId: documentId, appendToDocument: true)
        print("\n✓ AI-generated continuation added to document!\n")
        print("Added text:")
        print(String(repeating: "-", count: 60))
        print(continuation)
        print(String(repeating: "-", count: 60))
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func improveSpecificDocument(app: WritersApp, documentId: UUID) async {
    guard let document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Improve Document (AI) ===\n")
    
    if document.content.isEmpty {
        print("Document is empty. Please add some content first.")
        return
    }
    
    print("Analyzing and improving document...")
    
    do {
        let improved = try await app.improveDocument(documentId: documentId, replaceContent: false)
        print("\n✓ Improved version:\n")
        print(String(repeating: "=", count: 60))
        print(improved)
        print(String(repeating: "=", count: 60))
        print()
        print("Apply improvements? (y/n): ", terminator: "")
        
        if let response = readLine()?.lowercased(), response == "y" || response == "yes" {
            _ = try await app.improveDocument(documentId: documentId, replaceContent: true)
            print("\n✓ Improvements applied to document!")
        }
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func generateTitlesForDocument(app: WritersApp, documentId: UUID) async {
    guard let document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Generate Title Ideas (AI) ===\n")
    
    if document.content.isEmpty {
        print("Document is empty. Please add some content first.")
        return
    }
    
    print("Generating title suggestions...")
    
    do {
        let titles = try await app.generateDocumentTitles(documentId: documentId)
        print("\n✓ Title suggestions:\n")
        print(titles)
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
}

func analyzeSpecificDocument(app: WritersApp, documentId: UUID) async {
    guard let document = app.documentManager.getDocument(id: documentId) else {
        print("Document not found.")
        return
    }
    
    print("\n=== Analyze Document (AI) ===\n")
    
    if document.content.isEmpty {
        print("Document is empty. Please add some content first.")
        return
    }
    
    print("Analyzing document...")
    
    do {
        let analysis = try await app.analyzeDocument(documentId: documentId)
        print("\n✓ Analysis:\n")
        print(String(repeating: "=", count: 60))
        print(analysis.analysis)
        print(String(repeating: "=", count: 60))
    } catch {
        print("\n✗ Error: \(error.localizedDescription)")
    }
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

// MARK: - Productivity Features

func startFocusSession(app: WritersApp) {
    print("\n=== Start Focus Session ===\n")

    print("Select session type:")
    for (index, sessionType) in FocusSessionType.allCases.enumerated() {
        let duration = sessionType.defaultDuration > 0 ? " (\(Int(sessionType.defaultDuration / 60)) min)" : " (no time limit)"
        print("\(index + 1). \(sessionType.displayName)\(duration)")
    }

    print("\nSession type: ", terminator: "")
    guard let input = readLine(),
          let typeIndex = Int(input),
          typeIndex > 0,
          typeIndex <= FocusSessionType.allCases.count else {
        print("Invalid selection.")
        return
    }

    let sessionType = FocusSessionType.allCases[typeIndex - 1]

    // Optionally link to a document
    var documentId: UUID? = nil
    var currentWordCount = 0

    let documents = app.documentManager.getAllDocuments()
    if !documents.isEmpty {
        print("\nLink to a document? (y/n): ", terminator: "")
        if readLine()?.lowercased() == "y" {
            print("\nSelect document:")
            for (index, doc) in documents.enumerated() {
                print("\(index + 1). \(doc.title) (\(doc.wordCount) words)")
            }
            print("\nDocument number: ", terminator: "")
            if let docInput = readLine(),
               let docIndex = Int(docInput),
               docIndex > 0,
               docIndex <= documents.count {
                let doc = documents[docIndex - 1]
                documentId = doc.id
                currentWordCount = doc.wordCount
            }
        }
    }

    let session = focusManager.startSession(
        type: sessionType,
        documentId: documentId,
        currentWordCount: currentWordCount
    )

    print("\n✓ Focus session started!")
    print("  Type: \(session.type.displayName)")
    if session.targetDuration > 0 {
        print("  Duration: \(FocusSessionManager.formatTimeRemaining(session.targetDuration))")
    }
    if documentId != nil {
        print("  Linked document: Yes")
    }
    print("\nHappy writing! Use option 42 to end your session.\n")
}

func viewCurrentSession() {
    print("\n=== Current Focus Session ===\n")

    guard let session = focusManager.getCurrentSession() else {
        print("No active focus session.")
        print("Start one with option 40!")
        return
    }

    print("Type: \(session.type.displayName)")
    print("State: \(session.state.rawValue)")
    print("Started: \(formatDate(session.startTime))")
    print("Duration: \(FocusSessionManager.formatDuration(session.actualDuration))")

    if session.targetDuration > 0 {
        print("Time remaining: \(FocusSessionManager.formatTimeRemaining(session.timeRemaining))")
        print("Progress: \(Int(session.progress * 100))%")
    }

    if session.documentId != nil {
        print("Document linked: Yes")
        print("Words at start: \(session.wordsAtStart)")
    }
    print()
}

func endFocusSession(app: WritersApp) {
    print("\n=== End Focus Session ===\n")

    guard let session = focusManager.getCurrentSession() else {
        print("No active focus session to end.")
        return
    }

    var finalWordCount = session.wordsAtStart

    // If linked to document, get current word count
    if let docId = session.documentId,
       let doc = app.documentManager.getDocument(id: docId) {
        finalWordCount = doc.wordCount
    } else {
        print("Enter final word count (or press Enter to skip): ", terminator: "")
        if let input = readLine(), let count = Int(input) {
            finalWordCount = count
        }
    }

    guard let endedSession = focusManager.endSession(
        id: session.id,
        finalWordCount: finalWordCount,
        completed: true
    ) else {
        print("Failed to end session.")
        return
    }

    // Record progress toward daily goals
    if endedSession.wordsWritten > 0 {
        for goal in goalManager.getDailyGoals() {
            if goal.unit == .words {
                _ = goalManager.recordProgress(goalId: goal.id, amount: endedSession.wordsWritten)
            }
        }
        analyticsService.recordWordCount(documentId: session.documentId ?? UUID(), wordCount: finalWordCount)
    }

    print("\n✓ Focus session completed!")
    print("\nSession Summary:")
    print("  Duration: \(FocusSessionManager.formatDuration(endedSession.actualDuration))")
    print("  Words written: \(endedSession.wordsWritten)")
    if endedSession.actualDuration > 60 {
        print("  Words/minute: \(String(format: "%.1f", endedSession.wordsPerMinute))")
    }

    if endedSession.type == .pomodoro {
        print("  Pomodoros completed: \(endedSession.completedPomodoros + 1)")
    }
    print()
}

func viewFocusSessionStats() {
    print("\n=== Focus Session Statistics ===\n")

    let stats = focusManager.getStats()

    print("Overall Stats:")
    print("  Total sessions: \(stats.totalSessions)")
    print("  Completed sessions: \(stats.completedSessions)")
    print("  Completion rate: \(String(format: "%.1f", stats.completionRate))%")
    print("  Total focus time: \(FocusSessionManager.formatDuration(stats.totalFocusTime))")
    print("  Total words written: \(stats.totalWordsWritten)")
    print("  Average words/minute: \(String(format: "%.1f", stats.averageWordsPerMinute))")
    print("  Pomodoros completed: \(stats.pomodorosCompleted)")

    if let favorite = stats.favoriteSessionType {
        print("  Favorite session type: \(favorite.displayName)")
    }

    print("\nToday's Stats:")
    let todayStats = focusManager.getTodayStats()
    print("  Sessions: \(todayStats.totalSessions)")
    print("  Focus time: \(FocusSessionManager.formatDuration(todayStats.totalFocusTime))")
    print("  Words written: \(todayStats.totalWordsWritten)")
    print()
}

func setDailyWritingGoal() {
    print("\n=== Set Daily Writing Goal ===\n")

    print("Enter daily word count target: ", terminator: "")
    guard let input = readLine(), let target = Int(input), target > 0 else {
        print("Invalid target. Please enter a positive number.")
        return
    }

    print("Enter goal name (or press Enter for default): ", terminator: "")
    let nameInput = readLine() ?? ""
    let name = nameInput.isEmpty ? "Daily Writing Goal" : nameInput

    let goal = goalManager.createDailyWordGoal(target: target, name: name)

    print("\n✓ Daily goal created!")
    print("  Name: \(goal.name)")
    print("  Target: \(goal.target) words")
    print("  Resets at midnight")
    print()
}

func viewGoalsAndProgress() {
    print("\n=== Goals & Progress ===\n")

    let goals = goalManager.getAllGoals()

    if goals.isEmpty {
        print("No goals set. Create one with option 44!")
        return
    }

    for (index, goal) in goals.enumerated() {
        let status = goal.isAchieved ? "ACHIEVED" : (goal.isActive ? "Active" : "Inactive")
        let progressBar = generateProgressBar(goal.progress)

        print("\(index + 1). \(goal.name) [\(status)]")
        print("   Type: \(goal.type.displayName)")
        print("   Progress: \(goal.current)/\(goal.target) \(goal.unit.displayName.lowercased())")
        print("   \(progressBar) \(goal.progressPercentage)%")

        if let daysLeft = goal.daysRemaining {
            print("   Days remaining: \(daysLeft)")
            if let dailyRequired = goal.requiredDailyProgress {
                print("   Required daily: \(dailyRequired) \(goal.unit.displayName.lowercased())")
            }
        }
        print()
    }
}

func recordProgress() {
    print("\n=== Record Progress ===\n")

    let goals = goalManager.getActiveGoals()

    if goals.isEmpty {
        print("No active goals. Create one with option 44!")
        return
    }

    print("Select goal:")
    for (index, goal) in goals.enumerated() {
        print("\(index + 1). \(goal.name) (\(goal.current)/\(goal.target) \(goal.unit.displayName.lowercased()))")
    }

    print("\nGoal number: ", terminator: "")
    guard let input = readLine(),
          let goalIndex = Int(input),
          goalIndex > 0,
          goalIndex <= goals.count else {
        print("Invalid selection.")
        return
    }

    let goal = goals[goalIndex - 1]

    print("Enter progress amount: ", terminator: "")
    guard let amountInput = readLine(), let amount = Int(amountInput), amount > 0 else {
        print("Invalid amount.")
        return
    }

    if let updatedGoal = goalManager.recordProgress(goalId: goal.id, amount: amount) {
        print("\n✓ Progress recorded!")
        print("  New total: \(updatedGoal.current)/\(updatedGoal.target)")
        print("  Progress: \(updatedGoal.progressPercentage)%")

        if updatedGoal.isAchieved {
            print("\n  Congratulations! Goal achieved!")
        }
    }
    print()
}

func viewWritingStreak() {
    print("\n=== Writing Streak ===\n")

    goalManager.checkStreakStatus()
    let streak = goalManager.getStreak()

    if streak.currentStreak == 0 && streak.totalDaysWritten == 0 {
        print("No writing streak yet.")
        print("Start writing to build your streak!")
        return
    }

    print("Current streak: \(streak.currentStreak) day(s)")
    print("Longest streak: \(streak.longestStreak) day(s)")
    print("Total days written: \(streak.totalDaysWritten)")

    if let lastDate = streak.lastWritingDate {
        print("Last writing: \(formatDate(lastDate))")
    }

    if streak.wroteToday {
        print("\nYou've written today! Keep it up!")
    } else if streak.isStreakActive {
        print("\nWrite today to maintain your streak!")
    } else {
        print("\nStart a new streak today!")
    }
    print()
}

func viewProductivityReport() {
    print("\n=== Productivity Report ===\n")

    print("Select time period:")
    print("1. Today")
    print("2. This Week")
    print("3. This Month")
    print("4. All Time")

    print("\nPeriod: ", terminator: "")
    guard let input = readLine(), let option = Int(input) else {
        print("Invalid selection.")
        return
    }

    let period: AnalyticsPeriod
    switch option {
    case 1: period = .today
    case 2: period = .thisWeek
    case 3: period = .thisMonth
    case 4: period = .allTime
    default:
        print("Invalid selection.")
        return
    }

    let report = analyticsService.generateReport(for: period)

    print("\n\(period.displayName) Report:")
    print("─────────────────────────────")
    print("Total words: \(report.totalWords)")
    print("Total sessions: \(report.totalSessions)")
    print("Focus time: \(FocusSessionManager.formatDuration(report.totalFocusMinutes * 60))")
    print("Avg words/day: \(String(format: "%.0f", report.averageWordsPerDay))")
    print("Avg words/session: \(String(format: "%.0f", report.averageWordsPerSession))")
    print("Avg session length: \(String(format: "%.0f", report.averageSessionLength)) min")

    if let peakHour = report.peakHour {
        print("Peak writing hour: \(formatHour(peakHour))")
    }

    print()
}

func viewProductivityInsights() {
    print("\n=== Productivity Insights ===\n")

    let insights = analyticsService.generateInsights()

    if insights.isEmpty {
        print("Not enough data for insights yet.")
        print("Complete more focus sessions to get personalized recommendations!")
        return
    }

    for (index, insight) in insights.enumerated() {
        let icon: String
        switch insight.type {
        case .peakTime: icon = "🕐"
        case .streak: icon = "🔥"
        case .improvement: icon = "📈"
        case .goalProgress: icon = "🎯"
        case .suggestion: icon = "💡"
        case .warning: icon = "⚠️"
        case .achievement: icon = "🏆"
        }

        print("\(index + 1). \(icon) \(insight.title)")
        print("   \(insight.message)")
        print()
    }
}

// MARK: - Helper Functions for Productivity

func generateProgressBar(_ progress: Double, width: Int = 20) -> String {
    let filled = Int(progress * Double(width))
    let empty = width - filled
    return "[" + String(repeating: "█", count: filled) + String(repeating: "░", count: empty) + "]"
}

func formatHour(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    var components = DateComponents()
    components.hour = hour
    if let date = Calendar.current.date(from: components) {
        return formatter.string(from: date)
    }
    return "\(hour):00"
}

// MARK: - Command-Line Argument Handlers

// Constants for formatting
private let uuidDisplayLength = 8
private let titleColumnWidth = 24
private let categoryColumnWidth = 13

func showHelp() {
    print("""
    Writers App CLI - Command-Line Interface

    USAGE:
        WritersAppCLI [OPTIONS]

    OPTIONS:
        --help, -h              Show this help message
        --list, -l              List all documents
        --open, -o <id|title>   Open a document by ID or title
        --run, -r <option>      Run a menu option non-interactively

    EXAMPLES:
        WritersAppCLI                              # Start interactive mode
        WritersAppCLI --list                       # List all documents
        WritersAppCLI --open "My Story"            # Open document by title
        WritersAppCLI --open <document-id>         # Open document by ID
        WritersAppCLI --run 5                      # View statistics
        WritersAppCLI --run 1                      # Browse templates

    MENU OPTIONS (for --run):
        1-8:   Document operations (browse, create, view, search)
        10-16: AI features (requires ANTHROPIC_API_KEY)
        20-25: Memory plugin features
        30:    List plugins
        40-49: Productivity features (focus sessions, goals, streaks)

    ENVIRONMENT VARIABLES:
        ANTHROPIC_API_KEY      Set this to enable AI features

    For interactive mode, run without arguments.
    """)
}

func listDocuments(app: WritersApp) {
    print("\n=== All Documents ===\n")
    
    let documents = app.documentManager.getAllDocuments()
    
    if documents.isEmpty {
        print("No documents found. Create one to get started!")
        return
    }
    
    // ID (8) + " | " (3) + Title (24) + " | " (3) + Category (13) + " | Words" (8) = ~59
    let headerSeparatorWidth = uuidDisplayLength + 3 + titleColumnWidth + 3 + categoryColumnWidth + 10
    
    print("ID       | Title                    | Category      | Words")
    print(String(repeating: "-", count: headerSeparatorWidth))
    
    for document in documents {
        let id = String(document.id.uuidString.prefix(uuidDisplayLength))
        let title = String(document.title.prefix(titleColumnWidth)).padding(toLength: titleColumnWidth, withPad: " ", startingAt: 0)
        let category = String(document.category.rawValue.prefix(categoryColumnWidth)).padding(toLength: categoryColumnWidth, withPad: " ", startingAt: 0)
        print("\(id) | \(title) | \(category) | \(document.wordCount)")
    }
    
    print()
}

func openDocumentByIdOrTitle(app: WritersApp, searchTerm: String) async {
    let documents = app.documentManager.getAllDocuments()
    
    if documents.isEmpty {
        print("No documents found. Create one to get started!")
        return
    }
    
    // Try to find by ID first
    if let uuid = UUID(uuidString: searchTerm) {
        if let document = app.documentManager.getDocument(id: uuid) {
            await displayDocument(app: app, document: document)
            return
        }
    }
    
    // Try to find by exact title match
    if let document = documents.first(where: { $0.title.lowercased() == searchTerm.lowercased() }) {
        await displayDocument(app: app, document: document)
        return
    }
    
    // Try to find by partial title match
    let matches = documents.filter { $0.title.lowercased().contains(searchTerm.lowercased()) }
    
    if matches.isEmpty {
        print("No document found matching: \(searchTerm)")
        print("Use --list to see all documents")
        return
    }
    
    if matches.count == 1 {
        await displayDocument(app: app, document: matches[0])
        return
    }
    
    // Multiple matches found
    print("Multiple documents found matching '\(searchTerm)':\n")
    for (index, document) in matches.enumerated() {
        print("\(index + 1). \(document.title) (ID: \(String(document.id.uuidString.prefix(uuidDisplayLength))))")
    }
    print("\nPlease use a more specific title or document ID.")
}

func runMenuOption(app: WritersApp, optionString: String) async {
    guard let option = Int(optionString) else {
        print("Error: Invalid option number '\(optionString)'")
        print("Option must be a valid menu number")
        return
    }
    
    // Check if API key is needed for this option
    if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
        let config = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
        app.enableAI(configuration: config)
    }
    
    // Initialize memory plugin if needed
    do {
        try await app.enableMemoryPlugin()
    } catch {
        // Silently fail if memory plugin not available
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
    case 8:
        await openDocument(app: app)
    case 10:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await continueWritingWithAI(app: app)
    case 11:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await improveDocumentWithAI(app: app)
    case 12:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await generateTitlesWithAI(app: app)
    case 13:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await analyzeDocumentWithAI(app: app)
    case 14:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await brainstormIdeasWithAI(app: app)
    case 15:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await developCharacterWithAI(app: app)
    case 16:
        if !app.isAIEnabled {
            print("Error: AI features are not enabled. Set ANTHROPIC_API_KEY environment variable.")
            return
        }
        await generateOutlineWithAI(app: app)
    case 20:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await storeMemory(app: app)
    case 21:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await retrieveMemory(app: app)
    case 22:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await searchMemories(app: app)
    case 23:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await listMemories(app: app)
    case 24:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await clearMemory(app: app)
    case 25:
        if !app.isMemoryPluginEnabled {
            print("Error: Memory plugin is not enabled.")
            return
        }
        await viewMemoryStats(app: app)
    case 30:
        listPlugins(app: app)
    case 40:
        startFocusSession(app: app)
    case 41:
        viewCurrentSession()
    case 42:
        endFocusSession(app: app)
    case 43:
        viewFocusSessionStats()
    case 44:
        setDailyWritingGoal()
    case 45:
        viewGoalsAndProgress()
    case 46:
        recordProgress()
    case 47:
        viewWritingStreak()
    case 48:
        viewProductivityReport()
    case 49:
        viewProductivityInsights()
    default:
        print("Error: Invalid menu option '\(option)'")
        print("Use --help to see available options")
    }
    
    // Shutdown plugins before exit
    await app.shutdownPlugins()
}

func displayDocument(app: WritersApp, document: Document) async {
    // Update last opened date
    var updatedDocument = document
    updatedDocument.metadata.lastOpened = Date()
    app.documentManager.updateDocument(updatedDocument)
    
    print("\n" + String(repeating: "=", count: 60))
    print("Document: \(document.title)")
    print(String(repeating: "=", count: 60))
    print()
    print("ID: \(document.id.uuidString)")
    print("Category: \(document.category.rawValue)")
    print("Created: \(formatDate(document.metadata.created))")
    print("Modified: \(formatDate(document.metadata.modified))")
    if let lastOpened = document.metadata.lastOpened {
        print("Last Opened: \(formatDate(lastOpened))")
    }
    print()
    print("Word Count: \(document.wordCount)")
    print("Character Count: \(document.characterCount)")
    print("Reading Time: \(document.readingTime) min")
    
    if let goal = document.metadata.wordCountGoal {
        let progress = Double(document.wordCount) / Double(goal) * 100.0
        print("Goal Progress: \(document.wordCount)/\(goal) words (\(String(format: "%.1f", progress))%)")
    }
    
    if !document.metadata.tags.isEmpty {
        print("Tags: \(document.metadata.tags.joined(separator: ", "))")
    }
    
    if !document.metadata.notes.isEmpty {
        print("Notes: \(document.metadata.notes)")
    }
    
    print()
    print(String(repeating: "-", count: 60))
    print("CONTENT:")
    print(String(repeating: "-", count: 60))
    print()
    
    if document.content.isEmpty {
        print("[Empty document - no content yet]")
    } else {
        print(document.content)
    }
    
    print()
    print(String(repeating: "=", count: 60))
    print()
}
