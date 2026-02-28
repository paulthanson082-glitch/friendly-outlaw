# Adding Custom Hardware Boards

This guide explains how to define and configure custom hardware boards beyond the pre-configured templates.

## Overview

A custom board can be any microcontroller, development board, or GPIO platform not in the default list. friendly-outlaw supports custom boards through the `BoardType.custom` enum case and flexible pin aliasing.

## When to Add a Custom Board

Use a custom board definition when:
- You have a specialized development board
- You're combining boards (multiplexing multiple boards)
- You want to create a named configuration for your specific project
- You're using a breakout board or HAT (Hardware Attached on Top)

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
    datasheetURL: "https://example.com/datasheet.pdf",
    metadata: HardwareBoardMetadata(
        tags: ["custom", "sensor-board"],
        notes: "Built for plant monitoring project"
    )
)
```

## Defining Pin Aliases

Pin aliases map human-readable names to physical pin numbers:

```swift
// Format: PinAlias(alias: String, physicalPin: Int, description: String, pinType: String)

let aliases: [PinAlias] = [
    // Digital outputs
    PinAlias(alias: "pump_relay", physicalPin: 8, description: "Water pump relay", pinType: "digital"),
    PinAlias(alias: "grow_light", physicalPin: 9, description: "LED grow light (PWM)", pinType: "pwm"),

    // Digital inputs
    PinAlias(alias: "soil_moisture_digital", physicalPin: 7, description: "Soil moisture sensor (digital)", pinType: "digital"),
    PinAlias(alias: "water_level", physicalPin: 6, description: "Water level sensor", pinType: "digital"),

    // Analog inputs
    PinAlias(alias: "temp_sensor", physicalPin: 0, description: "Temperature (TMP36)", pinType: "analog"),
    PinAlias(alias: "humidity_sensor", physicalPin: 1, description: "Humidity sensor", pinType: "analog"),
    PinAlias(alias: "soil_moisture_analog", physicalPin: 2, description: "Soil moisture analog", pinType: "analog"),

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
| `i2c` | I2C communication | Sensors, displays |
| `spi` | SPI communication | SD cards, EEPROM |
| `uart` | Serial communication | GPS, Bluetooth modules |

## Example 1: Plant Monitoring System

```swift
// Create custom board for automated plant care

let plantBoardAliases: [PinAlias] = [
    // Sensors
    PinAlias(alias: "soil_moisture", physicalPin: A0, description: "Soil moisture analog sensor", pinType: "analog"),
    PinAlias(alias: "temp_humidity", physicalPin: 2, description: "DHT22 data pin", pinType: "digital"),
    PinAlias(alias: "light_sensor", physicalPin: A1, description: "Light level sensor", pinType: "analog"),

    // Actuators
    PinAlias(alias: "water_pump", physicalPin: 3, description: "Water pump relay (PWM)", pinType: "pwm"),
    PinAlias(alias: "grow_light", physicalPin: 5, description: "LED grow light (PWM)", pinType: "pwm"),
    PinAlias(alias: "cooling_fan", physicalPin: 6, description: "Cooling fan relay", pinType: "digital"),

    // Status
    PinAlias(alias: "status_led", physicalPin: 13, description: "Status indicator", pinType: "digital"),
]

let plantBoard = HardwareBoard(
    name: "Plant Care Automation",
    boardType: .custom,
    description: "Automated watering, lighting, and environmental control",
    serialPort: "/dev/ttyUSB0",
    baudRate: 9600,
    transportType: .serial,
    pinAliases: plantBoardAliases,
    datasheetURL: nil,
    metadata: HardwareBoardMetadata(
        tags: ["agriculture", "IoT", "sensor-array"],
        notes: "Deployed in greenhouse 2, monitoring 12 plants"
    )
)

// Create via CLI or programmatically
try app.hardwareManager.createBoard(plantBoard)
```

## Example 2: Multi-Board Configuration

Combine multiple boards under one logical project:

```swift
// Main Arduino board
let mainBoard = HardwareBoard(
    name: "Lab Control Board",
    boardType: .arduinoUno,
    serialPort: "/dev/ttyUSB0",
    baudRate: 9600,
    pinAliases: [
        PinAlias(alias: "heater_relay", physicalPin: 8, description: "Heating element", pinType: "digital"),
        PinAlias(alias: "pump_control", physicalPin: 3, description: "Pump PWM", pinType: "pwm"),
    ]
)

// Slave board (Teensy for real-time data logging)
let slaveBoard = HardwareBoard(
    name: "Lab Logger Board",
    boardType: .custom,
    serialPort: "/dev/ttyUSB1",
    baudRate: 115200,
    pinAliases: [
        PinAlias(alias: "data_valid", physicalPin: 2, description: "Data valid signal", pinType: "digital"),
        PinAlias(alias: "clock", physicalPin: 3, description: "Sync clock", pinType: "digital"),
    ],
    metadata: HardwareBoardMetadata(
        tags: ["slave", "logging"],
        notes: "Syncs with main board via digital pins"
    )
)

try app.hardwareManager.createBoard(mainBoard)
try app.hardwareManager.createBoard(slaveBoard)
```

## Example 3: HAT Board (Raspberry Pi)

```swift
let piHatAliases: [PinAlias] = [
    // Motor control (DRV8833 H-bridge)
    PinAlias(alias: "motor_a_in1", physicalPin: 17, description: "Motor A IN1", pinType: "digital"),
    PinAlias(alias: "motor_a_in2", physicalPin: 27, description: "Motor A IN2", pinType: "digital"),
    PinAlias(alias: "motor_b_in1", physicalPin: 22, description: "Motor B IN1", pinType: "digital"),
    PinAlias(alias: "motor_b_in2", physicalPin: 23, description: "Motor B IN2", pinType: "digital"),

    // IMU sensor (MPU6050 on I2C)
    PinAlias(alias: "imu_sda", physicalPin: 2, description: "I2C SDA", pinType: "i2c"),
    PinAlias(alias: "imu_scl", physicalPin: 3, description: "I2C SCL", pinType: "i2c"),
    PinAlias(alias: "imu_int", physicalPin: 4, description: "IMU interrupt", pinType: "digital"),

    // Status output
    PinAlias(alias: "status_led", physicalPin: 18, description: "Activity LED", pinType: "pwm"),
]

let piRobotHat = HardwareBoard(
    name: "Pi Robot HAT",
    boardType: .custom,
    description: "4-wheel robot control HAT for Raspberry Pi",
    transportType: .native,
    serialPort: "native",
    pinAliases: piHatAliases,
    metadata: HardwareBoardMetadata(
        tags: ["robotics", "hat", "motor-control"],
        notes: "Stacked on RPi 4B"
    )
)

try app.hardwareManager.createBoard(piRobotHat)
```

## Programmatic Board Creation

```swift
import WritersApp

// Create board in code
func setupCustomBoard() throws {
    let app = WritersApp()

    // Define pins
    let aliases = [
        PinAlias(alias: "sensor_1", physicalPin: 0, description: "Input sensor", pinType: "analog"),
        PinAlias(alias: "output_1", physicalPin: 8, description: "Control output", pinType: "digital"),
    ]

    // Create board
    let board = HardwareBoard(
        name: "Custom Project Board",
        boardType: .custom,
        description: "My custom hardware configuration",
        serialPort: "/dev/ttyUSB0",
        baudRate: 115200,
        transportType: .serial,
        pinAliases: aliases
    )

    // Register board
    try app.hardwareManager.createBoard(board)

    // Verify creation
    if let created = app.hardwareManager.getBoard(id: board.id) {
        print("Board created: \(created.name)")
    }
}
```

## CLI Method

From the friendly-outlaw CLI:

1. Select "Add Hardware Board" (option 80)
2. Enter board name: "My Custom Board"
3. Select board type: "custom" (last option)
4. Enter description: "My custom sensor/actuator configuration"
5. Enter serial port: `/dev/ttyUSB0` (or appropriate port)
6. Enter baud rate: `115200`
7. Board created

Then add pin aliases:
1. Select "Manage Pin Aliases" (option 84)
2. Select your newly created board
3. Choose "Add pin alias"
4. Repeat for each pin

## Best Practices

### Naming Conventions

Use clear, descriptive names:
```
✓ Good:
  - heater_relay
  - temp_sensor
  - water_pump
  - status_led

✗ Avoid:
  - led1, led2 (ambiguous)
  - pin8 (defeats aliasing purpose)
  - sensor (too generic)
```

### Documentation

Include comprehensive metadata:
```swift
metadata: HardwareBoardMetadata(
    tags: ["project-name", "category"],
    notes: """
    Project: Smart Garden
    Location: Greenhouse 2
    Deployed: 2024-03-15
    Connected to: Cloud logging via WiFi
    Maintenance: Calibrate sensors monthly
    """
)
```

### Organization

Group related pins logically:
```
Sensors (analog)
├── temperature
├── humidity
└── light

Actuators (digital/PWM)
├── pump
├── lights
└── fan

Status (outputs)
└── led
```

### Datasheet References

Include URLs for board documentation:
```swift
datasheetURL: "https://example.com/custom-board-pinout.pdf"
```

This helps when integrating with AI tools that may need to reference hardware specs.

## Adding to Database

Once created, boards are stored in memory. To persist them:

```swift
// Boards are automatically persisted when using CLI
// Programmatically:
try app.hardwareManager.createBoard(myBoard)
// Database persistence will be added in future updates
```

## Testing Your Custom Board

```swift
// Get board
let board = app.hardwareManager.searchBoards(query: "My Custom Board").first

// Verify pin aliases
if let tempPin = app.hardwareManager.getPinAlias(boardId: board!.id, aliasName: "temp_sensor") {
    print("Temperature pin: \(tempPin.physicalPin)")
}

// Create peripheral using the pins
let peripheral = Peripheral(
    name: "Environmental Monitor",
    boardId: board!.id,
    type: "sensor_array",
    pins: [
        PeripheralPin(pinAlias: "temp_sensor", mode: "analog"),
        PeripheralPin(pinAlias: "status_led", mode: "output")
    ]
)
try app.hardwareManager.createPeripheral(peripheral)
```

## Common Board Configurations

### Arduino Mega (54 digital pins, 16 analog)
```
Serial pins: 18 (TX), 19 (RX)
SPI pins: 50 (MISO), 51 (MOSI), 52 (SCK)
I2C pins: 20 (SDA), 21 (SCL)
PWM pins: 2-13, 44-46
```

### Arduino Nano (same as Uno, compact)
```
Same pinout as Uno
Uses USB Mini connector
No on-board USB driver
```

### STM32H7 Discovery
```
2× SPI, 4× I2C, 4× UART interfaces
144 pins
100 MHz Cortex-M7
```

See [HARDWARE.md](../HARDWARE.md) for more supported boards and [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI integration.
