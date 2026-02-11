# OpenClaw Integration Guide

This document explains the integration between the Friendly Outlaw Writers App and the OpenClaw gateway runtime.

## Overview

The OpenClaw plugin enables the Friendly Outlaw Writers App to stream real-time observations to messaging channels (Telegram, Discord, Signal, Slack, WhatsApp, Line). This allows writers to receive notifications about their writing progress, document updates, and AI assistance usage directly in their preferred messaging app.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Friendly Outlaw Writers App (Swift)                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Services                                               │    │
│  │  - DocumentManager                                      │    │
│  │  - AIService                                           │    │
│  │  - FocusSessionManager                                 │    │
│  │  - PluginManager                                       │    │
│  └────────────────────────────────────────────────────────┘    │
│                           ↓                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  HTTP/SSE Server (Port 37777)                          │    │
│  │  - GET /stream → Server-Sent Events                    │    │
│  │  - Emits: new_observation events                       │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                           ↓ SSE
┌─────────────────────────────────────────────────────────────────┐
│  OpenClaw Plugin (TypeScript/Node.js)                           │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  SSE Consumer                                          │    │
│  │  - Connects to /stream endpoint                        │    │
│  │  - Parses new_observation events                       │    │
│  │  - Formats observations for display                    │    │
│  │  - Handles reconnection with exponential backoff       │    │
│  └────────────────────────────────────────────────────────┘    │
│                           ↓                                      │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Channel Router                                        │    │
│  │  - Routes to appropriate channel API                   │    │
│  │  - Handles channel-specific formatting                 │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  OpenClaw Runtime                                               │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Channel Integrations                                  │    │
│  │  - Telegram Bot API                                    │    │
│  │  - Discord Webhooks                                    │    │
│  │  - Signal CLI                                          │    │
│  │  - Slack API                                           │    │
│  │  - WhatsApp Business API                               │    │
│  │  - Line Messaging API                                  │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                           ↓
         Messaging Channel (Telegram, Discord, etc.)
```

## Components

### 1. Writers App SSE Server

The Writers App needs to implement an HTTP server with Server-Sent Events support:

**Endpoint**: `GET /stream`

**Response Headers**:
```
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
```

**Event Format**:
```
data: {"type":"new_observation","title":"Document Created","subtitle":"Novel Chapter 1","timestamp":"2024-01-01T12:00:00Z"}

```

**Event Types**:
- `new_observation` - New writing observation occurred

**Observation Fields**:
- `type` (required) - Always "new_observation"
- `title` (required) - Short description (e.g., "Document Created", "Word Goal Reached")
- `subtitle` (optional) - Additional context (e.g., "Added 500 words", "Chapter 3")
- `timestamp` (optional) - ISO 8601 timestamp

### 2. OpenClaw Plugin

Located in `openclaw/` directory, the plugin:

1. **Registers a Service**: `friendly-outlaw-observation-feed`
   - Lifecycle: Start/Stop methods
   - Connects to Writers App SSE stream
   - Automatically reconnects on failure

2. **Registers a Command**: `/friendly-outlaw-feed`
   - Shows connection status
   - Displays configuration
   - Reports reconnection attempts

3. **Handles Events**:
   - Parses SSE frames
   - Extracts observation data
   - Formats messages
   - Routes to configured channel

### 3. OpenClaw Runtime

Provides the channel integration APIs that the plugin uses to send messages.

## Observation Types

The Writers App should emit observations for these events:

### Document Events
- **Document Created**: New document from template or blank
- **Document Updated**: Content modified
- **Document Exported**: Document exported to format (Markdown, HTML, etc.)
- **Document Deleted**: Document removed

### Writing Progress
- **Word Goal Reached**: Word count milestone achieved
- **Writing Session Started**: Focus session begins
- **Writing Session Completed**: Focus session ends with statistics
- **Streak Milestone**: Consecutive days writing goal met

### AI Assistance
- **AI Continuation**: AI continued writing
- **AI Improvement**: AI improved text quality
- **AI Analysis**: AI analyzed document
- **Character Development**: AI developed character
- **Outline Generated**: AI created outline

### Analytics
- **Productivity Milestone**: Total words across all documents
- **Project Milestone**: Project-specific achievement

## Implementation in Writers App

### Option 1: Swift HTTP Server

Add an HTTP server to the Writers App that exposes the `/stream` endpoint:

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class ObservationServer {
    private var server: HTTPServer?
    private let port: Int
    private var clients: [SSEClient] = []
    
    init(port: Int = 37777) {
        self.port = port
    }
    
    func start() {
        // Start HTTP server on configured port
        // Handle /stream endpoint with SSE
    }
    
    func emitObservation(title: String, subtitle: String? = nil) {
        let observation = ObservationEvent(
            type: "new_observation",
            title: title,
            subtitle: subtitle,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        // Send to all connected SSE clients
        let data = try? JSONEncoder().encode(observation)
        let message = "data: \(String(data: data!, encoding: .utf8)!)\n\n"
        
        for client in clients {
            client.send(message)
        }
    }
}

struct ObservationEvent: Codable {
    let type: String
    let title: String
    let subtitle: String?
    let timestamp: String
}
```

