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

Hardware tools are invoked during Claude's tool loop with `getAIAssistanceWithTools()`:

```swift
let response = try await app.getAIAssistanceWithTools(
    documentId: doc.id,
    type: .brainstormIdeas,
    context: "Hardware control scenario",
    maxIterations: 10
)

// Claude can now call custom hardware tools during this operation
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
        case "get_board_status":
            return getStatus()
        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }

    private func readSensor(_ input: String) async throws -> String {
        // Parse input JSON
        // Query sensor data
        // Return formatted result
        return "Sensor reading: 42.5°C"
    }

    private func controlLED(_ input: String) throws -> String {
        // Parse input JSON with pin alias and state
        // Control LED
        return "LED controlled successfully"
    }

    private func getStatus() -> String {
        // Return board status information
        return "Board status: online, 5 sensors active"
    }
}
```

## Example 1: Temperature Sensor Tool

```swift
import WritersApp

class TemperatureSensorTool: AIToolExecutor {
    let boardId: UUID
    let hardwareManager: HardwareManager

    init(boardId: UUID, hardwareManager: HardwareManager) {
        self.boardId = boardId
        self.hardwareManager = hardwareManager
    }

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

        case "check_temp_alert":
            let temp = await simulateTemperatureRead()
            let threshold = extractThreshold(from: input) ?? 30.0

            if temp > threshold {
                return """
                {
                    "alert": true,
                    "temperature": \(temp),
                    "threshold": \(threshold),
                    "message": "Temperature exceeds threshold!"
                }
                """
            }
            return """
            {
                "alert": false,
                "temperature": \(temp),
                "threshold": \(threshold),
                "message": "Temperature normal"
            }
            """

        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }

    // Simulated sensor reading (replace with actual hardware communication)
    private func simulateTemperatureRead() async -> Double {
        // In production, read from actual sensor via board
        return 22.5
    }

    private func extractThreshold(from input: String) -> Double? {
        // Parse threshold from input JSON
        // { "threshold": 30.0 }
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let threshold = json["threshold"] as? NSNumber else {
            return nil
        }
        return threshold.doubleValue
    }
}

// Usage:
let executor = TemperatureSensorTool(boardId: boardId, hardwareManager: app.hardwareManager)
let response = try await app.aiService?.getAssistanceWithTools(
    text: "Is the temperature safe for electronics?",
    type: .custom("sensor_analysis"),
    tools: [
        ToolDefinition(
            name: "read_temperature",
            description: "Read current temperature from sensor",
            inputSchema: [
                "type": "object",
                "properties": [:]
            ]
        ),
        ToolDefinition(
            name: "check_temp_alert",
            description: "Check if temperature exceeds safety threshold",
            inputSchema: [
                "type": "object",
                "properties": [
                    "threshold": [
                        "type": "number",
                        "description": "Temperature threshold in Celsius"
                    ]
                ]
            ]
        )
    ],
    toolExecutor: executor,
    context: "Environmental monitoring"
) ?? ""
```

## Example 2: LED Control Tool

