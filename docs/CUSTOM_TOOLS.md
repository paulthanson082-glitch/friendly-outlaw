# Building Custom Hardware Tools for AI

This guide explains how to create custom hardware tools that Claude can invoke during AI tool loops to interact with your boards, sensors, and actuators.

## Overview

Custom hardware tools allow Claude to:
- Read sensor values from your boards
- Control actuators (LEDs, motors, relays)
- Query board status and configuration
- Execute complex hardware operations
- Integrate hardware control with writing assistance

## Tool Loop Integration

Hardware tools are invoked during Claude's tool loop:

```swift
let response = try await app.aiService?.getAssistanceWithTools(
    text: "Is the temperature safe for electronics?",
    type: .custom("sensor_analysis"),
    tools: myToolDefinitions
)
```

## Creating a Hardware Tool

### Tool Structure

A hardware tool must implement the `AIToolExecutor` protocol:

```swift
public protocol AIToolExecutor {
    func executeTool(name: String, input: String) async throws -> String
}
```

### Basic Tool Template

```swift
class MyHardwareToolExecutor: AIToolExecutor {
    let hardwareManager: HardwareManager
    let boardId: UUID

    init(hardwareManager: HardwareManager, boardId: UUID) {
        self.hardwareManager = hardwareManager
        self.boardId = boardId
    }

    func executeTool(name: String, input: String) async throws -> String {
        switch name {
        case "read_sensor":
            return try await readSensor(input)
        case "control_led":
            return try controlLED(input)
        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }
}
```

## Example: Temperature Sensor Tool

```swift
class TemperatureSensorTool: AIToolExecutor {
    func executeTool(name: String, input: String) async throws -> String {
        switch name {
        case "read_temperature":
            let temperature = await simulateTemperatureRead()
            return """
            {
                "success": true,
                "temperature": \(temperature),
                "unit": "celsius",
                "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
            }
            """
        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }

    private func simulateTemperatureRead() async -> Double {
        // Replace with actual hardware communication
        return 22.5
    }
}
```

## Tool Definition Patterns

```swift
// Simple tool (no parameters)
ToolDefinition(
    name: "get_board_status",
    description: "Get current status of the hardware board",
    inputSchema: ["type": "object", "properties": [:]]
)

// Tool with parameters
ToolDefinition(
    name: "control_led",
    description: "Turn LED on or off",
    inputSchema: [
        "type": "object",
        "properties": [
            "pin": ["type": "string", "description": "LED pin alias (e.g., 'red_led')"],
            "state": ["type": "string", "enum": ["on", "off"]]
        ]
    ]
)
```

## Best Practices

### JSON Response Format

```swift
// Good: Structured JSON
return """
{
    "success": true,
    "action": "led_on",
    "pin": "red_led"
}
"""
```

### Error Handling

```swift
func executeTool(name: String, input: String) async throws -> String {
    guard let board = hardwareManager.getBoard(id: boardId) else {
        throw AIServiceError.toolExecutionFailed(
            toolName: name,
            reason: "Board not found"
        )
    }
    // Process...
}
```

## Next Steps

- See [HARDWARE.md](../HARDWARE.md) for board management
- See [HARDWARE_SETUP.md](HARDWARE_SETUP.md) for connection instructions
- See [ADD_CUSTOM_BOARD.md](ADD_CUSTOM_BOARD.md) for custom boards
