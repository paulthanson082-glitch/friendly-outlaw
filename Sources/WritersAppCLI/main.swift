import Foundation
import WritersApp

// MARK: - CLI Application

// Global productivity managers
var focusManager = FocusSessionManager()
var goalManager = WritingGoalManager()
var analyticsService: ProductivityAnalytics!

// MARK: - Clother Provider Detection

struct ClotherProvider {
    let name: String
    let command: String
    let baseUrl: String?
    let description: String
}

func detectClotherProvider() -> ClotherProvider? {
    let env = ProcessInfo.processInfo.environment

    // Check for custom base URL (set by Clother launchers)
    if let baseUrl = env["ANTHROPIC_BASE_URL"] {
        // Detect provider based on endpoint
        switch baseUrl {
        case _ where baseUrl.contains("z.ai"):
            return ClotherProvider(
                name: "Z.AI (GLM-5)",
                command: "clother-zai",
                baseUrl: baseUrl,
                description: "GLM-5 via Z.AI"
            )
        case _ where baseUrl.contains("deepseek"):
            return ClotherProvider(
                name: "DeepSeek",
                command: "clother-deepseek",
                baseUrl: baseUrl,
                description: "DeepSeek Chat API"
            )
        case _ where baseUrl.contains("openrouter"):
            return ClotherProvider(
                name: "OpenRouter",
                command: "clother-or-*",
                baseUrl: baseUrl,
                description: "100+ LLM models via OpenRouter"
            )
        case _ where baseUrl.contains("ollama"):
            return ClotherProvider(
                name: "Ollama (Local)",
                command: "clother-ollama",
                baseUrl: baseUrl,
                description: "Local LLM via Ollama"
            )
        case _ where baseUrl.contains("anthropic"):
            return ClotherProvider(
                name: "Anthropic Claude",
                command: "clother-native",
                baseUrl: baseUrl,
                description: "Claude API (Anthropic)"
            )
        default:
            return ClotherProvider(
                name: "Custom Provider",
                command: "custom",
                baseUrl: baseUrl,
                description: "Custom LLM endpoint"
            )
        }
    }

    return nil
}

func displayProviderInfo() {
    if let provider = detectClotherProvider() {
        print("🔗 LLM Provider: \(provider.name)")
        print("   Command: \(provider.command)")
        print("   Details: \(provider.description)")
    } else {
        print("ⓘ LLM Provider: Standard (Anthropic API)")
        print("   To use alternative providers, install Clother:")
        print("   → curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash")
        print("   → clother config")
        print("   → clother-<provider> swift run WritersAppCLI")
        print("   See CLOTHER.md for details")
    }
}

@main
struct WritersAppCLI {
    /// Application CLI entry point that initializes application services, processes command-line arguments, configures optional integrations, and runs the interactive main menu.
    /// 
    /// Performs high-level startup and runtime tasks:
    /// - Initializes WritersApp and global analytics.
    /// - Parses and handles command-line flags for help, listing, opening documents, running focus sessions, GUI exports, trace analysis, and playful actions.
    /// - Enables optional features based on environment variables (Anthropic/Clother AI, gui.new, Ragie) and attempts to initialize the Claude memory plugin.
    /// Application entry point that initializes global services, processes command-line flags, and runs the interactive CLI menu.
    /// 
    /// Application entry point that initializes services, parses command-line flags, and runs the interactive CLI loop.
    /// 
    /// The function initializes the application and analytics services, detects and enables optional integrations (AI, gui.new, Ragie, Gmail, Claude Memory), processes one-off CLI flags (help, list, open, run, trace analysis, dance, gui exports) and executes the corresponding actions (which may exit early). When no terminating flag is provided it prints a startup banner, displays LLM provider information, configures optional features based on environment variables, attempts to enable the memory plugin, and enters the interactive main menu loop that dispatches user-selected commands until the user exits.
    static func main() async {
        let app = WritersApp()
        analyticsService = ProductivityAnalytics(focusManager: focusManager, goalManager: goalManager)

        // Parse command-line arguments
        let arguments = CommandLine.arguments
        
        // Handle command-line arguments
        if arguments.count > 1 {
            // Parse all arguments to support combined commands
            var openArg: String? = nil
            var runArg: String? = nil
            var shouldShowHelp = false
            var listDocs = false
            var analyzeTraces = false
            var shouldDance = false
            var guiDocArg: String? = nil
            var guiStats = false
            var guiKanbanArg: String? = nil
            
            var i = 1
            while i < arguments.count {
                let arg = arguments[i]
                
                switch arg {
                case "--help", "-h":
                    shouldShowHelp = true
                    i += 1
                case "--list", "-l":
                    listDocs = true
                    i += 1
                case "--open", "-o":
                    if i + 1 < arguments.count {
                        openArg = arguments[i + 1]
                        i += 2
                    } else {
                        print("Error: --open requires a document ID or title")
                        print("Usage: WritersAppCLI --open <document-id-or-title>")
                        return
                    }
                case "--run", "-r":
                    if i + 1 < arguments.count && !arguments[i + 1].starts(with: "-") {
                        runArg = arguments[i + 1]
                        i += 2
                    } else {
                        runArg = "" // Empty string means freewrite (default)
                        i += 1
                    }
                case "--analyze-traces":
                    analyzeTraces = true
                    i += 1
                case "--dance":
                    shouldDance = true
                    i += 1
                case "--gui-stats":
                    guiStats = true
                    i += 1
                case "--gui-doc":
                    if i + 1 < arguments.count {
                        guiDocArg = arguments[i + 1]
                        i += 2
                    } else {
                        print("Error: --gui-doc requires a document ID or title")
                        print("Usage: WritersAppCLI --gui-doc <document-id-or-title>")
                        return
                    }
                case "--gui-kanban":
                    if i + 1 < arguments.count {
                        guiKanbanArg = arguments[i + 1]
                        i += 2
                    } else {
                        print("Error: --gui-kanban requires a board name or ID")
                        print("Usage: WritersAppCLI --gui-kanban <board-name-or-id>")
                        return
                    }
                default:
                    print("Unknown option: \(arg)")
                    print("Use --help for usage information")
                    return
                }
            }
            
            // Execute commands
            if shouldShowHelp {
                showHelp()
                return
            }
            
            if listDocs {
                listDocuments(app: app)
                return
            }

            if analyzeTraces {
                runTraceAnalysis(app: app)
                return
            }

            if shouldDance {
                await claudeDance()
                return
            }
            
            // Handle combined --open and --run
            if let openDocArg = openArg, let runSessionArg = runArg {
                await openDocumentAndStartSession(
                    app: app, 
                    searchTerm: openDocArg, 
                    sessionTypeName: runSessionArg.isEmpty ? nil : runSessionArg
                )
                return
            }
            
            // Handle --open alone
            if let openDocArg = openArg {
                await openDocumentByIdOrTitle(app: app, searchTerm: openDocArg)
                return
            }
            
            // Handle --run alone
            if let runSessionArg = runArg {
                startFocusSessionDirect(
                    app: app,
                    sessionTypeName: runSessionArg.isEmpty ? nil : runSessionArg
                )
                return
            }

            // Handle --gui-stats
            if guiStats {
                await exportStatisticsToGui(app: app)
                return
            }

            // Handle --gui-doc
            if let docArg = guiDocArg {
                await exportDocumentToGui(app: app, searchTerm: docArg)
                return
            }

            // Handle --gui-kanban
            if let boardArg = guiKanbanArg {
                await exportKanbanBoardToGui(app: app, searchTerm: boardArg)
                return
            }
        }

        print("╔══════════════════════════════════════╗")
        print("║     Writers App with Templates       ║")
        print("║   Swift Edition - Productivity Plus  ║")
        print("╚══════════════════════════════════════╝")
        print()

        // Display LLM provider information
        displayProviderInfo()
        print()

        // Check for API key in environment
        if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
            print("✓ AI features enabled (Claude API)")
            let config = AIConfiguration(apiKey: apiKey, model: .claude35Sonnet)
            app.enableAI(configuration: config)
        } else if ProcessInfo.processInfo.environment["ANTHROPIC_AUTH_TOKEN"] != nil {
            // Clother provider configured
            print("✓ AI features enabled (via Clother)")
            // Create config with default values; Clother handles auth via env vars
            let config = AIConfiguration(apiKey: "clother-managed", model: .claude35Sonnet)
            app.enableAI(configuration: config)
        } else {
            print("ⓘ AI features disabled (set ANTHROPIC_API_KEY to enable)")
        }

        // Initialize gui.new client if API key is present (optional)
        if ProcessInfo.processInfo.environment["GUI_NEW_API_KEY"] != nil {
            app.enableGui()
            print("✓ gui.new visual export enabled")
        } else {
            app.enableGui() // Free tier — no key required
            print("ⓘ gui.new visual export available (set GUI_NEW_API_KEY for Pro)")
        }

        // Initialize Ragie if API key is present
        if let ragieKey = ProcessInfo.processInfo.environment["RAGIE_API_KEY"], !ragieKey.isEmpty {
            let ragieConfig = RagieConfiguration(apiKey: ragieKey)
            app.enableRagie(configuration: ragieConfig)
            print("✓ Ragie document retrieval enabled")
        } else {
            print("ⓘ Ragie disabled (set RAGIE_API_KEY to enable document retrieval)")
        }

        // Initialize Gmail for Cowork Mode if OAuth token is present
        if let gmailToken = ProcessInfo.processInfo.environment["GMAIL_OAUTH_TOKEN"], !gmailToken.isEmpty {
            app.enableGmail(oauthToken: gmailToken)
            print("✓ Cowork Mode: Gmail enabled")
        } else {
            print("ⓘ Cowork Mode: Gmail disabled (set GMAIL_OAUTH_TOKEN to enable)")
        }
        print("✓ Cowork Mode: Prospect database and browser research ready")

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
                print("17. Chat with Jules (AI Assistant)")

