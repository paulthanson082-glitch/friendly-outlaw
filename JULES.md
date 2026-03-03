# Jules - Your AI Personal Assistant Chatbot

Jules is an intelligent, conversational AI assistant built into the friendly-outlaw writers app. She provides real-time writing assistance, feedback, and support for all your creative endeavors.

## Features

- **Conversational Interface**: Natural, flowing dialogue with an understanding AI assistant
- **Document Context Awareness**: Jules understands your active document and can reference it in conversations
- **Persistent Conversation History**: Your conversation is maintained throughout a session
- **Writing-Focused Assistance**: Tailored responses for writers, with support for brainstorming, editing, and creative challenges
- **Encouraging & Supportive**: Jules is designed to motivate and inspire your writing journey

## Getting Started

### Prerequisites

1. An Anthropic API key (`ANTHROPIC_API_KEY` environment variable)
2. The friendly-outlaw app built and running
3. AI features enabled (automatic with valid API key)

### Starting a Chat Session

#### From the CLI

```bash
# Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Run the app
swift run WritersAppCLI

# Select option 17 from the menu: "Chat with Jules (AI Assistant)"
```

#### Interactive Conversation

Once in Jules mode, you'll see:

```
╔════════════════════════════════════╗
║ Jules - Your AI Writing Assistant  ║
╚════════════════════════════════════╝

Type 'exit' to end conversation

You:
```

Simply type your message and press Enter. Jules will respond based on her understanding of:
- Your active document
- Your recent conversation history
- Your writing context and goals

## Example Conversations

### Example 1: Brainstorming

```
You: I'm stuck on my novel. My character needs a unique flaw.
Jules: That's a great moment to develop character depth! What's the character's
profession or role in the story? And what kind of story are you writing? Knowing
whether you're writing fantasy, mystery, or contemporary fiction will help me
suggest flaws that feel authentic.

You: She's a detective in a noir setting
Jules: Perfect! For a noir detective, some compelling flaws could be:
1) Obsession with cases she can't close - haunting her personal relationships
2) Trust issues from past betrayals, making partnership difficult
3) Reliance on alcohol or another coping mechanism
4) Moral ambiguity - willing to bend rules to catch criminals

Which of these resonates with your character, or shall we explore further?
```

### Example 2: Writing Improvement

```
You: Can you help me improve this paragraph? It feels flat.
Jules: I'd love to help! Paste the paragraph and I'll give you feedback on:
- Emotional resonance
- Pacing and flow
- Descriptive language
- Dialogue (if any)
- Overall impact

What's the paragraph?

You: "She walked into the room. It was dark. She was scared."
Jules: Here's a version with more impact:
"She stepped into the darkness, her heart hammering against her ribs as her eyes
struggled to adjust. Fear coiled in her chest, a familiar companion."

The improvements:
- "stepped into" vs "walked into" - more intentional
- Added sensory details (heart hammering, struggling eyes)
- Changed "was dark/scared" to show emotion through physical sensation
- More vivid verbs and imagery

Try rewriting it in your own voice!
```

### Example 3: Overcoming Writer's Block

```
You: I have no idea what to write about today.
Jules: Writer's block is temporary! Let's spark some ideas. Tell me:
1) What genre do you usually enjoy writing?
2) What's a topic you've been curious about lately?
3) Is there a character or scenario that's been stuck in your head?

Even one answer can get us rolling!

You: I like mystery and I've been thinking about inheritance disputes
Jules: Inheritance disputes are goldmines for mystery! Here are some starting points:
- A mysterious will that contradicts everything the family thought they knew
- A hidden beneficiary suddenly appears, challenging the legitimacy
- Someone discovers a second will - authentic or forgery?
- A detective investigating the death uncovers secrets tied to the estate

Which angle interests you most?
```

## Architecture

Jules is built on a clean, modular architecture:

### Models (`ChatbotModels.swift`)
- **`ChatMessage`**: Individual messages in the conversation
  - Properties: `id`, `role` (user/assistant), `content`, `timestamp`
  - Conforms to `Identifiable` and `Codable` for persistence

- **`ConversationSession`**: Tracks a full conversation
  - Properties: `id`, `startedAt`, `lastMessageAt`, `messages`, `context`
  - Maintains conversation history and contextual information

- **`ConversationContext`**: Provides awareness
  - Properties: `activeDocumentId`, `documentTitles`, `recentTopics`, `userPreferences`
  - Helps Jules understand your writing environment

- **`ChatbotError`**: Typed error handling
  - `emptyMessage`, `messageTooLong`, `aiNotAvailable`, `documentNotFound`, `conversationLimitExceeded`, `invalidContext`, `aiServiceFailed`

### Service (`ChatbotService.swift`)
- **`ChatbotService`**: Orchestrates conversations
  - Maintains conversation state and history
  - Validates user input (length, emptiness)
  - Constructs contextual prompts for Claude
  - Manages session lifecycle

