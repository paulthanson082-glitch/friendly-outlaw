# Writers App - Swift Playground

An interactive Swift Playground for exploring writing app features with AI-powered assistance.

## 🚀 Getting Started

### Option 1: Xcode (Recommended)
1. Open `WritersApp.playground` in Xcode
2. The playground will execute automatically
3. View results in the sidebar and console

### Option 2: Swift Playgrounds App
1. Open with Swift Playgrounds app on Mac or iPad
2. Explore and modify the code interactively
3. Run to see results

## 📚 What's Inside

### Core Features
- **Template System**: 7+ pre-built writing templates
- **Document Management**: Create, edit, and organize documents
- **Word Count Tracking**: Automatic word/character counting
- **Search Functionality**: Find templates and documents
- **Statistics**: Track your writing progress
- **AI Integration**: Optional Claude API integration

### Interactive Examples

The playground includes 6 ready-to-run examples:

1. **Create the App** - Initialize the Writers App
2. **Browse Templates** - See all available templates
3. **Create from Template** - Make a document from a template
4. **Create Blank Document** - Start with a blank slate
5. **Search Templates** - Find templates by keyword
6. **Get Statistics** - View writing statistics

## 🤖 AI Features (Optional)

To use AI-powered features:

1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. Uncomment the AI section in the playground
3. Replace `"your-anthropic-api-key-here"` with your actual key
4. Run the playground

### Available AI Features:
- Continue Writing
- Improve Text
- Grammar Check
- Generate Outline
- Brainstorm Ideas
- Character Development
- Title Generation
- Summarize Text

## 💡 Try These Challenges

### Challenge 1: Create Your Own Template
```swift
let myTemplate = Template(
    name: "Recipe Card",
    description: "A template for cooking recipes",
    category: .other,
    content: """
    # {{recipe_name}}

    Prep time: {{prep_time}}
    Cook time: {{cook_time}}

    ## Ingredients
    {{ingredients}}

    ## Instructions
    {{instructions}}
    """,
    placeholders: [
        TemplatePlaceholder(key: "recipe_name", label: "Recipe Name"),
        TemplatePlaceholder(key: "prep_time", label: "Prep Time"),
        TemplatePlaceholder(key: "cook_time", label: "Cook Time"),
        TemplatePlaceholder(key: "ingredients", label: "Ingredients"),
        TemplatePlaceholder(key: "instructions", label: "Instructions")
    ]
)
app.templateManager.addTemplate(myTemplate)
```

### Challenge 2: Bulk Document Creation
Create 5 documents with different content and analyze the statistics.

### Challenge 3: AI Writing Assistant
Use AI to:
1. Generate an outline for a story
2. Create the first chapter
3. Use "Continue Writing" to extend it
4. Use "Improve Text" to enhance it

## 📖 Code Structure

```
Playground
├── Models
│   ├── TemplateCategory
│   ├── Template
│   ├── Document
│   └── AIConfiguration
├── Services
│   ├── TemplateManager
│   ├── DocumentManager
│   └── AIService
└── WritersApp (Main Class)
```

## 🎯 Learning Objectives

By exploring this playground, you'll learn:

1. **Swift Basics**
   - Structs and Classes
   - Enums with associated values
   - Optionals and error handling
   - Async/await for AI operations

2. **App Architecture**
   - Service layer pattern
   - Manager classes
   - Separation of concerns

3. **API Integration**
   - URLSession and async requests
   - JSON serialization
   - Error handling

4. **Data Management**
   - Dictionary-based storage
   - CRUD operations
   - Search and filtering

## 🔧 Customization Ideas

### Add New Template Categories
```swift
case recipe = "Recipe"
case script = "Script"
case resume = "Resume"
```

### Extend Document Metadata
```swift
public var author: String?
public var keywords: [String]
public var readingDifficulty: Int?
```

### Add Export Functionality
```swift
func exportAsMarkdown(document: Document) -> String
func exportAsHTML(document: Document) -> String
func exportAsPDF(document: Document) -> Data
```

## 📱 Platform Compatibility

- ✅ macOS 13.0+
- ✅ iOS 16.0+ (Swift Playgrounds app)
- ✅ Xcode 14.0+
- ✅ Swift 5.9+

## 🚦 Quick Tips

1. **View Output**: Check the console (Cmd+Shift+Y) for print statements
2. **Modify Examples**: Change values and re-run to see different results
3. **Add Code**: Write your own examples below the provided ones
4. **Debug**: Use `print()` statements to understand code flow
5. **Async Code**: Remember to use `await` for AI operations

## 🆘 Troubleshooting

### Playground Not Running
- Ensure auto-execution is enabled (Editor > Automatically Run)
- Manually run: Cmd+Shift+Return

### AI Features Not Working
- Check your API key is correct
- Ensure you have internet connection
- Verify the API key has proper permissions
- Check Anthropic API status

### Can't See Output
- Open console: View > Debug Area > Show Debug Area
- Check the sidebar for inline results

## 📚 Additional Resources

- [Swift Playgrounds Documentation](https://developer.apple.com/swift-playgrounds/)
- [Anthropic Claude API Docs](https://docs.anthropic.com/)
- [Swift Async/Await Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 🎓 Next Steps

1. Complete all the challenges
2. Create your own custom templates
3. Build a small writing project
4. Experiment with AI features
5. Share your creations!

Happy coding and writing! ✍️