### Option 2: Use Existing Plugin System

Integrate with the existing Swift plugin architecture:

```swift
// In PluginManager or WritersApp
public func emitObservation(title: String, subtitle: String? = nil) {
    // Notify all registered plugins via the plugin manager
    let observation = [
        "type": "new_observation",
        "title": title,
        "subtitle": subtitle ?? "",
        "timestamp": ISO8601DateFormatter().string(from: Date())
    ]
    
    // If HTTP server is running, broadcast via SSE
    observationServer?.broadcast(observation)
}
```

### Integration Points

Add observation emissions at key points in the Writers App:

```swift
// When creating a document
func createDocument(...) -> Document {
    let doc = // ... create document
    
    emitObservation(
        title: "Document Created",
        subtitle: doc.title
    )
    
    return doc
}

// When reaching word count goal
func checkWordCountGoal(document: Document) {
    if document.wordCount >= document.metadata.wordCountGoal {
        emitObservation(
            title: "Word Goal Reached!",
            subtitle: "\(document.wordCount) words in \(document.title)"
        )
    }
}

// When AI assists
func continueWriting(...) async throws -> String {
    let result = // ... AI generation
    
    emitObservation(
        title: "AI Continued Writing",
        subtitle: "Added \(result.wordCount) words"
    )
    
    return result
}
```

## Configuration

### Writers App Configuration

Add to your Writers App configuration:

```swift
struct WritersAppConfig {
    var observationServerEnabled: Bool = true
    var observationServerPort: Int = 37777
    // ... other config
}
```

### OpenClaw Configuration

Add to `openclaw.json`:

```json
{
  "plugins": {
    "friendly-outlaw": {
      "workerPort": 37777,
      "project": "my-novel",
      "observationFeed": {
        "enabled": true,
        "channel": "telegram",
        "to": "123456789"
      }
    }
  }
}
```

## Security Considerations

1. **Local Only**: The SSE server should only listen on localhost (127.0.0.1) for security
2. **No Authentication**: Since it's localhost-only, authentication is not required
3. **Rate Limiting**: Consider limiting observation frequency to avoid spam
4. **PII Protection**: Don't include document content in observations, only metadata

## Testing

### Manual Testing

1. Start Writers App with observation server enabled:
```bash
swift run WritersAppCLI --enable-observations
```

2. Start OpenClaw with plugin:
```bash
openclaw start
```

3. Create a document in Writers App:
```bash
# In another terminal
curl http://localhost:37777/stream
```

4. Verify observation appears in configured channel

### Automated Testing

Use the provided E2E tests:

```bash
cd openclaw/
./test-e2e.sh
```

## Troubleshooting

### SSE Connection Refused

- Verify Writers App is running
- Check that observation server is enabled
- Confirm port matches configuration (default: 37777)
- Check firewall settings

### No Observations Appearing

- Verify OpenClaw plugin is loaded
- Check channel configuration is correct
- Ensure channel integration is set up in OpenClaw
- Review OpenClaw logs for errors

### Reconnection Issues

- Check Writers App stability
- Monitor for crashes or restarts
- Review plugin logs for reconnection attempts

## Future Enhancements

Potential future improvements:

1. **Bidirectional Communication**: Allow commands from messaging channels
2. **Rich Formatting**: Support Markdown in observation messages
3. **Attachments**: Send document previews or exports
4. **Filters**: Configure which observation types to stream
5. **Multiple Projects**: Support multiple Writers App instances
6. **WebSocket Support**: Alternative to SSE for bidirectional communication
7. **Persistence**: Store observations for later retrieval

## Related Documentation

- [OpenClaw Plugin README](openclaw/README.md) - Plugin-specific documentation
- [OpenClaw Testing Guide](openclaw/TESTING.md) - Testing procedures
- [Writers App Plugin System](Sources/WritersApp/Plugins/) - Swift plugin architecture
- [DATABASE.md](DATABASE.md) - Writers App database schema

## Support

For issues related to:
- **Plugin**: See [openclaw/README.md](openclaw/README.md)
- **Writers App**: See [README.md](README.md)
- **OpenClaw Runtime**: Refer to OpenClaw documentation
