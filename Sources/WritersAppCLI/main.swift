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

            print("\nHardware Boards:")
            print("80. Add Hardware Board")
            print("81. List Hardware Boards")
            print("82. View Board Details")
            print("83. Remove Hardware Board")
            print("84. Manage Pin Aliases")
            print("85. View Board Statistics")

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
            case 80:
                addHardwareBoard(app: app)
            case 81:
                listHardwareBoards(app: app)
            case 82:
                viewBoardDetails(app: app)
            case 83:
                removeHardwareBoard(app: app)
            case 84:
                managePinAliases(app: app)
            case 85:
                viewHardwareStatistics(app: app)
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

// MARK: - Hardware Board Functions

func addHardwareBoard(app: WritersApp) {
    print("\nAdd Hardware Board")
    print("==================")

    print("Board name: ", terminator: "")
    guard let name = readLine(), !name.isEmpty else {
        print("Board name is required")
        return
    }

    print("\nSelect board type:")
    let types = BoardType.allCases
    for (index, type) in types.enumerated() {
        print("\(index + 1). \(type.rawValue)")
    }
    print("Choice: ", terminator: "")

    guard let typeStr = readLine(), let typeIndex = Int(typeStr),
          typeIndex > 0, typeIndex <= types.count else {
        print("Invalid choice")
        return
    }

    let boardType = types[typeIndex - 1]

    print("Description (optional): ", terminator: "")
    let description = readLine() ?? ""

    print("Serial port (e.g., /dev/ttyUSB0, COM3) [optional]: ", terminator: "")
    let serialPortInput = readLine() ?? ""
    let serialPort = serialPortInput.isEmpty ? nil : serialPortInput

    print("Baud rate [9600]: ", terminator: "")
    let baudInput = readLine() ?? ""
    let baudRate = Int(baudInput) ?? 9600

    do {
        let board = try app.createHardwareBoard(
            name: name,
            type: boardType,
            description: description,
            serialPort: serialPort,
            baudRate: baudRate
        )
        print("\n✓ Board created successfully!")
        print("Board ID: \(board.id.uuidString)")
    } catch {
        print("Error creating board: \(error.localizedDescription)")
    }
}

func listHardwareBoards(app: WritersApp) {
    print("\nHardware Boards")
    print("===============")

    let boards = app.hardwareManager.getAllBoards()
    if boards.isEmpty {
        print("No boards configured")
        return
    }

    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
        print("   Type: \(board.boardType.rawValue)")
        if let port = board.serialPort {
            print("   Port: \(port) @ \(board.baudRate) baud")
        }
        print("   Pins: \(board.pinAliases.count) aliases")
        print("   Status: \(board.metadata.isActive ? "Active" : "Inactive")")
        print()
    }
}

func viewBoardDetails(app: WritersApp) {
    print("\nView Board Details")
    print("==================")

    let boards = app.hardwareManager.getAllBoards()
    guard !boards.isEmpty else {
        print("No boards configured")
        return
    }

    print("Select board:")
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("Choice: ", terminator: "")

    guard let choiceStr = readLine(), let choice = Int(choiceStr),
          choice > 0, choice <= boards.count else {
        print("Invalid choice")
        return
    }

    let board = boards[choice - 1]

    print("\n--- Board: \(board.name) ---")
    print("ID: \(board.id.uuidString)")
    print("Type: \(board.boardType.rawValue)")
    if !board.description.isEmpty {
        print("Description: \(board.description)")
    }
    print("Transport: \(board.transportType.rawValue)")
    if let port = board.serialPort {
        print("Serial Port: \(port)")
    }
    print("Baud Rate: \(board.baudRate)")
    print("Status: \(board.metadata.isActive ? "Active" : "Inactive")")

    if !board.pinAliases.isEmpty {
        print("\nPin Aliases (\(board.pinAliases.count)):")
        for pin in board.pinAliases {
            print("  - \(pin.alias) (Pin \(pin.physicalPin)): \(pin.description) [\(pin.pinType)]")
        }
    } else {
        print("\nNo pin aliases configured")
    }

    if let url = board.datasheetURL {
        print("\nDatasheet: \(url)")
    }
}

