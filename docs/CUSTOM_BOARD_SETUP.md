# Custom Board Creation & Pin Configuration Guide

Complete walkthrough for creating custom hardware boards and configuring pins.

## Method 1: CLI Setup (Interactive)

### Step 1: Launch the Application

```bash
swift run WritersAppCLI
```

### Step 2: Create a Custom Board (Option 80)

```
Main Menu → 80. Add Hardware Board

Board name: Smart Plant Monitor
Select board type: 6 (custom)
Description: Arduino-based automated plant watering system
Serial port: /dev/ttyUSB0
Baud rate: 9600

✓ Board created successfully!
```

### Step 3: Add Pin Aliases (Option 84)

```
Main Menu → 84. Manage Pin Aliases

Select board: 1. Smart Plant Monitor

Pin Management Options:
  1. Add pin alias

Alias name: soil_moisture_sensor
Physical pin number: 0
Description: Analog soil moisture sensor on A0
Pin type: analog

✓ Pin alias added successfully
```

**Add all pins for this project:**

| Pin Name | Number | Type | Description |
|----------|--------|------|-------------|
| soil_moisture_sensor | 0 | analog | Main soil sensor (A0) |
| temp_sensor | 1 | analog | Temperature sensor (A1) |
| water_pump | 3 | pwm | Pump control (PWM) |
| status_led | 13 | digital | Status indicator |

### Step 4: Verify Configuration (Option 82)

```
Main Menu → 82. View Board Details

--- Board: Smart Plant Monitor ---
Type: custom
Transport: serial
Serial Port: /dev/ttyUSB0
Baud Rate: 9600
Status: Active

Pin Aliases (4):
  - soil_moisture_sensor (Pin 0): Analog soil moisture sensor [analog]
  - temp_sensor (Pin 1): Temperature sensor [analog]
  - water_pump (Pin 3): Pump control [pwm]
  - status_led (Pin 13): Status indicator [digital]
```

### Step 5: Check Statistics (Option 85)

```
Main Menu → 85. View Board Statistics

Hardware Statistics
===================
Total boards: 7
Active boards: 0

Boards by type:
  arduino-uno: 1
  custom: 1
  esp32: 1
  nucleo-f401re: 1
  rpi-gpio: 1
  teensy-40: 1
```

---

## Method 2: Programmatic Setup (Swift Code)

```swift
import WritersApp

let app = WritersApp()

let plantMonitorPins: [PinAlias] = [
    PinAlias(alias: "soil_moisture_sensor", physicalPin: 0,
             description: "Analog soil moisture sensor on A0", pinType: "analog"),
    PinAlias(alias: "temp_sensor", physicalPin: 1,
             description: "Temperature sensor (DHT22) on A1", pinType: "analog"),
    PinAlias(alias: "water_pump", physicalPin: 3,
             description: "Water pump relay control (PWM)", pinType: "pwm"),
    PinAlias(alias: "status_led", physicalPin: 13,
             description: "Green status indicator LED", pinType: "digital"),
]

let smartPlantBoard = HardwareBoard(
    name: "Smart Plant Monitor",
    boardType: .custom,
    description: "Arduino-based automated plant watering system",
    serialPort: "/dev/ttyUSB0",
    baudRate: 9600,
    transportType: .serial,
    pinAliases: plantMonitorPins,
    metadata: HardwareBoardMetadata(
        tags: ["agriculture", "IoT", "automation"],
        notes: "Deployed in home garden. Calibrate soil sensor monthly."
    )
)

try app.hardwareManager.createBoard(smartPlantBoard)
```

---

## Pin Configuration Best Practices

1. **Use Descriptive Aliases**: `soil_moisture_sensor` not `sensor1`
2. **Group Related Pins**: Sensors (analog), Actuators (pwm/digital), Status (digital)
3. **Document Pin Purpose**: Include specs in description
4. **Plan for Expansion**: Leave room for future sensors

See [HARDWARE_EXAMPLES.md](HARDWARE_EXAMPLES.md) for complete project examples.