Key methods:
```swift
// Start a new conversation
public func startSession(context: ConversationContext? = nil) -> ConversationSession

// Send a message and get a response
public func sendMessage(_ userMessage: String, in session: inout ConversationSession) async throws -> String

// Retrieve conversation history
public func getConversationHistory(from session: ConversationSession) -> [ChatMessage]

// Clear conversation history (keep context)
public func clearHistory(for session: inout ConversationSession)

// End the current session
public func endSession()
```

### Integration

Jules is seamlessly integrated into WritersApp:

```swift
// When AI is enabled, chatbotService is automatically created
app.enableAI(configuration: config)
let chatbot = app.chatbotService  // Now available

// When AI is disabled, chatbot is also disabled
app.disableAI()  // chatbotService becomes nil
```

### CLI (`main.swift`)
- Option 17 launches interactive chat mode
- Multi-turn conversation loop
- "exit" command ends session gracefully

## Code Examples

### Basic Usage (Swift)

```swift
import WritersApp

// Create app with AI enabled
let config = AIConfiguration(apiKey: "sk-ant-...", model: .claude35Sonnet)
let app = WritersApp(aiConfiguration: config)

// Create a conversation with context
let context = ConversationContext(
    activeDocumentId: myDocument.id,
    documentTitles: ["Chapter 1", "Chapter 2"],
    recentTopics: ["character development"]
)

var session = app.chatbotService!.startSession(context: context)

// Send a message
let response = try await app.chatbotService!.sendMessage(
    "I'm struggling with my antagonist's motivation",
    in: &session
)

print("Jules: \(response)")

// View conversation history
let history = app.chatbotService!.getConversationHistory(from: session)
print("Messages in session: \(history.count)")

// End session
app.chatbotService?.endSession()
```

### CLI Usage (Bash)

```bash
# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Run the app
swift run WritersAppCLI

# At main menu, enter: 17
# Then start typing your messages!
```

## Configuration

### Environment Variables

```bash
# Required
ANTHROPIC_API_KEY="sk-ant-..."

# Optional (for alternative LLM providers)
ANTHROPIC_BASE_URL="https://..."
ANTHROPIC_AUTH_TOKEN="..."
```

### Chatbot Settings

Adjust in `ChatbotService` initialization:

```swift
ChatbotService(
    aiService: aiSvc,
    documentManager: docMgr,
    templateManager: tmplMgr,
    maxHistoryMessages: 50,        // Trim conversations at 50 messages
    maxMessageLength: 4000          // Reject messages longer than 4000 chars
)
```

## Conversation Limits

- **Max message length**: 4,000 characters
- **Max history**: 50 messages (automatically trimmed)
- **Session timeout**: None (sessions persist until explicitly ended)
- **Context window**: Configurable via AIConfiguration

## Error Handling

Jules provides clear, user-friendly error messages:

```
"Please enter a message."                    # Empty message
"Message exceeds maximum length."            # Message too long
"The AI assistant is not enabled..."        # AI not configured
"Invalid conversation context."              # Context issue
"AI service error: [reason]"                # API or service failure
```

## Testing

Jules includes comprehensive test coverage (18+ tests):

```bash
swift test WritersAppTests
```

Test categories:
- **Initialization**: Chatbot creation and setup
- **Input Validation**: Empty/long message handling
- **Conversation Management**: History, context, session lifecycle
- **Data Persistence**: Codable conformance for messages and sessions
- **Error Handling**: Proper error propagation

## Best Practices

1. **Always provide context**: Tell Jules about your document or writing goals
2. **Be specific**: "Help me develop my protagonist" is better than "Help me write"
3. **Follow up**: Jules remembers your conversation; build on previous responses
4. **Use for multiple purposes**: Brainstorming, editing, analysis, motivation
5. **Clear history when changing topics**: Use `clearHistory()` to reset context

## Troubleshooting

### "AI features disabled"
- Ensure `ANTHROPIC_API_KEY` is set in environment
- Verify the key is valid (starts with `sk-ant-`)

### Jules not responding
- Check internet connection
- Verify API key has credits
- Try a shorter message
- Check for rate limits on your API key

### Conversation feels repetitive
- Use `clearHistory()` to reset the conversation
- Start a new session with updated context
- Try being more specific in your questions

### Session crashes
- Ensure messages aren't excessively long
- Verify document context still exists
- Try starting a new session

## Future Enhancements

Potential additions for Jules:
- [ ] Persistent conversation storage to SQLite
- [ ] Multi-user conversation history
- [ ] Custom personality/style preferences
- [ ] Integration with version control for document awareness
- [ ] Motivation tracking and milestone suggestions
- [ ] Memory plugin integration for long-term context
- [ ] Streaming responses for faster feedback
- [ ] Voice input/output support

## Support

For issues or feedback:
1. Check the troubleshooting section above
2. Review conversation context and input validation
3. Inspect error messages for specific errors
4. Refer to CLAUDE.md for architectural details

## Summary

Jules is your intelligent writing companion, available 24/7 to help you:
- ✨ Brainstorm ideas
- 📝 Develop characters
- 🏗️ Structure narratives
- ✅ Edit and improve
- 💪 Stay motivated
- 🎯 Overcome blocks

Start chatting with Jules today and elevate your writing!