                if app.isJulesAdultModeEnabled {
                    print("18. Disable Jules Adult Mode (currently ON)")
                } else {
                    print("18. Enable Jules Adult Mode (currently OFF)")
                }
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
            
            print("\nEncouragement:")
            print("50. Get Encouragement")
            print("51. Toggle Encouragement")
            print("52. View Encouragement History")

            print("\nLLM Provider:")
            print("53. Display LLM Provider Information")

            print("\nIssue Management:")
            print("60. Create Issue")
            print("61. View Issues for Document")
            print("62. View All Issues")
            print("63. View Issues by Status")
            print("64. View Issues by Priority")
            print("65. Search Issues")
            print("66. Update Issue")
            print("67. Update Issue Status")
            print("68. Delete Issue")
            print("69. View Issue Statistics")
            print("70. Reopen Issue")

            print("\nKanban Board Management:")
            print("71. Create Kanban Board")
            print("72. List Kanban Boards")
            print("73. View Kanban Board")
            print("74. Add Kanban Task")
            print("75. Move Kanban Task")
            print("76. Delete Kanban Board")

            print("\nHardware Board Management:")
            print("80. Add Hardware Board")
            print("81. List Hardware Boards")
            print("82. View Board Details")
            print("83. Remove Hardware Board")
            print("84. Manage Pin Aliases")
            print("85. View Board Statistics")

            print("\ngui.new Visual Export:")
            print("90. Export Statistics Dashboard to gui.new")
            print("91. Export Document to gui.new")
            print("92. Export Kanban Board to gui.new")

            if app.isRagieEnabled {
                print("\nRagie Document Retrieval:")
                print("95. Ingest Document into Ragie")
                print("96. Retrieve Context from Ragie")
                print("97. List Ragie Documents")
                print("98. Check Ragie Document Status")
            }