```swift
import WritersApp

class LEDControlTool: AIToolExecutor {
    let boardId: UUID
    let hardwareManager: HardwareManager

    init(boardId: UUID, hardwareManager: HardwareManager) {
        self.boardId = boardId
        self.hardwareManager = hardwareManager
    }

    func executeTool(name: String, input: String) async throws -> String {
        switch name {
        case "turn_on_led":
            return try turnOnLED(input)
        case "turn_off_led":
            return try turnOffLED(input)
        case "blink_led":
            return try blinkLED(input)
        case "get_led_status":
            return try getLEDStatus(input)
        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }

    private func turnOnLED(_ input: String) throws -> String {
        guard let pinAlias = extractPinAlias(from: input) else {
            throw AIServiceError.toolExecutionFailed(toolName: "turn_on_led", reason: "Invalid pin")
        }

        // Verify pin alias exists
        guard hardwareManager.getPinAlias(boardId: boardId, aliasName: pinAlias) != nil else {
            throw AIServiceError.toolExecutionFailed(toolName: "turn_on_led", reason: "Pin not found")
        }

        // Simulate LED control
        return """
        {
            "success": true,
            "action": "on",
            "pin": "\(pinAlias)",
            "state": "HIGH"
        }
        """
    }

    private func turnOffLED(_ input: String) throws -> String {
        guard let pinAlias = extractPinAlias(from: input) else {
            throw AIServiceError.toolExecutionFailed(toolName: "turn_off_led", reason: "Invalid pin")
        }

        guard hardwareManager.getPinAlias(boardId: boardId, aliasName: pinAlias) != nil else {
            throw AIServiceError.toolExecutionFailed(toolName: "turn_off_led", reason: "Pin not found")
        }

        return """
        {
            "success": true,
            "action": "off",
            "pin": "\(pinAlias)",
            "state": "LOW"
        }
        """
    }

    private func blinkLED(_ input: String) throws -> String {
        guard let pinAlias = extractPinAlias(from: input),
              let count = extractCount(from: input) ?? 3 as Int? else {
            throw AIServiceError.toolExecutionFailed(toolName: "blink_led", reason: "Invalid parameters")
        }

        return """
        {
            "success": true,
            "action": "blink",
            "pin": "\(pinAlias)",
            "count": \(count),
            "message": "LED blinked \(count) times"
        }
        """
    }

    private func getLEDStatus(_ input: String) throws -> String {
        guard let pinAlias = extractPinAlias(from: input) else {
            throw AIServiceError.toolExecutionFailed(toolName: "get_led_status", reason: "Invalid pin")
        }

        return """
        {
            "pin": "\(pinAlias)",
            "state": "LOW",
            "mode": "output",
            "voltage": "0V"
        }
        """
    }

    private func extractPinAlias(from input: String) -> String? {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pin = json["pin"] as? String else {
            return nil
        }
        return pin
    }

    private func extractCount(from input: String) -> Int? {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let count = json["count"] as? NSNumber else {
            return nil
        }
        return count.intValue
    }
}

// Usage in AI assistance:
let ledTool = LEDControlTool(boardId: board.id, hardwareManager: app.hardwareManager)
let context = """
The user wants to control their project's status LED.
Available LED pins: red_led (pin 13), green_led (pin 12), blue_led (pin 11)
"""

let response = try await app.aiService?.getAssistanceWithTools(
    text: "Turn on the red status LED and confirm it's working",
    type: .custom("hardware_control"),
    tools: [
        ToolDefinition(name: "turn_on_led", description: "Turn on an LED"),
        ToolDefinition(name: "turn_off_led", description: "Turn off an LED"),
        ToolDefinition(name: "blink_led", description: "Blink an LED N times"),
        ToolDefinition(name: "get_led_status", description: "Check LED current state")
    ],
    toolExecutor: ledTool,
    context: context
) ?? ""
```

## Example 3: Multi-Sensor Environmental Tool

```swift
import WritersApp

class EnvironmentalMonitorTool: AIToolExecutor {
    let boardId: UUID
    let hardwareManager: HardwareManager

    init(boardId: UUID, hardwareManager: HardwareManager) {
        self.boardId = boardId
        self.hardwareManager = hardwareManager
    }

    func executeTool(name: String, input: String) async throws -> String {
        switch name {
        case "read_all_sensors":
            return try await readAllSensors()
        case "get_sensor":
            return try await readSpecificSensor(input)
        case "activate_alarm":
            return try activateAlarm(input)
        default:
            throw AIServiceError.toolExecutionFailed(toolName: name, reason: "Unknown tool")
        }
    }

    private func readAllSensors() async throws -> String {
        // Simulate reading multiple sensors
        let temperature = 22.5
        let humidity = 65.0
        let pressure = 1013.25
        let light = 250

        return """
        {
            "success": true,
            "sensors": {
                "temperature_celsius": \(temperature),
                "humidity_percent": \(humidity),
                "pressure_hpa": \(pressure),
                "light_level": \(light)
            },
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))",
            "status": "All sensors operational"
        }
        """
    }

    private func readSpecificSensor(_ input: String) async throws -> String {
        guard let sensorName = extractSensorName(from: input) else {
            throw AIServiceError.toolExecutionFailed(toolName: "get_sensor", reason: "Invalid sensor")
        }

        let value: Double
        switch sensorName {
        case "temperature":
            value = 22.5
        case "humidity":
            value = 65.0
        case "pressure":
            value = 1013.25
        default:
            throw AIServiceError.toolExecutionFailed(toolName: "get_sensor", reason: "Unknown sensor")
        }

        return """
        {
            "sensor": "\(sensorName)",
            "value": \(value),
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
    }

    private func activateAlarm(_ input: String) throws -> String {
        guard let alarmType = extractAlarmType(from: input) else {
            throw AIServiceError.toolExecutionFailed(toolName: "activate_alarm", reason: "Invalid alarm type")
        }

        return """
        {
            "success": true,
            "alarm_type": "\(alarmType)",
            "duration_seconds": 10,
            "message": "Alarm activated"
        }
        """
    }

    private func extractSensorName(from input: String) -> String? {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sensor = json["sensor"] as? String else {
            return nil
        }
        return sensor
    }

    private func extractAlarmType(from input: String) -> String? {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let alarmType = json["type"] as? String else {
            return nil
        }
        return alarmType
    }
}
```

