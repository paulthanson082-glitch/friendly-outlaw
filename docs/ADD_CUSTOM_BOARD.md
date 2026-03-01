# Adding Custom Hardware Boards

This guide explains how to define and configure custom hardware boards beyond the pre-configured templates.

## Overview

A custom board can be any microcontroller, development board, or GPIO platform not in the default list. friendly-outlaw supports custom boards through the `BoardType.custom` enum case and flexible pin aliasing.

## Custom Board Structure

```swift
let myCustomBoard = HardwareBoard(
    name: "My Project Board",
    boardType: .custom,
    description: "Custom sensor interface board",
    serialPort: "/dev/ttyUSB0",
    baudRate: 115200,
    transportType: .serial,
    pinAliases: [
        // Define all your pins here
    ],
    metadata: HardwareBoardMetadata(
        tags: ["custom", "sensor-board"],
        notes: "Built for plant monitoring project"
    )
)
```

## Defining Pin Aliases

```swift
let aliases: [PinAlias] = [
    // Digital outputs
    PinAlias(alias: "pump_relay", physicalPin: 8, description: "Water pump relay", pinType: "digital"),
    PinAlias(alias: "grow_light", physicalPin: 9, description: "LED grow light (PWM)", pinType: "pwm"),

    // Analog inputs
    PinAlias(alias: "temp_sensor", physicalPin: 0, description: "Temperature (TMP36)", pinType: "analog"),
    PinAlias(alias: "humidity_sensor", physicalPin: 1, description: "Humidity sensor", pinType: "analog"),

    // Communication
    PinAlias(alias: "i2c_sda", physicalPin: 20, description: "I2C SDA", pinType: "digital"),
    PinAlias(alias: "i2c_scl", physicalPin: 21, description: "I2C SCL", pinType: "digital"),
]
```

## Pin Types

| Type | Description | Use Case |
|------|-------------|----------|
| `digital` | On/off pins | LEDs, relays, buttons |
| `analog` | 0-5V input pins | Sensors, potentiometers |
| `pwm` | Pulse-width modulation | Dimmers, variable output |

## CLI Method

1. Select "Add Hardware Board" (option 80)
2. Enter board name: "My Custom Board"
3. Select board type: "custom" (last option)
4. Enter description and serial port
5. Use option 84 to add pin aliases

## Best Practices

- Use descriptive alias names: `soil_moisture_sensor` not `sensor1`
- Group related pins logically in your code
- Include comprehensive metadata with tags and notes
- Add datasheet URL for reference

See [HARDWARE.md](../HARDWARE.md) for more and [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI integration.