func removeHardwareBoard(app: WritersApp) {
    print("\nRemove Hardware Board")
    print("====================")

    let boards = app.hardwareManager.getAllBoards()
    guard !boards.isEmpty else {
        print("No boards configured")
        return
    }

    print("Select board to remove:")
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("Choice: ", terminator: "")

    guard let choiceStr = readLine(), let choice = Int(choiceStr),
          choice > 0, choice <= boards.count else {
        print("Invalid choice")
        return
    }

    let board = boards[choice - 1]
    print("Really remove '\(board.name)'? (y/n): ", terminator: "")
    guard let confirm = readLine(), confirm.lowercased() == "y" else {
        print("Cancelled")
        return
    }

    do {
        try app.hardwareManager.deleteBoard(id: board.id)
        print("Board removed successfully")
    } catch {
        print("Error removing board: \(error.localizedDescription)")
    }
}

func managePinAliases(app: WritersApp) {
    print("\nManage Pin Aliases")
    print("==================")

    let boards = app.hardwareManager.getAllBoards()
    guard !boards.isEmpty else {
        print("No boards configured")
        return
    }

    print("Select board:")
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("Choice: ", terminator: "")

    guard let choiceStr = readLine(), let choice = Int(choiceStr),
          choice > 0, choice <= boards.count else {
        print("Invalid choice")
        return
    }

    let board = boards[choice - 1]

    print("\nPin Management Options:")
    print("1. Add pin alias")
    print("2. Remove pin alias")
    print("3. List pin aliases")
    print("Choice: ", terminator: "")

    guard let optionStr = readLine(), let option = Int(optionStr) else {
        print("Invalid choice")
        return
    }

    switch option {
    case 1:
        print("Alias name (e.g., 'red_led'): ", terminator: "")
        guard let aliasName = readLine(), !aliasName.isEmpty else {
            print("Name cannot be empty")
            return
        }

        print("Physical pin number: ", terminator: "")
        guard let pinStr = readLine(), let pin = Int(pinStr) else {
            print("Invalid pin number")
            return
        }

        print("Description: ", terminator: "")
        let description = readLine() ?? ""

        print("Pin type (digital/analog/pwm) [digital]: ", terminator: "")
        let pinTypeInput = readLine() ?? ""
        let pinType = pinTypeInput.isEmpty ? "digital" : pinTypeInput

        let alias = PinAlias(
            alias: aliasName,
            physicalPin: pin,
            description: description,
            pinType: pinType
        )

        do {
            try app.hardwareManager.addPinAlias(to: board.id, alias: alias)
            print("Pin alias added successfully")
        } catch {
            print("Error adding pin alias: \(error.localizedDescription)")
        }

    case 2:
        guard !board.pinAliases.isEmpty else {
            print("No pin aliases to remove")
            return
        }
        print("Pin aliases:")
        for (index, pin) in board.pinAliases.enumerated() {
            print("\(index + 1). \(pin.alias) (Pin \(pin.physicalPin))")
        }
        print("Choice: ", terminator: "")

        guard let idxStr = readLine(), let idx = Int(idxStr),
              idx > 0, idx <= board.pinAliases.count else {
            print("Invalid choice")
            return
        }

        let pinToRemove = board.pinAliases[idx - 1]
        do {
            try app.hardwareManager.removePinAlias(from: board.id, aliasId: pinToRemove.id)
            print("Pin alias removed successfully")
        } catch {
            print("Error removing pin alias: \(error.localizedDescription)")
        }

    case 3:
        print("\nPin Aliases for '\(board.name)':")
        if board.pinAliases.isEmpty {
            print("  No pin aliases configured")
        } else {
            for pin in board.pinAliases {
                print("  - \(pin.alias) -> Pin \(pin.physicalPin) (\(pin.pinType))")
                if !pin.description.isEmpty {
                    print("    \(pin.description)")
                }
            }
        }

    default:
        print("Invalid option")
    }
}

func viewHardwareStatistics(app: WritersApp) {
    print("\nHardware Statistics")
    print("===================")

    let stats = app.getHardwareStatistics()

    print("Total boards: \(stats.totalBoards)")
    print("Active boards: \(stats.activeCount)")

    if !stats.byType.isEmpty {
        print("\nBoards by type:")
        for (type, count) in stats.byType.sorted(by: { $0.key < $1.key }) {
            print("  \(type): \(count)")
        }
    }
}
