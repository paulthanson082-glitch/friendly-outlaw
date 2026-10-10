# AI Assistant Guide

## Table of Contents
1. Getting Started
2. Core Concepts
3. Implementation
4. Best Practices
5. Integration Examples

## Getting Started

### What is the AI Assistant?
The AI Assistant in friendly-outlaw provides intelligent support for users, powered by Claude's language model. It handles queries, provides recommendations, and assists with navigation.

### Quick Start
```swift
import FriendlyOutlaw

let assistant = AIAssistant(apiKey: "your-api-key")
let response = try await assistant.query("How do I get started?")
print(response.text)
```

## Core Concepts

### Assistant Architecture

**Three-tier design:**
1. **User Interface Layer** - Chat UI, input handling
2. **Logic Layer** - Query processing, context management
3. **Backend Layer** - API communication, model inference

### Key Components

#### AIAssistant
Main interface for AI interactions
```swift
class AIAssistant {
    func query(_ message: String) async throws -> AssistantResponse
    func startConversation() -> ConversationSession
    func reset()
}
```

#### ConversationSession
Maintains conversation context and history
```swift
class ConversationSession {
    var messages: [Message] = []
    var context: Context
    func addMessage(_ message: Message)
    func getContext() -> Context
}
```

#### Message
Represents a single message in the conversation
```swift
struct Message {
    let id: String
    let content: String
    let role: MessageRole  // user, assistant, system
    let timestamp: Date
    let metadata: MessageMetadata?
}
```

## Implementation

### Basic Setup

```swift
// Initialize with configuration
let config = AIAssistantConfig(
    apiKey: "your-api-key",
    model: .claude3Sonnet,
    maxTokens: 2048,
    temperature: 0.7
)

let assistant = AIAssistant(config: config)
```

### Handling Queries

```swift
func handleUserQuery(_ query: String) async {
    do {
        let response = try await assistant.query(query)
        
        // Update UI with response
        DispatchQueue.main.async {
            self.messages.append(Message(
                content: response.text,
                role: .assistant
            ))
        }
    } catch {
        // Handle error
        print("Query failed: \(error)")
    }
}
```

### Conversation Management

```swift
// Start new conversation
let session = assistant.startConversation()

// Add system context
session.context.systemPrompt = """
You are a helpful assistant for the friendly-outlaw app.
Focus on helping users navigate features and solving problems.
"""

// Maintain conversation history
session.addMessage(Message(content: "Hello", role: .user))
let response = try await assistant.query("How can you help?", session: session)
session.addMessage(Message(content: response.text, role: .assistant))
```

### Error Handling

```swift
enum AIAssistantError: Error {
    case invalidAPIKey
    case networkFailure
    case rateLimitExceeded
    case invalidResponse
    case contextTooLarge
}

do {
    let response = try await assistant.query(userInput)
} catch AIAssistantError.rateLimitExceeded {
    // Implement exponential backoff
    try await Task.sleep(nanoseconds: 2_000_000_000)
    // Retry
} catch AIAssistantError.networkFailure {
    // Show offline message
} catch {
    // Handle other errors
}
```

## Best Practices

### Performance Optimization

1. **Cache Responses** - Store frequently asked answers
```swift
let cache = ResponseCache()
if let cached = cache.get(query) {
    return cached
}
```

2. **Batch Requests** - Group multiple queries when possible
3. **Limit Context Size** - Keep conversation history reasonable
4. **Stream Responses** - Use streaming for long responses
```swift
assistant.streamQuery(query) { chunk in
    appendToDisplay(chunk)
}
```

### User Experience

1. **Loading States** - Show spinners during query processing
2. **Error Messages** - Provide clear, actionable error feedback
3. **Conversation Memory** - Maintain context across sessions
4. **Typing Indicators** - Show when assistant is thinking

### Security

1. **API Key Management**
```swift
// Store API key in Keychain, not hardcoded
let keychain = KeychainManager()
keychain.store("ai-api-key", for: "friendly-outlaw")
```

2. **Input Validation** - Sanitize user input
3. **Rate Limiting** - Implement client-side limits
4. **Data Privacy** - Don't send sensitive user data

## Integration Examples

### Chat View Integration

```swift
struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State var userInput: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                    }
                }
            }
            
            HStack {
                TextField("Ask something...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(userInput.isEmpty || viewModel.isLoading)
            }
            .padding()
        }
    }
    
    func sendMessage() {
        viewModel.sendMessage(userInput)
        userInput = ""
    }
}
```

### Context-Aware Responses

```swift
class ContextAwareAssistant: AIAssistant {
    func queryWithContext(_ message: String, context: AppContext) async throws -> AssistantResponse {
        let contextualPrompt = """
        User is currently:
        - On screen: \(context.currentScreen)
        - Has completed: \(context.completedSteps.joined(separator: ", "))
        - User preferences: \(context.userPreferences)
        
        Question: \(message)
        """
        
        return try await query(contextualPrompt)
    }
}
```

### Feedback Loop

```swift
struct FeedbackView: View {
    let response: AssistantResponse
    @State var feedback: ResponseFeedback?
    
    var body: some View {
        HStack {
            Button(action: { feedback = .helpful }) {
                Image(systemName: "hand.thumbsup")
            }
            
            Button(action: { feedback = .notHelpful }) {
                Image(systemName: "hand.thumbsdown")
            }
        }
        .onChange(of: feedback) { oldValue, newValue in
            if let newValue {
                submitFeedback(response, feedback: newValue)
            }
        }
    }
}
```

## Testing

```swift
class AIAssistantTests: XCTestCase {
    var assistant: AIAssistant!
    var mockAPI: MockAIAPI!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockAIAPI()
        assistant = AIAssistant(api: mockAPI)
    }
    
    func testSimpleQuery() async throws {
        mockAPI.mockResponse = "Hello! How can I help?"
        let response = try await assistant.query("Hi")
        XCTAssertEqual(response.text, "Hello! How can I help?")
    }
    
    func testConversationContext() async throws {
        let session = assistant.startConversation()
        session.context.systemPrompt = "You are helpful"
        
        try await assistant.query("First question", session: session)
        try await assistant.query("Follow-up", session: session)
        
        XCTAssertEqual(session.messages.count, 4) // 2 user + 2 assistant
    }
}
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Slow responses | Enable streaming, reduce context size |
| Irrelevant answers | Improve system prompt, provide more context |
| Memory usage high | Clear conversation history periodically |
| API errors | Check API key, verify network connectivity |

## Resources

- Claude API Documentation: https://docs.anthropic.com
- friendly-outlaw Repository: https://github.com/paulthanson082-glitch/friendly-outlaw
- Support: paulthanson082@gmail.com