## Tool Definition Patterns

Tools must be defined with `ToolDefinition` for Claude to understand them:

```swift
// Simple tool (no parameters)
ToolDefinition(
    name: "get_board_status",
    description: "Get current status of the hardware board",
    inputSchema: ["type": "object", "properties": [:]]
)

// Tool with required parameters
ToolDefinition(
    name: "control_led",
    description: "Turn LED on or off",
    inputSchema: [
        "type": "object",
        "properties": [
            "pin": [
                "type": "string",
                "description": "LED pin alias (e.g., 'red_led')"
            ],
            "state": [
                "type": "string",
                "enum": ["on", "off"],
                "description": "LED state"
            ]
        ]
    ]
)

// Tool with optional parameters
ToolDefinition(
    name: "blink_led",
    description: "Blink an LED multiple times",
    inputSchema: [
        "type": "object",
        "properties": [
            "pin": ["type": "string", "description": "LED pin alias"],
            "count": ["type": "integer", "description": "Number of blinks (default 3)"],
            "interval_ms": ["type": "integer", "description": "Interval in ms (default 500)"]
        ]
    ]
)
```

## Best Practices

### Error Handling

```swift
func executeTool(name: String, input: String) async throws -> String {
    guard let board = hardwareManager.getBoard(id: boardId) else {
        throw AIServiceError.toolExecutionFailed(
            toolName: name,
            reason: "Board not found"
        )
    }

    // Validate input exists
    guard !input.isEmpty else {
        throw AIServiceError.toolExecutionFailed(
            toolName: name,
            reason: "Missing required input parameters"
        )
    }

    // Process...
}
```

### JSON Response Format

Keep responses structured for Claude to understand:

```swift
// Good: Structured JSON
return """
{
    "success": true,
    "action": "led_on",
    "pin": "red_led",
    "details": {
        "voltage": "5V",
        "current_ma": 20
    }
}
"""

// Avoid: Unstructured text
return "LED turned on successfully"
```

### Input Validation

```swift
private func extractAndValidateInput(from input: String) throws -> Parameters {
    guard let data = input.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw AIServiceError.toolExecutionFailed(
            toolName: "tool_name",
            reason: "Invalid JSON input"
        )
    }

    guard let requiredField = json["required_field"] else {
        throw AIServiceError.toolExecutionFailed(
            toolName: "tool_name",
            reason: "Missing 'required_field' parameter"
        )
    }

    return Parameters(value: requiredField)
}
```

## Complete Integration Example

```swift
import WritersApp

// 1. Create custom tool executor
let myTool = LEDControlTool(boardId: boardId, hardwareManager: app.hardwareManager)

// 2. Define available tools
let tools = [
    ToolDefinition(
        name: "turn_on_led",
        description: "Turn on an LED by pin alias",
        inputSchema: ["type": "object", "properties": ["pin": ["type": "string"]]]
    ),
    ToolDefinition(
        name: "turn_off_led",
        description: "Turn off an LED by pin alias",
        inputSchema: ["type": "object", "properties": ["pin": ["type": "string"]]]
    )
]

// 3. Call AI with tools
let response = try await app.getAIAssistanceWithTools(
    documentId: documentId,
    type: .custom("hardware_control"),
    context: "User wants to control LEDs on their Arduino board",
    maxIterations: 5
)

// 4. Claude automatically calls your tools during the response
// Response will include actual hardware control results
print(response)
```

## Testing Hardware Tools

```swift
func testLEDControlTool() {
    let app = WritersApp()
    let board = HardwareBoard(name: "Test", boardType: .arduinoUno)
    try? app.hardwareManager.createBoard(board)

    let tool = LEDControlTool(boardId: board.id, hardwareManager: app.hardwareManager)

    // Test tool directly
    let result = try? await tool.executeTool(
        name: "turn_on_led",
        input: #"{"pin": "red_led"}"#
    )

    print("Tool result:", result ?? "Error")
}
```

## Next Steps

- See [HARDWARE.md](../HARDWARE.md) for board management
- See [HARDWARE_SETUP.md](HARDWARE_SETUP.md) for connection instructions
- See [ADD_CUSTOM_BOARD.md](ADD_CUSTOM_BOARD.md) for custom boards
