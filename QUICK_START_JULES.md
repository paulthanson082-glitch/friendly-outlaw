# Quick Start: Chat with Jules 🤖📝

## 30-Second Setup

```bash
# 1. Set your Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-YOUR_KEY_HERE"

# 2. Run the app
swift run WritersAppCLI

# 3. Select option 17: "Chat with Jules (AI Assistant)"

# 4. Start typing!
You: I need help developing my antagonist
Jules: That's crucial to a compelling story! What genre are you writing...
```

## Interactive Chat Example

```
╔════════════════════════════════════╗
║ Jules - Your AI Writing Assistant  ║
╚════════════════════════════════════╝

Type 'exit' to end conversation

You: My protagonist is too perfect. How do I make her flawed?
Jules: Great question! Here are some compelling flaw types:

1. Internal conflicts - desires vs values (she wants love but fears trust)
2. Habits/addictions - something that sabotages her success
3. Blindspots - she's unaware of her impact on others
4. Contradictions - she's brave in crisis but cowardly in relationships
5. Consequences - her strengths create problems

Which of these interests you? Or tell me more about your character...

You: She's a detective who always solves cases but destroys relationships
Jules: Perfect! That's a rich character dynamic. Her strength (obsessive focus
on justice) becomes her weakness (inability to connect). Here are ways to deepen it:

- Show a past case that went wrong because of her emotional distance
- Add someone who challenges her (mentor, partner, love interest)
- Have a case that reveals how her methods hurt innocent people
- Force her to choose: justice or human connection

How would you like to explore this further?

You: exit
Jules: Goodbye! Happy writing! 📝
```

## Use Jules For

### 💡 Brainstorming
- **Character concepts**: "Help me develop a conflicted villain"
- **Plot ideas**: "I need plot twists for my mystery"
- **World building**: "What are good rules for magic in my world?"
- **Theme exploration**: "How can I weave 'redemption' through my story?"

### ✏️ Writing & Editing
- **Improving passages**: "This dialogue feels flat, help me revise it"
- **Overcoming blocks**: "I'm stuck on chapter 3, any ideas?"
- **Style feedback**: "Does this match my narrative voice?"
- **Pacing issues**: "This section feels rushed, how do I slow it down?"

### 🎬 Technique Help
- **Dialogue**: "How do I make my character's voice distinctive?"
- **POV**: "Should I use first or third person?"
- **Structure**: "What's a good 3-act structure for my romance?"
- **Description**: "How much detail is too much?"

### 🚀 Motivation
- **Getting unstuck**: "I haven't written in weeks, how do I start?"
- **Confidence boost**: "Is my premise strong enough?"
- **Goal setting**: "How should I structure my writing routine?"
- **Milestone celebration**: "I just finished my first draft!"

## Swift Code Usage

### Basic Conversation
```swift
import WritersApp

// Enable AI with your API key
let config = AIConfiguration(
    apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "",
    model: .claude35Sonnet
)
let app = WritersApp(aiConfiguration: config)

// Start chatting
var session = app.chatbotService!.startSession()

let response = try await app.chatbotService!.sendMessage(
    "Help me develop my character's backstory",
    in: &session
)

print("Jules: \(response)")
```

### With Document Context
```swift
// Create a conversation with your active document
let doc = app.documentManager.getAllDocuments().first!
let context = ConversationContext(
    activeDocumentId: doc.id,
    documentTitles: [doc.title],
    recentTopics: ["character", "plot"]
)

var session = app.chatbotService!.startSession(context: context)

// Jules will now reference your active document
let response = try await app.chatbotService!.sendMessage(
    "How can I strengthen this character's arc?",
    in: &session
)
```

### Multi-Turn Conversation
```swift
var session = app.chatbotService!.startSession()

// Turn 1
let r1 = try await app.chatbotService!.sendMessage(
    "What makes a good antagonist?",
    in: &session
)
print("Jules: \(r1)")

// Turn 2 - Jules remembers context!
let r2 = try await app.chatbotService!.sendMessage(
    "Can you give me an example in a fantasy setting?",
    in: &session
)
print("Jules: \(r2)")

// View full history
let history = app.chatbotService!.getConversationHistory(from: session)
print("Total messages: \(history.count)")
```

## Key Features

| Feature | Details |
|---------|---------|
| **Context Aware** | Understands your active document & writing goals |
| **Memory** | Remembers your entire conversation (up to 50 messages) |
| **Error Handling** | Clear error messages if something goes wrong |
| **Validated Input** | Rejects empty/excessively long messages |
| **Typed Errors** | Proper Swift error handling with ChatbotError |
| **Async/Await** | All operations are async for responsiveness |
| **Persistent** | Sessions stay active until you exit or call endSession() |
| **Graceful Degradation** | Works without AI key (shows friendly error) |

## Error Handling

```swift
do {
    let response = try await app.chatbotService!.sendMessage(
        userMessage,
        in: &session
    )
    print("Jules: \(response)")
} catch ChatbotError.emptyMessage {
    print("Please enter a message")
} catch ChatbotError.messageTooLong {
    print("Message is too long (max 4000 chars)")
} catch ChatbotError.aiNotAvailable {
    print("AI is not enabled - check your API key")
} catch let error as ChatbotError {
    print("Error: \(error.localizedDescription)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Advanced: Custom Context

```swift
// Provide Jules with specific context
let context = ConversationContext(
    activeDocumentId: myDocument.id,
    documentTitles: ["Chapter 1", "Chapter 2", "Chapter 3"],
    recentTopics: ["mystery", "detective", "small town"],
    userPreferences: [
        "genre": "cozy mystery",
        "tone": "humorous",
        "length": "novel"
    ]
)

var session = app.chatbotService!.startSession(context: context)

// Jules tailors responses to your preferences!
let response = try await app.chatbotService!.sendMessage(
    "What should happen next in my story?",
    in: &session
)
```

## Keyboard Shortcuts (CLI)

| Command | Action |
|---------|--------|
| `exit` | End conversation |
| `Ctrl+C` | Force exit |
| `↑ Arrow` | Previous message (terminal feature) |
| `↓ Arrow` | Next message (terminal feature) |

## Conversation Limits

- **Max message**: 4,000 characters
- **Max history**: 50 messages (automatically trimmed)
- **Response time**: Depends on API (typically 1-5 seconds)
- **Session**: Until you call `endSession()` or exit CLI

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "AI assistant not enabled" | Set ANTHROPIC_API_KEY env var |
| Jules not responding | Check internet, API key validity, try shorter message |
| Message rejected | Ensure message isn't empty or > 4000 chars |
| Session lost | Sessions persist until `endSession()` is called |

## More Information

- **Full documentation**: See `JULES.md`
- **Architecture details**: See `CLAUDE.md` section on AI Integration
- **API reference**: Check `ChatbotService` and `ChatbotModels` in code

---

**Ready to chat with Jules?** Start with `swift run WritersAppCLI` and select option 17! 🚀