            print("\nCowork Mode (Gmail + Prospects + Browser):")
            print("100. Start Cowork Session")
            print("101. End Cowork Session")
            print("102. Add Prospect")
            print("103. List Prospects")
            print("104. Search Prospects")
            print("105. Update Prospect Status")
            print("106. Prospect Pipeline Stats")
            if app.isGmailEnabled {
                print("107. View Gmail Inbox")
                print("108. Mark Email as Read")
                print("109. Send Email")
            }
            print("110. Research URL (Browser)")
            print("111. View Browsing History")

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
            case 17:
                await chatWithJules(app: app)
            case 18:
                toggleJulesAdultMode(app: app)
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
            case 50:
                getEncouragement(app: app)
            case 51:
                toggleEncouragement(app: app)
            case 52:
                viewEncouragementHistory(app: app)
            case 53:
                displayClotherProviderInfo()
            case 60:
                createIssue(app: app)
            case 61:
                viewIssuesForDocument(app: app)
            case 62:
                viewAllIssues(app: app)
            case 63:
                viewIssuesByStatus(app: app)
            case 64:
                viewIssuesByPriority(app: app)
            case 65:
                searchIssues(app: app)
            case 66:
                updateIssue(app: app)
            case 67:
                updateIssueStatus(app: app)
            case 68:
                deleteIssue(app: app)
            case 69:
                viewIssueStatistics(app: app)
            case 70:
                reopenIssue(app: app)
            case 71:
                createKanbanBoardCLI(app: app)
            case 72:
                listKanbanBoardsCLI(app: app)
            case 73:
                viewKanbanBoardCLI(app: app)
            case 74:
                addKanbanTaskCLI(app: app)
            case 75:
                moveKanbanTaskCLI(app: app)
            case 76:
                deleteKanbanBoardCLI(app: app)
            case 80:
                await addHardwareBoard(app: app)
            case 81:
                listHardwareBoards(app: app)
            case 82:
                viewBoardDetails(app: app)
            case 83:
                removeHardwareBoard(app: app)
            case 84:
                await managePinAliases(app: app)
            case 85:
                viewHardwareStatistics(app: app)
            case 90:
                await exportStatisticsToGui(app: app)
            case 91:
                await exportDocumentToGuiInteractive(app: app)
            case 92:
                await exportKanbanBoardToGuiInteractive(app: app)
            case 95:
                await ingestDocumentToRagie(app: app)
            case 96:
                await retrieveContextFromRagie(app: app)
            case 97:
                await listRagieDocuments(app: app)
            case 98:
                await checkRagieDocumentStatus(app: app)
            case 100:
                startCoworkSession(app: app)
            case 101:
                endCoworkSession(app: app)
            case 102:
                addProspect(app: app)
            case 103:
                listProspects(app: app)
            case 104:
                searchProspects(app: app)
            case 105:
                updateProspectStatus(app: app)
            case 106:
                viewProspectPipelineStats(app: app)
            case 107:
                await viewGmailInbox(app: app)
            case 108:
                await markGmailMessageAsRead(app: app)
            case 109:
                await sendGmail(app: app)
            case 110:
                await researchURL(app: app)
            case 111:
                viewBrowsingHistory(app: app)
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

// MARK: - Document Viewing

/// Displays a document interactively with a menu of actions
func viewDocumentInteractive(app: WritersApp, documentId: UUID) async {
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
    await viewDocumentInteractive(app: app, documentId: documentId)
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
    
    let previousWordCount = document.wordCount
    
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
    
    // Show encouragement if enabled and words were added
    if app.isEncouragementEnabled {
        if let encouragement = app.getEncouragementForDocument(document, previousWordCount: previousWordCount) {
            print("\n💫 \(encouragement.message)")
        }
    }
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

func startFocusSessionDirect(app: WritersApp, sessionTypeName: String?) {
    // Check if session is already active
    if focusManager.getCurrentSession() != nil {
        print("Error: A focus session is already active.")
        print("Please end the current session before starting a new one.")
        return
    }
    
    // Parse session type from argument or default to freeWrite
    let sessionType: FocusSessionType
    if let typeName = sessionTypeName?.lowercased() {
        switch typeName {
        case "freewrite", "free":
            sessionType = .freeWrite
        case "pomodoro", "pomo":
            sessionType = .pomodoro
        case "sprint", "writing-sprint":
            sessionType = .sprint
        case "deepwork", "deep":
            sessionType = .deepWork
        case "marathon":
            sessionType = .marathon
        default:
            print("Error: Unknown session type '\(typeName)'")
            print("Valid types: freewrite, pomodoro, sprint, deepwork, marathon")
            return
        }
    } else {
        sessionType = .freeWrite
    }
    
    // Start the session without document linking for CLI simplicity
    let session = focusManager.startSession(
        type: sessionType,
        documentId: nil,
        currentWordCount: 0
    )
    
    print("\n✓ Focus session started!")
    print("  Type: \(session.type.displayName)")
    if session.targetDuration > 0 {
        print("  Duration: \(FocusSessionManager.formatTimeRemaining(session.targetDuration))")
    }
    print("\nHappy writing! The session is now running in the background.")
    print("Run 'WritersAppCLI' in interactive mode to view or end your session.\n")
}

func openDocumentAndStartSession(app: WritersApp, searchTerm: String, sessionTypeName: String?) async {
    // First, find the document
    let documents = app.documentManager.getAllDocuments()
    
    if documents.isEmpty {
        print("No documents found. Create one to get started!")
        return
    }
    
    var targetDocument: Document? = nil
    
    // Try to find by ID first
    if let uuid = UUID(uuidString: searchTerm) {
        targetDocument = app.documentManager.getDocument(id: uuid)
    }
    
    // If not found by ID, try to find by exact title match
    if targetDocument == nil {
        targetDocument = documents.first(where: { $0.title.lowercased() == searchTerm.lowercased() })
    }
    
    // If still not found, try partial title match
    if targetDocument == nil {
        let matches = documents.filter { $0.title.lowercased().contains(searchTerm.lowercased()) }
        
        if matches.isEmpty {
            print("No document found matching: \(searchTerm)")
            print("Use --list to see all documents")
            return
        }
        
        if matches.count == 1 {
            targetDocument = matches[0]
        } else {
            // Multiple matches found
            print("Multiple documents found matching '\(searchTerm)':\n")
            for (index, document) in matches.enumerated() {
                print("\(index + 1). \(document.title) (ID: \(String(document.id.uuidString.prefix(8))))")
            }
            print("\nPlease use a more specific title or document ID.")
            return
        }
    }
    
    guard let document = targetDocument else {
        print("Error: Could not find document matching: \(searchTerm)")
        return
    }
    
    // Check if a session is already active
    if focusManager.getCurrentSession() != nil {
        print("Error: A focus session is already active.")
        print("Please end the current session before starting a new one.")
        return
    }
    
    // Parse session type from argument or default to freeWrite
    let sessionType: FocusSessionType
    if let typeName = sessionTypeName?.lowercased() {
        switch typeName {
        case "freewrite", "free":
            sessionType = .freeWrite
        case "pomodoro", "pomo":
            sessionType = .pomodoro
        case "sprint", "writing-sprint":
            sessionType = .sprint
        case "deepwork", "deep":
            sessionType = .deepWork
        case "marathon":
            sessionType = .marathon
        default:
            print("Error: Unknown session type '\(typeName)'")
            print("Valid types: freewrite, pomodoro, sprint, deepwork, marathon")
            return
        }
    } else {
        sessionType = .freeWrite
    }
    
    // Start the session linked to the document
    let session = focusManager.startSession(
        type: sessionType,
        documentId: document.id,
        currentWordCount: document.wordCount
    )
    
    // Update last opened date
    var updatedDocument = document
    updatedDocument.metadata.lastOpened = Date()
    app.documentManager.updateDocument(updatedDocument)
    
    // Display document info
    print("\n" + String(repeating: "=", count: 60))
    print("Document Opened: \(document.title)")
    print(String(repeating: "=", count: 60))
    print()
    print("Category: \(document.category.rawValue)")
    print("Word Count: \(document.wordCount)")
    print("Character Count: \(document.characterCount)")
    
    if let goal = document.metadata.wordCountGoal {
        let progress = Double(document.wordCount) / Double(goal) * 100.0
        print("Goal Progress: \(document.wordCount)/\(goal) words (\(String(format: "%.1f", progress))%)")
    }
    print()
    
    // Display session info
    print("✓ Focus session started!")
    print("  Type: \(session.type.displayName)")
    if session.targetDuration > 0 {
        print("  Duration: \(FocusSessionManager.formatTimeRemaining(session.targetDuration))")
    }
    print("  Linked to: \(document.title)")
    print("  Starting word count: \(document.wordCount)")
    print()
    print("Happy writing! The session is tracking this document.")
    print("Run 'WritersAppCLI' in interactive mode to view or end your session.\n")
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

// MARK: - Dance

func claudeDance() async {
    let frames: [String] = [
        """
        ╔══════════════════════════════╗
        ║       ♪ ♫  CLAUDE  ♫ ♪       ║
        ╚══════════════════════════════╝

              \\o/   ← arms up!
               |
              / \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♫ ♪  CLAUDE  ♪ ♫       ║
        ╚══════════════════════════════╝

               o    ← lean right
              /|
              / \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♪ ♫  CLAUDE  ♫ ♪       ║
        ╚══════════════════════════════╝

               o    ← lean left
               |\\
              / \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♫ ♪  CLAUDE  ♪ ♫       ║
        ╚══════════════════════════════╝

              \\o/   ← spin!
               |
              / \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♪ ♫  CLAUDE  ♫ ♪       ║
        ╚══════════════════════════════╝

              \\o    ← groove left
               |\\
              /  \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♫ ♪  CLAUDE  ♪ ♫       ║
        ╚══════════════════════════════╝

               o/   ← groove right
              /|
              /  \\
        """,
        """
        ╔══════════════════════════════╗
        ║       ♪ ♫  CLAUDE  ♫ ♪       ║
        ╚══════════════════════════════╝

              \\O/   ← jazz hands!
               |
              / \\
        """,
        """
        ╔══════════════════════════════╗
        ║    🎉  DANCE COMPLETE!  🎉    ║
        ╚══════════════════════════════╝

              \\o/
               |    Thanks for watching!
              / \\
        """
    ]

    print("\nGet ready... Claude is about to dance!\n")
    try? await Task.sleep(nanoseconds: 800_000_000)

    let repeatCount = 2
    for rep in 0..<repeatCount {
        let framesToShow = rep < repeatCount - 1 ? frames.dropLast() : Array(frames)
        for frame in framesToShow {
            // Clear previous frame (move cursor up 8 lines)
            print("\u{1B}[8A\u{1B}[J", terminator: "")
            print(frame)
            try? await Task.sleep(nanoseconds: 350_000_000)
        }
    }

    print("\n  ♪ Never gonna give you up, never gonna let you down ♪\n")
}

func showHelp() {
    print("""
    Writers App CLI - Command-Line Interface

    USAGE:
        WritersAppCLI [OPTIONS]

    OPTIONS:
        --help, -h              Show this help message
        --list, -l              List all documents
        --open, -o <id|title>   Open a document by ID or title
        --run, -r [type]        Start a focus session (types: freewrite, pomodoro, sprint, deepwork, marathon)
        --analyze-traces        Run trace analysis report (productivity by session length, tool usage)
        --dance                 Make Claude dance ♪
        --gui-stats             Export writing statistics dashboard to gui.new (prints shareable URL)
        --gui-doc <id|title>    Export a document as a shareable gui.new page
        --gui-kanban <name|id>  Export a Kanban board as a shareable gui.new canvas

    COMBINED OPTIONS:
        --open <id|title> --run [type]   Open a document and start a focus session on it
        --run [type] --open <id|title>   Start a focus session linked to a document (order doesn't matter)

    EXAMPLES:
        WritersAppCLI                              # Start interactive mode
        WritersAppCLI --list                       # List all documents
        WritersAppCLI --open "My Story"            # Open document by title
        WritersAppCLI --open <document-id>         # Open document by ID
        WritersAppCLI --run pomodoro               # Start a 25-minute Pomodoro session
        WritersAppCLI --run sprint                 # Start a 15-minute writing sprint
        WritersAppCLI --run                        # Start a free write session (no time limit)
        WritersAppCLI --open "My Novel" --run pomodoro    # Open "My Novel" and start 25-min session
        WritersAppCLI --run sprint --open "Chapter 1"     # Same as above, order doesn't matter
        WritersAppCLI --open <doc-id> --run deepwork      # Open by ID and start 90-min deep work
        WritersAppCLI --gui-stats                  # Publish statistics dashboard to gui.new
        WritersAppCLI --gui-doc "My Novel"         # Publish document to gui.new
        WritersAppCLI --gui-kanban "Sprint Board"  # Publish Kanban board to gui.new

    ENVIRONMENT VARIABLES:
        ANTHROPIC_API_KEY      Set this to enable AI features (Anthropic Claude)
        GUI_NEW_API_KEY        Optional: gui.new Pro API key for extended canvas expiry

    USING ALTERNATIVE LLM PROVIDERS WITH CLOTHER:
        Clother allows you to use 100+ LLM providers without changing code.
        See CLOTHER.md for complete setup and provider list.

        Quick Start:
            1. Install Clother:
               curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash

            2. Configure a provider:
               clother config                    # Interactive setup
               clother config zai                # Z.AI (GLM-5)
               clother config deepseek           # DeepSeek

            3. Run with your provider:
               clother-native swift run WritersAppCLI          # Claude
               clother-zai swift run WritersAppCLI             # Z.AI
               clother-deepseek swift run WritersAppCLI        # DeepSeek
               clother-ollama --model qwen3-coder swift run WritersAppCLI  # Local Ollama

        Supported Providers:
            Cloud: Claude (Anthropic), Z.AI, DeepSeek, OpenRouter, Kimi, Moonshot, MiniMax
            Local: Ollama, LM Studio, llama.cpp

    For interactive mode, run without arguments.
    """)
}

func displayClotherProviderInfo() {
    print("\n=== LLM Provider Information ===\n")

    displayProviderInfo()

    print("\n--- Provider Setup ---")
    print("""
    To change your LLM provider, install and configure Clother:

    1. INSTALL CLOTHER (one-time)
       curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash

    2. CONFIGURE A PROVIDER
       clother config                   # Interactive setup wizard
       clother test                     # Verify your configuration

    3. POPULAR PROVIDERS
       • clother-native                 # Claude (Anthropic) - requires Pro/Team
       • clother-zai                    # Z.AI (GLM-5) - affordable
       • clother-deepseek               # DeepSeek - affordable
       • clother-ollama                 # Local Ollama - free, offline
       • clother-or-*                   # OpenRouter - 100+ models

    4. RUN WITH YOUR PROVIDER
       clother-zai swift run WritersAppCLI
       clother-deepseek swift run WritersAppCLI
       clother-ollama --model qwen3-coder swift run WritersAppCLI

    For complete setup instructions, see CLOTHER.md
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
        if app.documentManager.getDocument(id: uuid) != nil {
            await viewDocumentInteractive(app: app, documentId: uuid)
            return
        }
    }
    
    // Try to find by exact title match
    if let document = documents.first(where: { $0.title.lowercased() == searchTerm.lowercased() }) {
        await viewDocumentInteractive(app: app, documentId: document.id)
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
        await viewDocumentInteractive(app: app, documentId: matches[0].id)
        return
    }
    
    // Multiple matches found
    print("Multiple documents found matching '\(searchTerm)':\n")
    for (index, document) in matches.enumerated() {
        print("\(index + 1). \(document.title) (ID: \(String(document.id.uuidString.prefix(uuidDisplayLength))))")
    }
    print("\nPlease use a more specific title or document ID.")
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

// MARK: - Encouragement Functions

func getEncouragement(app: WritersApp) {
    print("\n=== Get Encouragement ===\n")
    
    if !app.isEncouragementEnabled {
        print("❌ Encouragement is currently disabled.")
        print("Use option 51 to enable it.")
        return
    }
    
    print("Choose encouragement type:")
    print("1. General encouragement")
    print("2. Perseverance message")
    print("3. Based on total words written")
    print()
    print("Enter choice: ", terminator: "")
    
    guard let input = readLine(), let choice = Int(input) else {
        print("Invalid input.")
        return
    }
    
    switch choice {
    case 1:
        let encouragement = app.getGeneralEncouragement()
        print("\n💫 \(encouragement.message)\n")
        
    case 2:
        let encouragement = app.encouragementService.getPerseveranceEncouragement()
        print("\n💪 \(encouragement.message)\n")
        
    case 3:
        let stats = app.getStatistics()
        if stats.totalWordCount >= 50 {
            let encouragement = app.encouragementService.getWordCountEncouragement(
                wordCount: stats.totalWordCount,
                previousCount: 0
            )
            if let enc = encouragement {
                print("\n💫 \(enc.message)")
                print("   Total words across all documents: \(stats.totalWordCount)\n")
            }
        } else {
            print("\n📝 Keep writing! You have \(stats.totalWordCount) words so far.")
            print("   Get to 50 words for your first encouragement!\n")
        }
        
    default:
        print("Invalid choice.")
    }
}

func toggleEncouragement(app: WritersApp) {
    print("\n=== Toggle Encouragement ===\n")
    
    let currentStatus = app.isEncouragementEnabled ? "enabled" : "disabled"
    print("Encouragement is currently: \(currentStatus)")
    print()
    print("Would you like to \(app.isEncouragementEnabled ? "disable" : "enable") it? (yes/no): ", terminator: "")
    
    guard let input = readLine()?.lowercased() else {
        print("Invalid input.")
        return
    }
    
    if input == "yes" || input == "y" {
        app.setEncouragementEnabled(!app.isEncouragementEnabled)
        let newStatus = app.isEncouragementEnabled ? "enabled" : "disabled"
        print("\n✓ Encouragement has been \(newStatus)!")
        
        if app.isEncouragementEnabled {
            let encouragement = app.getGeneralEncouragement()
            print("\n💫 \(encouragement.message)\n")
        }
    } else {
        print("\nNo changes made.")
    }
}

// MARK: - Trace Analysis

func runTraceAnalysis(app: WritersApp) {
    print("\n=== Trace Analysis Report ===\n")

    let traceAnalysis = TraceAnalysisService(databaseManager: app.databaseManager)

    do {
        let report = try traceAnalysis.runFullAnalysis()
        print(TraceAnalysisService.formatReport(report))
    } catch {
        print("Error running trace analysis: \(error.localizedDescription)")
    }
}

func viewEncouragementHistory(app: WritersApp) {
    print("\n=== Encouragement History ===\n")
    
    let history = app.encouragementService.getHistory(limit: 20)
    
    if history.isEmpty {
        print("No encouragement history yet.")
        print("Start writing and receive encouraging messages!\n")
        return
    }
    
    print("Recent encouragements:\n")
    
    for (index, encouragement) in history.enumerated().reversed() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let typeEmoji: String
        switch encouragement.type {
        case .wordCount:
            typeEmoji = "📝"
        case .sessionDuration:
            typeEmoji = "⏱️"
        case .milestone:
            typeEmoji = "🏆"
        case .general:
            typeEmoji = "💫"
        case .perseverance:
            typeEmoji = "💪"
        case .creativity:
            typeEmoji = "✨"
        case .consistency:
            typeEmoji = "🎯"
        }
        
        print("\(history.count - index). \(typeEmoji) \(encouragement.message)")
        print("   \(formatter.string(from: encouragement.timestamp))")
        
        if let context = encouragement.context {
            if let wordsWritten = context["words_written"] {
                print("   Words written: \(wordsWritten)")
            }
            if let duration = context["duration_minutes"] {
                print("   Session duration: \(duration) minutes")
            }
        }
        print()
    }
}

// MARK: - Issue Management

func createIssue(app: WritersApp) {
    print("\n=== Create Issue ===\n")
    
    // Select document
    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available. Create a document first.")
        return
    }
    
    print("Select a document:")
    for (index, doc) in documents.enumerated() {
        print("\(index + 1). \(doc.title)")
    }
    print("\nEnter document number: ", terminator: "")
    
    guard let docChoice = readLine(), let docIndex = Int(docChoice),
          docIndex > 0, docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }
    
    let document = documents[docIndex - 1]
    
    // Get issue title
    print("Enter issue title: ", terminator: "")
    guard let title = readLine(), !title.isEmpty else {
        print("Title cannot be empty.")
        return
    }
    
    // Get description
    print("Enter issue description (optional): ", terminator: "")
    let description = readLine() ?? ""
    
    // Get priority
    print("\nSelect priority:")
    print("1. Low")
    print("2. Medium (default)")
    print("3. High")
    print("4. Critical")
    print("Enter priority (1-4, default 2): ", terminator: "")
    
    let priorityInput = readLine() ?? "2"
    let priority: IssuePriority
    switch priorityInput {
    case "1": priority = .low
    case "3": priority = .high
    case "4": priority = .critical
    default: priority = .medium
    }
    
    let issue = app.createIssue(
        documentId: document.id,
        title: title,
        description: description,
        priority: priority
    )
    
    print("\n✓ Issue created successfully!")
    print("Issue ID: \(issue.id)")
    print("Document: \(document.title)")
    print("Priority: \(priority.displayName)")
}

func viewIssuesForDocument(app: WritersApp) {
    print("\n=== View Issues for Document ===\n")
    
    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents available.")
        return
    }
    
    print("Select a document:")
    for (index, doc) in documents.enumerated() {
        print("\(index + 1). \(doc.title)")
    }
    print("\nEnter document number: ", terminator: "")
    
    guard let docChoice = readLine(), let docIndex = Int(docChoice),
          docIndex > 0, docIndex <= documents.count else {
        print("Invalid selection.")
        return
    }
    
    let document = documents[docIndex - 1]
    let issues = app.getIssues(forDocument: document.id)
    
    if issues.isEmpty {
        print("\nNo issues found for '\(document.title)'")
        return
    }
    
    print("\n=== Issues for '\(document.title)' ===\n")
    displayIssues(issues)
}

func viewAllIssues(app: WritersApp) {
    print("\n=== All Issues ===\n")
    
    let issues = app.issueManager.getAllIssues()
    
    if issues.isEmpty {
        print("No issues found.")
        return
    }
    
    displayIssues(issues)
}

func viewIssuesByStatus(app: WritersApp) {
    print("\n=== View Issues by Status ===\n")
    
    print("Select status:")
    print("1. Open")
    print("2. In Progress")
    print("3. Resolved")
    print("4. Closed")
    print("\nEnter status (1-4): ", terminator: "")
    
    guard let choice = readLine(), let statusIndex = Int(choice),
          statusIndex >= 1, statusIndex <= 4 else {
        print("Invalid selection.")
        return
    }
    
    let status: IssueStatus
    switch statusIndex {
    case 1: status = .open
    case 2: status = .inProgress
    case 3: status = .resolved
    case 4: status = .closed
    default: return
    }
    
    let issues = app.getIssues(withStatus: status)
    
    if issues.isEmpty {
        print("\nNo issues with status '\(status.displayName)'")
        return
    }
    
    print("\n=== Issues with Status: \(status.displayName) ===\n")
    displayIssues(issues)
}

func viewIssuesByPriority(app: WritersApp) {
    print("\n=== View Issues by Priority ===\n")
    
    print("Select priority:")
    print("1. Low")
    print("2. Medium")
    print("3. High")
    print("4. Critical")
    print("\nEnter priority (1-4): ", terminator: "")
    
    guard let choice = readLine(), let priorityIndex = Int(choice),
          priorityIndex >= 1, priorityIndex <= 4 else {
        print("Invalid selection.")
        return
    }
    
    let priority: IssuePriority
    switch priorityIndex {
    case 1: priority = .low
    case 2: priority = .medium
    case 3: priority = .high
    case 4: priority = .critical
    default: return
    }
    
    let issues = app.getIssues(withPriority: priority)
    
    if issues.isEmpty {
        print("\nNo issues with priority '\(priority.displayName)'")
        return
    }
    
    print("\n=== Issues with Priority: \(priority.displayName) ===\n")
    displayIssues(issues)
}

func searchIssues(app: WritersApp) {
    print("\n=== Search Issues ===\n")
    print("Enter search query: ", terminator: "")
    
    guard let query = readLine(), !query.isEmpty else {
        print("Search query cannot be empty.")
        return
    }
    
    let issues = app.searchIssues(query: query)
    
    if issues.isEmpty {
        print("\nNo issues found matching '\(query)'")
        return
    }
    
    print("\n=== Search Results for '\(query)' ===\n")
    displayIssues(issues)
}

func updateIssue(app: WritersApp) {
    print("\n=== Update Issue ===\n")
    
    let issues = app.issueManager.getAllIssues()
    if issues.isEmpty {
        print("No issues available.")
        return
    }
    
    print("Select an issue to update:")
    for (index, issue) in issues.enumerated() {
        print("\(index + 1). \(issue.title) [\(issue.status.displayName), \(issue.priority.displayName)]")
    }
    print("\nEnter issue number: ", terminator: "")
    
    guard let choice = readLine(), let issueIndex = Int(choice),
          issueIndex > 0, issueIndex <= issues.count else {
        print("Invalid selection.")
        return
    }
    
    var issue = issues[issueIndex - 1]
    
    print("\nCurrent title: \(issue.title)")
    print("Enter new title (or press Enter to keep): ", terminator: "")
    if let newTitle = readLine(), !newTitle.isEmpty {
        issue.title = newTitle
    }
    
    print("\nCurrent description: \(issue.description)")
    print("Enter new description (or press Enter to keep): ", terminator: "")
    if let newDescription = readLine(), !newDescription.isEmpty {
        issue.description = newDescription
    }
    
    app.updateIssue(issue)
    print("\n✓ Issue updated successfully!")
}

func updateIssueStatus(app: WritersApp) {
    print("\n=== Update Issue Status ===\n")
    
    let issues = app.issueManager.getAllIssues()
    if issues.isEmpty {
        print("No issues available.")
        return
    }
    
    print("Select an issue:")
    for (index, issue) in issues.enumerated() {
        print("\(index + 1). \(issue.title) [Current: \(issue.status.displayName)]")
    }
    print("\nEnter issue number: ", terminator: "")
    
    guard let choice = readLine(), let issueIndex = Int(choice),
          issueIndex > 0, issueIndex <= issues.count else {
        print("Invalid selection.")
        return
    }
    
    let issue = issues[issueIndex - 1]
    
    print("\nSelect new status:")
    print("1. Open")
    print("2. In Progress")
    print("3. Resolved")
    print("4. Closed")
    print("\nEnter status (1-4): ", terminator: "")
    
    guard let statusChoice = readLine(), let statusIndex = Int(statusChoice),
          statusIndex >= 1, statusIndex <= 4 else {
        print("Invalid selection.")
        return
    }
    
    let status: IssueStatus
    switch statusIndex {
    case 1: status = .open
    case 2: status = .inProgress
    case 3: status = .resolved
    case 4: status = .closed
    default: return
    }
    
    app.updateIssueStatus(id: issue.id, status: status)
    print("\n✓ Issue status updated to '\(status.displayName)'!")
}

func deleteIssue(app: WritersApp) {
    print("\n=== Delete Issue ===\n")
    
    let issues = app.issueManager.getAllIssues()
    if issues.isEmpty {
        print("No issues available.")
        return
    }
    
    print("Select an issue to delete:")
    for (index, issue) in issues.enumerated() {
        print("\(index + 1). \(issue.title) [\(issue.status.displayName)]")
    }
    print("\nEnter issue number: ", terminator: "")
    
    guard let choice = readLine(), let issueIndex = Int(choice),
          issueIndex > 0, issueIndex <= issues.count else {
        print("Invalid selection.")
        return
    }
    
    let issue = issues[issueIndex - 1]
    
    print("\nAre you sure you want to delete '\(issue.title)'? (yes/no): ", terminator: "")
    guard let confirm = readLine()?.lowercased(), confirm == "yes" || confirm == "y" else {
        print("Deletion cancelled.")
        return
    }
    
    app.deleteIssue(id: issue.id)
    print("\n✓ Issue deleted successfully!")
}

func viewIssueStatistics(app: WritersApp) {
    print("\n=== Issue Statistics ===\n")
    
    let (byStatus, byPriority) = app.getIssueStatistics()
    
    print("Issues by Status:")
    for status in IssueStatus.allCases {
        let count = byStatus[status] ?? 0
        print("  \(status.displayName): \(count)")
    }
    
    print("\nIssues by Priority:")
    for priority in IssuePriority.allCases {
        let count = byPriority[priority] ?? 0
        print("  \(priority.displayName): \(count)")
    }
    
    let totalIssues = byStatus.values.reduce(0, +)
    print("\nTotal Issues: \(totalIssues)")
}

func reopenIssue(app: WritersApp) {
    print("\n=== Reopen Issue ===\n")
    
    let issues = app.issueManager.getAllIssues().filter { $0.status == .resolved || $0.status == .closed }
    
    if issues.isEmpty {
        print("No resolved or closed issues to reopen.")
        return
    }
    
    displayIssues(issues)
    
    print("Enter issue number to reopen (0 to cancel): ", terminator: "")
    guard let input = readLine(), let choice = Int(input) else {
        print("Invalid input.")
        return
    }
    
    if choice == 0 {
        return
    }
    
    guard choice > 0 && choice <= issues.count else {
        print("Invalid issue number.")
        return
    }
    
    let issue = issues[choice - 1]
    app.reopenIssue(id: issue.id)
    print("\n✓ Issue '\(issue.title)' has been reopened.")
}

func displayIssues(_ issues: [Issue]) {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short

    for (index, issue) in issues.enumerated() {
        print("\(index + 1). \(issue.title)")
        print("   Status: \(issue.status.displayName) | Priority: \(issue.priority.displayName)")
        if !issue.description.isEmpty {
            print("   Description: \(issue.description)")
        }
        print("   Created: \(formatter.string(from: issue.metadata.created))")
        if let resolvedAt = issue.metadata.resolvedAt {
            print("   Resolved: \(formatter.string(from: resolvedAt))")
        }
        print()
    }
}

// MARK: - Hardware Board Management

func addHardwareBoard(app: WritersApp) async {
    print("\nAdd Hardware Board")
    print("==================")

    print("Board name: ", terminator: "")
    guard let name = readLine(), !name.isEmpty else {
        print("Name cannot be empty")
        return
    }

    print("\nSelect board type:")
    let types = BoardType.allCases
    for (index, type) in types.enumerated() {
        print("\(index + 1). \(type.rawValue)")
    }
    print("Choice: ", terminator: "")

    guard let choiceStr = readLine(), let choice = Int(choiceStr),
          choice > 0, choice <= types.count else {
        print("Invalid choice")
        return
    }

    let boardType = types[choice - 1]

    print("Description: ", terminator: "")
    let description = readLine() ?? ""

    print("Serial port (e.g., /dev/ttyUSB0, COM3) [optional]: ", terminator: "")
    let serialPort = readLine()

    print("Baud rate [9600]: ", terminator: "")
    let baudRateStr = readLine() ?? "9600"
    let baudRate = Int(baudRateStr) ?? 9600

    do {
        let board = try app.createHardwareBoard(
            name: name,
            type: boardType,
            description: description,
            serialPort: serialPort?.isEmpty == false ? serialPort : nil,
            baudRate: baudRate
        )
        print("\nBoard created successfully!")
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
        print("\n\(index + 1). \(board.name)")
        print("   Type: \(board.boardType.rawValue)")
        print("   Status: \(board.metadata.isActive ? "Active" : "Inactive")")
        if let port = board.serialPort {
            print("   Port: \(port)@\(board.baudRate)")
        }
        print("   Pins: \(board.pinAliases.count) configured")
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
    print("Description: \(board.description)")
    print("Transport: \(board.transportType.rawValue)")
    if let port = board.serialPort {
        print("Serial Port: \(port)")
        print("Baud Rate: \(board.baudRate)")
    }
    print("Status: \(board.metadata.isActive ? "Active" : "Inactive")")
    if let lastConnected = board.metadata.lastConnected {
        print("Last Connected: \(lastConnected)")
    }
    if let url = board.datasheetURL {
        print("Datasheet: \(url)")
    }

    print("\nPin Aliases (\(board.pinAliases.count)):")
    for pin in board.pinAliases {
        print("  - \(pin.alias) (Pin \(pin.physicalPin)): \(pin.description) [\(pin.pinType)]")
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

func managePinAliases(app: WritersApp) async {
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
        let pinType = readLine() ?? "digital"

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
                print("    \(pin.description)")
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

// MARK: - Jules Chatbot

func chatWithJules(app: WritersApp) async {
    guard let chatbot = app.chatbotService else {
        print("Error: Chatbot service not available (AI not enabled)")
        return
    }

    print("\n╔════════════════════════════════════╗")
    print("║ Jules - Your AI Writing Assistant  ║")
    if chatbot.isAdultModeEnabled {
        print("║        🔞 ADULT MODE ENABLED 🔞   ║")
    }
    print("╚════════════════════════════════════╝\n")

    var session = chatbot.startSession()
    print("Type 'exit' to end conversation\n")

    while true {
        print("You: ", terminator: "")
        guard let userInput = readLine() else {
            break
        }

        let trimmedInput = userInput.trimmingCharacters(in: .whitespaces)

        if trimmedInput.lowercased() == "exit" {
            print("\nJules: Goodbye! Happy writing! 📝\n")
            break
        }

        if trimmedInput.isEmpty {
            continue
        }

        do {
            let response = try await chatbot.sendMessage(trimmedInput, in: &session)
            print("\nJules: \(response)\n")
        } catch let error as ChatbotError {
            print("\nError: \(error.localizedDescription)\n")
        } catch {
            print("\nError: \(error.localizedDescription)\n")
        }
    }

    chatbot.endSession()
}

func toggleJulesAdultMode(app: WritersApp) {
    if app.isJulesAdultModeEnabled {
        app.disableJulesAdultMode()
        print("\n✓ Jules Adult Mode DISABLED")
        print("  Jules will use standard language filters\n")
    } else {
        app.enableJulesAdultMode()
        print("\n✓ Jules Adult Mode ENABLED")
        print("  Jules can now discuss adult content and use colorful language")
        print("  Suitable for: crime fiction, mature romance, edgy narratives, etc.\n")
    }
}

// MARK: - gui.new Visual Export

func exportStatisticsToGui(app: WritersApp) async {
    print("\n=== Export Statistics to gui.new ===\n")
    do {
        print("Publishing writing statistics dashboard...")
        let canvas = try await app.exportStatisticsToGui()
        print("✓ Dashboard published!")
        print("  URL: \(canvas.url)")
        print("  Canvas ID: \(canvas.id)")
        print("  Expires: \(canvas.expiresAt)")
        print()
        print("Share this URL to let anyone view your writing stats.")
    } catch {
        print("✗ Export failed: \(error.localizedDescription)")
    }
}

func exportDocumentToGui(app: WritersApp, searchTerm: String) async {
    print("\n=== Export Document to gui.new ===\n")
    let documents = app.documentManager.getAllDocuments()
    guard let document = documents.first(where: {
        $0.title.localizedCaseInsensitiveContains(searchTerm) ||
        $0.id.uuidString.hasPrefix(searchTerm)
    }) else {
        print("✗ No document found matching: \(searchTerm)")
        return
    }
    print("Publishing '\(document.title)'...")
    do {
        let canvas = try await app.exportDocumentToGui(id: document.id)
        print("✓ Document published!")
        print("  URL: \(canvas.url)")
        print("  Canvas ID: \(canvas.id)")
        print("  Expires: \(canvas.expiresAt)")
    } catch {
        print("✗ Export failed: \(error.localizedDescription)")
    }
}

func exportKanbanBoardToGui(app: WritersApp, searchTerm: String) async {
    print("\n=== Export Kanban Board to gui.new ===\n")
    let boards = app.getAllKanbanBoards()
    guard let board = boards.first(where: {
        $0.name.localizedCaseInsensitiveContains(searchTerm) ||
        $0.id.uuidString.hasPrefix(searchTerm)
    }) else {
        print("✗ No Kanban board found matching: \(searchTerm)")
        return
    }
    print("Publishing board '\(board.name)'...")
    do {
        let canvas = try await app.exportKanbanBoardToGui(boardId: board.id)
        print("✓ Kanban board published!")
        print("  URL: \(canvas.url)")
        print("  Canvas ID: \(canvas.id)")
        print("  Expires: \(canvas.expiresAt)")
    } catch {
        print("✗ Export failed: \(error.localizedDescription)")
    }
}

func exportDocumentToGuiInteractive(app: WritersApp) async {
    print("\n=== Export Document to gui.new ===\n")
    let documents = app.documentManager.getAllDocuments()
    if documents.isEmpty {
        print("No documents found. Create a document first.")
        return
    }
    for (i, doc) in documents.enumerated() {
        print("\(i + 1). \(doc.title) (\(doc.wordCount) words)")
    }
    print("\nSelect document number: ", terminator: "")
    guard let input = readLine(),
          let idx = Int(input), idx > 0, idx <= documents.count else {
        print("Invalid selection.")
        return
    }
    let doc = documents[idx - 1]
    print("Publishing '\(doc.title)'...")
    do {
        let canvas = try await app.exportDocumentToGui(id: doc.id)
        print("✓ Published!")
        print("  URL: \(canvas.url)")
        print("  Expires: \(canvas.expiresAt)")
    } catch {
        print("✗ Export failed: \(error.localizedDescription)")
    }
}

/// Presents an interactive CLI list of Kanban boards, lets the user choose one, and publishes the selected board to gui.new.
/// 
/// If no boards exist the function prints a message and returns. After the user selects a board it attempts to export the board via the app, printing the resulting URL and expiration on success or an error message on failure.
func exportKanbanBoardToGuiInteractive(app: WritersApp) async {
    print("\n=== Export Kanban Board to gui.new ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found. Create a board first.")
        return
    }
    for (i, board) in boards.enumerated() {
        let count = app.getKanbanTasks(forBoard: board.id).count
        print("\(i + 1). \(board.name) (\(count) tasks)")
    }
    print("\nSelect board number: ", terminator: "")
    guard let input = readLine(),
          let idx = Int(input), idx > 0, idx <= boards.count else {
        print("Invalid selection.")
        return
    }
    let board = boards[idx - 1]
    print("Publishing board '\(board.name)'...")
    do {
        let canvas = try await app.exportKanbanBoardToGui(boardId: board.id)
        print("✓ Published!")
        print("  URL: \(canvas.url)")
        print("  Expires: \(canvas.expiresAt)")
    } catch {
        print("✗ Export failed: \(error.localizedDescription)")
    }
}

/// Ingests a chosen document into Ragie and reports ingestion status.
/// 
/// Prompts the user to select a document from the app's document list, initiates ingestion into Ragie, and prints the resulting Ragie document ID and status. If Ragie is not enabled or no documents are available, prints an explanatory message and returns. On error prints the ingestion failure reason.

func ingestDocumentToRagie(app: WritersApp) async {
    guard app.isRagieEnabled else {
        print("Ragie is not enabled. Set RAGIE_API_KEY to use this feature.")
        return
    }

    let documents = app.documentManager.getAllDocuments()
    guard !documents.isEmpty else {
        print("No documents available to ingest.")
        return
    }

    print("\n=== Ingest Document into Ragie ===\n")
    for (index, doc) in documents.enumerated() {
        print("\(index + 1). \(doc.title) (\(doc.wordCount) words)")
    }
    print("\nEnter document number: ", terminator: "")

    guard let input = readLine(), let idx = Int(input), idx > 0, idx <= documents.count else {
        print("Invalid selection.")
        return
    }

    let document = documents[idx - 1]
    print("Ingesting '\(document.title)' into Ragie...")

    do {
        let ragieDoc = try await app.ingestDocumentToRagie(documentId: document.id)
        print("✓ Document ingested successfully!")
        print("  Ragie ID: \(ragieDoc.id)")
        print("  Status:   \(ragieDoc.status)")
        if !ragieDoc.isReady {
            print("  ⓘ Document is processing. Use option 98 to check when it's ready.")
        }
    } catch {
        print("✗ Ingestion failed: \(error.localizedDescription)")
    }
}

/// Retrieves contextual chunks from Ragie for a user-provided query and prints the results.
/// 
/// Prompts the user to enter a query, requests matching chunks from Ragie via the provided `WritersApp`,
/// and prints each chunk's score, source (document name or ID), and text. If Ragie is not enabled,
/// the query is empty, or no chunks are found, a user-facing message is printed instead.
/// - Parameter app: The application instance used to perform the Ragie retrieval.
func retrieveContextFromRagie(app: WritersApp) async {
    guard app.isRagieEnabled else {
        print("Ragie is not enabled. Set RAGIE_API_KEY to use this feature.")
        return
    }

    print("\n=== Retrieve Context from Ragie ===\n")
    print("Enter your query: ", terminator: "")
    guard let query = readLine(), !query.isEmpty else {
        print("Query cannot be empty.")
        return
    }

    print("Searching Ragie for: \"\(query)\"...")

    do {
        let result = try await app.retrieveFromRagie(query: query)
        if result.chunks.isEmpty {
            print("No relevant chunks found for this query.")
        } else {
            print("\nFound \(result.chunks.count) relevant chunk(s):\n")
            for (i, chunk) in result.chunks.enumerated() {
                let docName = chunk.documentName ?? chunk.documentId
                print("[\(i + 1)] Score: \(String(format: "%.3f", chunk.score))  Source: \(docName)")
                print(chunk.text)
                print()
            }
        }
    } catch {
        print("✗ Retrieval failed: \(error.localizedDescription)")
    }
}

/// Prints a formatted list of documents ingested into Ragie to the console.
/// 
/// If Ragie is not enabled, prints an explanatory message and returns early.
/// For each Ragie document it prints a readiness marker, the document name (or `"(unnamed)"`), optional chunk count, the document ID, and its status.
/// In case of an error while retrieving the list, prints a failure message with the error description.
func listRagieDocuments(app: WritersApp) async {
    guard app.isRagieEnabled else {
        print("Ragie is not enabled. Set RAGIE_API_KEY to use this feature.")
        return
    }

    print("\n=== Ragie Documents ===\n")

    do {
        let documents = try await app.listRagieDocuments()
        if documents.isEmpty {
            print("No documents ingested into Ragie yet.")
        } else {
            for doc in documents {
                let readyMark = doc.isReady ? "✓" : "⏳"
                let chunkInfo = doc.chunkCount.map { " (\($0) chunks)" } ?? ""
                let name = doc.name ?? "(unnamed)"
                print("\(readyMark) \(name)\(chunkInfo)")
                print("   ID: \(doc.id)  Status: \(doc.status)")
            }
        }
    } catch {
        print("✗ Failed to list Ragie documents: \(error.localizedDescription)")
    }
}

/// Prompt for a Ragie document ID and print the document's ingestion status and metadata.
/// 
/// This function verifies that Ragie integration is enabled, asks the user to enter a Ragie document ID,
/// retrieves the document's status from the app, and prints a ready indicator along with available metadata
/// such as the document name and chunk count. If Ragie is not enabled, the ID is empty, or the status fetch fails,
/// a corresponding message is printed.
/// - Parameter app: The WritersApp instance used to access Ragie state and retrieve document status.
func checkRagieDocumentStatus(app: WritersApp) async {
    guard app.isRagieEnabled else {
        print("Ragie is not enabled. Set RAGIE_API_KEY to use this feature.")
        return
    }

    print("\n=== Check Ragie Document Status ===\n")
    print("Enter Ragie document ID: ", terminator: "")
    guard let ragieId = readLine(), !ragieId.isEmpty else {
        print("Document ID cannot be empty.")
        return
    }

    do {
        let doc = try await app.getRagieDocumentStatus(ragieId: ragieId)
        let readyMark = doc.isReady ? "✓ Ready" : "⏳ \(doc.status.capitalized)"
        print("Status: \(readyMark)")
        if let name = doc.name { print("Name:   \(name)") }
        if let chunks = doc.chunkCount { print("Chunks: \(chunks)") }
    } catch {
        print("✗ Status check failed: \(error.localizedDescription)")
    }
}


// MARK: - Kanban Board Management

/// Creates a new Kanban board interactively.
func createKanbanBoardCLI(app: WritersApp) {
    print("\n=== Create Kanban Board ===\n")
    print("Board name: ", terminator: "")
    guard let name = readLine(), !name.isEmpty else {
        print("Board name cannot be empty.")
        return
    }
    print("Description (optional): ", terminator: "")
    let description = readLine() ?? ""
    let board = app.createKanbanBoard(name: name, description: description)
    print("\n✓ Kanban board created: \(board.name) [\(board.id.uuidString.prefix(8))]")
}

/// Lists all Kanban boards.
func listKanbanBoardsCLI(app: WritersApp) {
    print("\n=== Kanban Boards ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found. Create one with option 71.")
        return
    }
    for board in boards {
        let taskCount = app.getKanbanTasks(forBoard: board.id).count
        print("[\(board.id.uuidString.prefix(8))] \(board.name) — \(taskCount) task(s)")
        if !board.description.isEmpty {
            print("  \(board.description)")
        }
    }
}

/// Displays detailed view of a specific Kanban board.
func viewKanbanBoardCLI(app: WritersApp) {
    print("\n=== View Kanban Board ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found. Create one with option 71.")
        return
    }
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("\nSelect board (1-\(boards.count)): ", terminator: "")
    guard let input = readLine(), let choice = Int(input), choice >= 1, choice <= boards.count else {
        print("Invalid selection.")
        return
    }
    let board = boards[choice - 1]
    print("\n\(board.name)")
    if !board.description.isEmpty { print("Description: \(board.description)") }
    print(String(repeating: "-", count: 40))
    // KanbanColumn.allCases preserves declaration order: backlog → planning → running → review → done
    for column in KanbanColumn.allCases {
        let tasks = app.getKanbanTasks(forBoard: board.id, inColumn: column)
        print("\n[\(column.displayName)] (\(tasks.count))")
        for task in tasks {
            print("  • [\(task.id.uuidString.prefix(8))] \(task.title)")
            if !task.description.isEmpty { print("    \(task.description)") }
        }
    }
}

/// Adds a new task to a Kanban board.
func addKanbanTaskCLI(app: WritersApp) {
    print("\n=== Add Kanban Task ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found. Create one with option 71.")
        return
    }
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("\nSelect board (1-\(boards.count)): ", terminator: "")
    guard let boardInput = readLine(), let boardChoice = Int(boardInput),
          boardChoice >= 1, boardChoice <= boards.count else {
        print("Invalid selection.")
        return
    }
    let board = boards[boardChoice - 1]
    print("Task title: ", terminator: "")
    guard let title = readLine(), !title.isEmpty else {
        print("Task title cannot be empty.")
        return
    }
    print("Description (optional): ", terminator: "")
    let description = readLine() ?? ""
    // Prompt for initial column (KanbanColumn.allCases preserves workflow order: backlog → done)
    print("\nSelect initial column:")
    let columns = KanbanColumn.allCases
    for (index, column) in columns.enumerated() {
        let marker = index == 0 ? " (default)" : ""
        print("\(index + 1). \(column.displayName)\(marker)")
    }
    print("Choice (1-\(columns.count), default 1): ", terminator: "")
    var initialColumn: KanbanColumn = .backlog
    if let colInput = readLine(), let colChoice = Int(colInput), colChoice >= 1, colChoice <= columns.count {
        initialColumn = columns[colChoice - 1]
    }
    let task = app.createKanbanTask(boardId: board.id, title: title, description: description, column: initialColumn)
    print("\n✓ Task added to \(board.name): \(task.title) [\(task.id.uuidString.prefix(8))]")
    print("  Column: \(task.column.displayName)")
}

/// Moves a Kanban task to a different column.
func moveKanbanTaskCLI(app: WritersApp) {
    print("\n=== Move Kanban Task ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found. Create one with option 71.")
        return
    }
    for (index, board) in boards.enumerated() {
        print("\(index + 1). \(board.name)")
    }
    print("\nSelect board (1-\(boards.count)): ", terminator: "")
    guard let boardInput = readLine(), let boardChoice = Int(boardInput),
          boardChoice >= 1, boardChoice <= boards.count else {
        print("Invalid selection.")
        return
    }
    let board = boards[boardChoice - 1]
    let tasks = app.getKanbanTasks(forBoard: board.id)
    if tasks.isEmpty {
        print("No tasks on this board.")
        return
    }
    for (index, task) in tasks.enumerated() {
        print("\(index + 1). [\(task.column.displayName)] \(task.title)")
    }
    print("\nSelect task (1-\(tasks.count)): ", terminator: "")
    guard let taskInput = readLine(), let taskChoice = Int(taskInput),
          taskChoice >= 1, taskChoice <= tasks.count else {
        print("Invalid selection.")
        return
    }
    let task = tasks[taskChoice - 1]
    let columns = KanbanColumn.allCases
    print("\nSelect target column:")
    for (index, column) in columns.enumerated() {
        let marker = column == task.column ? " (current)" : ""
        print("\(index + 1). \(column.displayName)\(marker)")
    }
    print("Choice (1-\(columns.count)): ", terminator: "")
    guard let colInput = readLine(), let colChoice = Int(colInput),
          colChoice >= 1, colChoice <= columns.count else {
        print("Invalid selection.")
        return
    }
    let targetColumn = columns[colChoice - 1]
    app.moveKanbanTask(id: task.id, toColumn: targetColumn)
    print("\n✓ Task '\(task.title)' moved to \(targetColumn.displayName)")
}

/// Interactively prompts the user to select and delete a Kanban board from the application.
/// 
/// Lists all Kanban boards with their task counts, prompts for a selection number, and asks for an explicit `y` confirmation before deleting the chosen board and its tasks. If there are no boards, the selection is skipped. Invalid selection or any confirmation other than `y` cancels the operation and prints a corresponding message.
func deleteKanbanBoardCLI(app: WritersApp) {
    print("\n=== Delete Kanban Board ===\n")
    let boards = app.getAllKanbanBoards()
    if boards.isEmpty {
        print("No Kanban boards found.")
        return
    }
    for (index, board) in boards.enumerated() {
        let taskCount = app.getKanbanTasks(forBoard: board.id).count
        print("\(index + 1). \(board.name) (\(taskCount) task(s))")
    }
    print("\nSelect board to delete (1-\(boards.count)): ", terminator: "")
    guard let input = readLine(), let choice = Int(input), choice >= 1, choice <= boards.count else {
        print("Invalid selection.")
        return
    }
    let board = boards[choice - 1]
    print("Delete '\(board.name)' and all its tasks? (y/N): ", terminator: "")
    guard let confirm = readLine(), confirm.lowercased() == "y" else {
        print("Deletion cancelled.")
        return
    }
    app.deleteKanbanBoard(id: board.id)
    print("\n✓ Kanban board '\(board.name)' deleted.")
}

/// Starts a cowork session and displays its metadata and integration readiness.
/// 
/// Prints a short session identifier, the session start time, whether Gmail is enabled,
/// and readiness indicators for prospects and browser integrations.

func startCoworkSession(app: WritersApp) {
    let session = app.startCoworkSession()
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    print("\n=== Cowork Session Started ===")
    print("Session ID: \(session.id.uuidString.prefix(8))...")
    print("Started at: \(formatter.string(from: session.startedAt))")
    print("Gmail:     \(app.isGmailEnabled ? "enabled" : "disabled")")
    print("Prospects: ready")
    print("Browser:   ready")
}

/// Ends the currently active cowork session (if any) and prints a concise summary to stdout.
/// - Parameter app: The application instance used to end the session and retrieve the final session details.
func endCoworkSession(app: WritersApp) {
    guard let session = app.endCoworkSession() else {
        print("\nNo active cowork session.")
        return
    }
    print("\n=== Cowork Session Summary ===")
    let mins = session.durationMinutes.map { String(format: "%.0f min", $0) } ?? "unknown"
    print("Duration:            \(mins)")
    print("Emails sent:         \(session.emailsSent)")
    print("Prospects added:     \(session.prospectsAdded)")
    print("Prospects contacted: \(session.prospectsContacted)")
    print("Pages researched:    \(session.pagesResearched)")
    print("\nSession ended. Great work!")
}

/// Prompts the user for prospect information (name, email, optional company, role, notes, and tags), validates required fields, creates the prospect via the provided app, and prints a confirmation or validation error.
/// - Parameter app: The application instance used to persist the new prospect.
func addProspect(app: WritersApp) {
    print("\n=== Add Prospect ===\n")
    print("Name: ", terminator: "")
    guard let name = readLine(), !name.isEmpty else {
        print("Name cannot be empty.")
        return
    }
    print("Email: ", terminator: "")
    guard let email = readLine(), !email.isEmpty, email.contains("@") else {
        print("Invalid email address.")
        return
    }
    print("Company (optional): ", terminator: "")
    let company = readLine().flatMap { $0.isEmpty ? nil : $0 }
    print("Role (e.g. publisher, agent, client): ", terminator: "")
    let role = readLine().flatMap { $0.isEmpty ? nil : $0 }
    print("Notes (optional): ", terminator: "")
    let notes = readLine() ?? ""
    print("Tags (comma-separated, optional): ", terminator: "")
    let tagsInput = readLine() ?? ""
    let tags = tagsInput.isEmpty ? [] : tagsInput.components(separatedBy: ",").map {
        $0.trimmingCharacters(in: .whitespaces)
    }

    let prospect = app.addProspect(
        name: name, email: email, company: company, role: role, notes: notes, tags: tags
    )
    print("\n✓ Prospect '\(prospect.name)' added (ID: \(prospect.id.uuidString.prefix(8))...)")
}

/// Prints a formatted list of all prospects and their metadata to standard output.
/// - Parameters:
///   - app: The application instance used to retrieve prospect data. The function fetches all prospects from `app` and renders each prospect's name, company, role, email, status, optional notes, tags, and last-contacted date.
/// 
/// If no prospects exist, prints a short message indicating the database is empty and how to add a prospect; always prints a final total count.
func listProspects(app: WritersApp) {
    print("\n=== Prospect Database ===\n")
    let prospects = app.getAllProspects()
    if prospects.isEmpty {
        print("No prospects yet. Add some with option 102.")
        return
    }
    for prospect in prospects {
        let company = prospect.company.map { " @ \($0)" } ?? ""
        let role = prospect.role.map { " [\($0)]" } ?? ""
        print("• \(prospect.name)\(company)\(role)")
        print("  Email:  \(prospect.email)")
        print("  Status: \(prospect.status.displayName)")
        if !prospect.notes.isEmpty {
            print("  Notes:  \(prospect.notes)")
        }
        if !prospect.tags.isEmpty {
            print("  Tags:   \(prospect.tags.joined(separator: ", "))")
        }
        if let contacted = prospect.lastContactedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            print("  Last contacted: \(formatter.string(from: contacted))")
        }
        print()
    }
    print("Total: \(prospects.count) prospect(s)")
}

/// Prompts the user for a search query and displays matching prospects.
/// 
/// Reads a line from standard input, validates it is non-empty, performs a search via the app's prospect index, and prints either a "no matches" message or a numbered summary of matching prospects (name, optional company, email, and status).
/// 
/// Side effects: reads from stdin and writes formatted results to stdout.
func searchProspects(app: WritersApp) {
    print("\n=== Search Prospects ===\n")
    print("Search query: ", terminator: "")
    guard let query = readLine(), !query.isEmpty else {
        print("Query cannot be empty.")
        return
    }
    let results = app.searchProspects(query: query)
    if results.isEmpty {
        print("No prospects match '\(query)'.")
        return
    }
    print("\nFound \(results.count) result(s):\n")
    for prospect in results {
        let company = prospect.company.map { " @ \($0)" } ?? ""
        print("• \(prospect.name)\(company) — \(prospect.email) [\(prospect.status.displayName)]")
    }
}

/// Interactively update the status of a prospect selected from the application's prospect list.
/// 
/// Prompts the user to choose a prospect and a new status, applies the change via the provided application instance, and prints a success or error message.
func updateProspectStatus(app: WritersApp) {
    print("\n=== Update Prospect Status ===\n")
    let prospects = app.getAllProspects()
    if prospects.isEmpty {
        print("No prospects found.")
        return
    }
    for (i, p) in prospects.enumerated() {
        print("\(i + 1). \(p.name) [\(p.status.displayName)]")
    }
    print("\nSelect prospect (1-\(prospects.count)): ", terminator: "")
    guard let input = readLine(), let choice = Int(input),
          choice >= 1, choice <= prospects.count else {
        print("Invalid selection.")
        return
    }
    let prospect = prospects[choice - 1]
    let statuses = ProspectStatus.allCases
    print("\nSelect new status:")
    for (i, status) in statuses.enumerated() {
        let marker = status == prospect.status ? " (current)" : ""
        print("\(i + 1). \(status.displayName)\(marker)")
    }
    print("Choice (1-\(statuses.count)): ", terminator: "")
    guard let statusInput = readLine(), let statusChoice = Int(statusInput),
          statusChoice >= 1, statusChoice <= statuses.count else {
        print("Invalid selection.")
        return
    }
    let newStatus = statuses[statusChoice - 1]
    do {
        try app.updateProspectStatus(id: prospect.id, status: newStatus)
        print("\n✓ \(prospect.name) status updated to \(newStatus.displayName)")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

/// Prints a textual prospect pipeline summary to standard output.
/// 
/// The summary lists each prospect status with a fixed-width label, a three-digit count, an ASCII bar proportional to the count, and a final total count. The statuses are printed in the order defined by `ProspectStatus.allCases`.
func viewProspectPipelineStats(app: WritersApp) {
    print("\n=== Prospect Pipeline ===\n")
    let stats = app.getProspectStats()
    let total = stats.values.reduce(0, +)
    if total == 0 {
        print("No prospects in the pipeline yet.")
        return
    }
    for status in ProspectStatus.allCases {
        let count = stats[status] ?? 0
        let bar = String(repeating: "█", count: count)
        let label = status.displayName.padding(toLength: 20, withPad: " ", startingAt: 0)
        print("\(label) \(String(format: "%3d", count))  \(bar)")
    }
    print("\nTotal: \(total) prospect(s)")
}

/// Displays an interactive Gmail inbox listing.
///
/// Displays the user's Gmail inbox in the CLI, prompting for a maximum result count and an optional search query.
/// 
/// Prompts:
/// - Max results (defaults to 10; must be between 1 and 100).
/// - Optional search query (e.g. `from:agent@example.com`).
/// 
/// If Gmail is not enabled, prints an explanatory message and returns. Fetches messages via the app, then prints each message with a read/unread marker, subject (or “(no subject)”), sender, formatted date, and a short snippet preview. Prints a message when no messages are found and reports fetch errors when they occur.
func viewGmailInbox(app: WritersApp) async {
    print("\n=== Gmail Inbox ===\n")
    guard app.isGmailEnabled else {
        print("Gmail is not enabled. Set GMAIL_OAUTH_TOKEN and restart.")
        return
    }
    print("Max results (default 10, range 1-100): ", terminator: "")
    let maxInput = readLine() ?? ""
    let trimmedMaxInput = maxInput.trimmingCharacters(in: .whitespacesAndNewlines)
    let maxResults: Int
    if trimmedMaxInput.isEmpty {
        maxResults = 10
    } else if let value = Int(trimmedMaxInput), (1...100).contains(value) {
        maxResults = value
    } else {
        print("Invalid max results. Please enter a number between 1 and 100.")
        return
    }
    print("Search query (optional, e.g. 'from:agent@example.com'): ", terminator: "")
    let query = readLine().flatMap { $0.isEmpty ? nil : $0 }

    do {
        let messages = try await app.listGmailMessages(maxResults: maxResults, query: query)
        if messages.isEmpty {
            print("No messages found.")
            return
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        print("\nFetched \(messages.count) message(s):\n")
        for (i, msg) in messages.enumerated() {
            let readMarker = msg.isRead ? "  " : "● "
            print("\(readMarker)\(i + 1). \(msg.subject.isEmpty ? "(no subject)" : msg.subject)")
            print("     From: \(msg.from)")
            print("     Date: \(formatter.string(from: msg.date))")
            if !msg.snippet.isEmpty {
                let preview = String(msg.snippet.prefix(80))
                print("     \(preview)…")
            }
            print()
        }
    } catch {
        print("Error fetching inbox: \(error.localizedDescription)")
    }
}

/// Marks a Gmail message as read based on a user-provided message ID.
/// 
/// Prompts the user to enter a message ID, verifies that Gmail integration is enabled, and requests the app to mark that message as read. On success prints a shortened confirmation containing the message ID prefix; on failure prints the error description. If Gmail is not enabled or the provided message ID is empty, the function prints an explanatory message and returns without performing an action.
func markGmailMessageAsRead(app: WritersApp) async {
    print("\n=== Mark Email as Read ===\n")
    guard app.isGmailEnabled else {
        print("Gmail is not enabled. Set GMAIL_OAUTH_TOKEN and restart.")
        return
    }
    print("Enter message ID to mark as read: ", terminator: "")
    guard let msgId = readLine(), !msgId.isEmpty else {
        print("Message ID cannot be empty.")
        return
    }
    do {
        try await app.markGmailAsRead(id: msgId)
        print("\n✓ Message \(String(msgId.prefix(16)))... marked as read.")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

/// Presents an interactive CLI flow to compose and send an email through the app's Gmail integration.
///
/// Presents an interactive flow to compose and send an email through the app's Gmail integration.
/// 
/// Prompts the user for a recipient (must contain `@`), a non-empty subject, and a multi-line body terminated by a line containing only a single `.`. After confirmation, sends the message via the app and prints a short success message with the sent message ID or an error description.
/// 
/// Requires Gmail to be enabled in the app; if not enabled, prints an informational message and returns.
func sendGmail(app: WritersApp) async {
    print("\n=== Send Email via Gmail ===\n")
    guard app.isGmailEnabled else {
        print("Gmail is not enabled. Set GMAIL_OAUTH_TOKEN and restart.")
        return
    }
    print("To: ", terminator: "")
    guard let to = readLine(), !to.isEmpty, to.contains("@") else {
        print("Invalid recipient address.")
        return
    }
    print("Subject: ", terminator: "")
    guard let subject = readLine(), !subject.isEmpty else {
        print("Subject cannot be empty.")
        return
    }
    print("Body (end with a line containing only '.'): ")
    var lines: [String] = []
    while let line = readLine() {
        if line == "." { break }
        lines.append(line)
    }
    let body = lines.joined(separator: "\n")
    print("\nSend to \(to) with subject '\(subject)'? (y/N): ", terminator: "")
    guard let confirm = readLine(), confirm.lowercased() == "y" else {
        print("Send cancelled.")
        return
    }
    let draft = GmailDraft(to: to, subject: subject, body: body)
    do {
        let sentId = try await app.sendGmail(draft: draft)
        print("\n✓ Email sent (ID: \(sentId.prefix(16))...)")
    } catch {
        print("Error sending email: \(error.localizedDescription)")
    }
}

/// Fetches a web page, prints a short preview of its text content, and records the page in browsing history.
/// 
/// Prompts the user for a URL, retrieves the page via the app, prints the page title, URL, and up to the first 40 text lines, and reports that the page was saved to browsing history. Errors encountered during fetching are printed to standard output.
func researchURL(app: WritersApp) async {
    print("\n=== Research URL ===\n")
    print("Enter URL to fetch (https://...): ", terminator: "")
    guard let urlString = readLine(), !urlString.isEmpty else {
        print("URL cannot be empty.")
        return
    }
    do {
        print("Fetching \(urlString)...")
        let page = try await app.browseURL(urlString)
        print("\n--- \(page.title) ---")
        print("URL: \(page.url)")
        // Show first 40 non-empty lines
        let lines = page.textContent.components(separatedBy: "\n").prefix(40)
        for line in lines {
            print(line)
        }
        let totalLines = page.textContent.components(separatedBy: "\n").count
        if totalLines > 40 {
            print("\n[... \(totalLines - 40) more lines — saved to browsing history]")
        }
        print("\n✓ Page saved to browsing history (\(page.textContent.count) chars)")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

/// Displays the current browsing history and prompts the user to optionally clear it.
/// 
/// Lists each visited page with its title, URL, fetched time, and character count, then shows the total number of pages. If the user confirms by entering `y`, the history is cleared.
/// - Parameter app: The `WritersApp` instance used to retrieve and clear browsing history.
func viewBrowsingHistory(app: WritersApp) {
    print("\n=== Browsing History ===\n")
    let history = app.getBrowsingHistory()
    if history.isEmpty {
        print("No pages browsed this session. Use option 109 to research a URL.")
        return
    }
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    for (i, page) in history.enumerated() {
        print("\(i + 1). \(page.title)")
        print("   URL:     \(page.url)")
        print("   Fetched: \(formatter.string(from: page.fetchedAt))")
        print("   Size:    \(page.textContent.count) chars")
        print()
    }
    print("Total: \(history.count) page(s)")
    print("\nClear history? (y/N): ", terminator: "")
    if let input = readLine(), input.lowercased() == "y" {
        app.clearBrowsingHistory()
        print("✓ Browsing history cleared.")
    }
}
