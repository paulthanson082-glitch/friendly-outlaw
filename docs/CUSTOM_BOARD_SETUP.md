# Custom Board Creation & Pin Configuration Guide

Complete walkthrough for creating custom hardware boards and configuring pins.

## Method 1: CLI Setup (Interactive)

### Step 1: Launch the Application

```bash
swift run WritersAppCLI
```

You'll see the main menu with hardware board options (80-85).

### Step 2: Create a Custom Board (Option 80)

```
Main Menu → 80. Add Hardware Board

Enter the following when prompted:
```

**Example: Create a "Smart Plant Monitor" Board**

```
Board name: Smart Plant Monitor
Select board type:
  1. nucleo-f401re
  2. arduino-uno
  3. rpi-gpio
  4. esp32
  5. teensy-40
  6. custom

Choice: 6 (select "custom")

Description: Arduino-based automated plant watering system with soil moisture
             and temperature monitoring

Serial port (e.g., /dev/ttyUSB0, COM3) [optional]: /dev/ttyUSB0

Baud rate [9600]: 9600

✓ Board created successfully!
Board ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### Step 3: Add Pin Aliases (Option 84)

After creating the board, configure all pins:

```
Main Menu → 84. Manage Pin Aliases

Select board: 1. Smart Plant Monitor

Pin Management Options:
  1. Add pin alias
  2. Remove pin alias
  3. List pin aliases

Choice: 1

Alias name (e.g., 'red_led'): soil_moisture_sensor
Physical pin number: 0
Description: Analog soil moisture sensor on A0
Pin type (digital/analog/pwm) [digital]: analog

✓ Pin alias added successfully
```

**Add all pins for this project:**

| Pin Name | Number | Type | Description |
|----------|--------|------|-------------|
| soil_moisture_sensor | 0 | analog | Main soil sensor (A0) |
| temp_sensor | 1 | analog | Temperature sensor (A1) |
| water_pump | 3 | pwm | Pump control (PWM) |
| status_led | 13 | digital | Status indicator |
| error_led | 12 | digital | Error indication |
| button_override | 2 | digital | Manual control button |

### Step 4: Verify Configuration (Option 82)

```
Main Menu → 82. View Board Details

Select board: 1. Smart Plant Monitor

--- Board: Smart Plant Monitor ---
ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Type: custom
Description: Arduino-based automated plant watering system...
Transport: serial
Serial Port: /dev/ttyUSB0
Baud Rate: 9600
Status: Inactive

Pin Aliases (6):
  - soil_moisture_sensor (Pin 0): Analog soil moisture sensor on A0 [analog]
  - temp_sensor (Pin 1): Temperature sensor (A1) [analog]
  - water_pump (Pin 3): Pump control (PWM) [pwm]
  - status_led (Pin 13): Status indicator [digital]
  - error_led (Pin 12): Error indication [digital]
  - button_override (Pin 2): Manual control button [digital]
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

For advanced users who want to create boards in code:

### Create a Custom Board

```swift
import WritersApp

let app = WritersApp()

// Step 1: Define pin aliases
let plantMonitorPins: [PinAlias] = [
    PinAlias(
        alias: "soil_moisture_sensor",
        physicalPin: 0,
        description: "Analog soil moisture sensor on A0",
        pinType: "analog"
    ),
    PinAlias(
        alias: "temp_sensor",
        physicalPin: 1,
        description: "Temperature sensor (DHT22) on A1",
        pinType: "analog"
    ),
    PinAlias(
        alias: "water_pump",
        physicalPin: 3,
        description: "Water pump relay control (PWM)",
        pinType: "pwm"
    ),
    PinAlias(
        alias: "status_led",
        physicalPin: 13,
        description: "Green status indicator LED",
        pinType: "digital"
    ),
    PinAlias(
        alias: "error_led",
        physicalPin: 12,
        description: "Red error indicator LED",
        pinType: "digital"
    ),
    PinAlias(
        alias: "button_override",
        physicalPin: 2,
        description: "Manual pump control button",
        pinType: "digital"
    )
]

// Step 2: Create the custom board
let smartPlantBoard = HardwareBoard(
    name: "Smart Plant Monitor",
    boardType: .custom,
    description: """
    Arduino-based automated plant watering system
    - Soil moisture sensing and automatic watering
    - Temperature/humidity monitoring
    - Manual override button
    - Status LED indicators
    """,
    serialPort: "/dev/ttyUSB0",
    baudRate: 9600,
    transportType: .serial,
    pinAliases: plantMonitorPins,
    metadata: HardwareBoardMetadata(
        tags: ["agriculture", "IoT", "automation"],
        notes: "Deployed in home garden. Calibrate soil sensor monthly."
    )
)

// Step 3: Register the board
do {
    try app.hardwareManager.createBoard(smartPlantBoard)
    print("✓ Custom board created: \(smartPlantBoard.name)")
    print("  Board ID: \(smartPlantBoard.id.uuidString)")
} catch HardwareError.boardAlreadyExists(let name) {
    print("✗ Board '\(name)' already exists")
} catch {
    print("✗ Error: \(error.localizedDescription)")
}

// Step 4: Verify
if let board = app.hardwareManager.getBoard(id: smartPlantBoard.id) {
    print("\n✓ Board verified:")
    print("  Name: \(board.name)")
    print("  Type: \(board.boardType.rawValue)")
    print("  Pins: \(board.pinAliases.count)")
    print("  Port: \(board.serialPort ?? "native")")
}
```

### Access Pins Programmatically

```swift
// Get a specific pin alias
if let soilPin = app.hardwareManager.getPinAlias(
    boardId: smartPlantBoard.id,
    aliasName: "soil_moisture_sensor"
) {
    print("Soil sensor on pin: \(soilPin.physicalPin)")
    print("Type: \(soilPin.pinType)")
}

// Add a new pin dynamically
let newPin = PinAlias(
    alias: "humidity_sensor",
    physicalPin: 2,
    description: "Humidity sensor (DHT22 data pin)",
    pinType: "digital"
)

do {
    try app.hardwareManager.addPinAlias(
        to: smartPlantBoard.id,
        alias: newPin
    )
    print("✓ Pin added successfully")
} catch {
    print("✗ Error adding pin: \(error.localizedDescription)")
}

// List all pins
let board = app.hardwareManager.getBoard(id: smartPlantBoard.id)
for pin in board?.pinAliases ?? [] {
    print("- \(pin.alias) → Pin \(pin.physicalPin) [\(pin.pinType)]")
}
```

---

## Pin Configuration Patterns

### Digital Output (LED, Relay)

```
Alias: status_led
Physical Pin: 13
Pin Type: digital
Description: Status indicator LED
Typical Voltage: 5V
Current Draw: 20mA per LED
```

```swift
let ledPin = PinAlias(
    alias: "status_led",
    physicalPin: 13,
    description: "Green status LED",
    pinType: "digital"
)
```

### Digital Input (Button, Sensor)

```
Alias: button
Physical Pin: 2
Pin Type: digital
Description: User button input
Typical Configuration: Pull-up resistor enabled
Logic: HIGH = pressed, LOW = released
```

```swift
let buttonPin = PinAlias(
    alias: "user_button",
    physicalPin: 2,
    description: "Push button with pull-up",
    pinType: "digital"
)
```

### Analog Input (Sensor)

```
Alias: temperature
Physical Pin: 0 (A0)
Pin Type: analog
Description: Temperature sensor (TMP36)
Voltage Range: 0-5V
ADC Resolution: 10-bit (1024 values)
```

```swift
let tempPin = PinAlias(
    alias: "temp_sensor",
    physicalPin: 0,
    description: "TMP36 temperature sensor on A0",
    pinType: "analog"
)
```

### PWM Output (Motor, LED dimming)

```
Alias: led_brightness
Physical Pin: 3
Pin Type: pwm
Description: Dimmable LED
PWM Frequency: 490 Hz (typical for Arduino)
Duty Cycle: 0-255 (0% to 100%)
```

```swift
let pwmPin = PinAlias(
    alias: "led_brightness",
    physicalPin: 3,
    description: "Dimmable LED via PWM",
    pinType: "pwm"
)
```

### I2C Communication (Sensor, Display)

```
Alias: i2c_sda
Physical Pin: SDA (varies by board)
Pin Type: digital
Description: I2C Serial Data line
Data Rate: 100-400 kHz
Devices: Sensors, displays, RTC, etc.
```

```swift
let i2cSDA = PinAlias(
    alias: "i2c_sda",
    physicalPin: 20,
    description: "I2C Serial Data line",
    pinType: "digital"
)

let i2cSCL = PinAlias(
    alias: "i2c_scl",
    physicalPin: 21,
    description: "I2C Serial Clock line",
    pinType: "digital"
)
```

### SPI Communication (SD Card, Memory)

```
Alias: spi_clock
Physical Pin: SCK (varies)
Pin Type: digital
Description: SPI serial clock
Clock Speed: Up to 10 MHz (typical)
Devices: SD cards, Flash, sensors
```

```swift
let spiPins: [PinAlias] = [
    PinAlias(alias: "spi_clock", physicalPin: 13, pinType: "digital"),
    PinAlias(alias: "spi_mosi", physicalPin: 11, pinType: "digital"),
    PinAlias(alias: "spi_miso", physicalPin: 12, pinType: "digital"),
    PinAlias(alias: "spi_cs", physicalPin: 10, pinType: "digital")
]
```

---

## Real-World Configuration Examples

### Example 1: Home Weather Station

**Components:**
- DHT22 (temperature/humidity) on pin 2
- BMP280 (pressure) via I2C
- Light sensor on A0
- Status LED on pin 13

**Board Setup:**
```swift
let weatherStationPins: [PinAlias] = [
    PinAlias(alias: "dht22_signal", physicalPin: 2,
             description: "DHT22 data pin", pinType: "digital"),
    PinAlias(alias: "i2c_sda", physicalPin: 20,
             description: "I2C for BMP280", pinType: "digital"),
    PinAlias(alias: "i2c_scl", physicalPin: 21,
             description: "I2C clock", pinType: "digital"),
    PinAlias(alias: "light_sensor", physicalPin: 0,
             description: "Light level (A0)", pinType: "analog"),
    PinAlias(alias: "status_led", physicalPin: 13,
             description: "Activity indicator", pinType: "digital")
]
```

### Example 2: Motor Speed Controller

**Components:**
- DC motor via H-bridge on pins 5 & 6
- Speed control via PWM on pin 3
- Direction control on pins 8 & 9
- Speed feedback on A0
- Emergency stop button on pin 2

**Pin Configuration:**
```swift
let motorPins: [PinAlias] = [
    PinAlias(alias: "motor_fwd", physicalPin: 5, pinType: "digital"),
    PinAlias(alias: "motor_rev", physicalPin: 6, pinType: "digital"),
    PinAlias(alias: "speed_control", physicalPin: 3, pinType: "pwm"),
    PinAlias(alias: "speed_feedback", physicalPin: 0, pinType: "analog"),
    PinAlias(alias: "e_stop", physicalPin: 2, pinType: "digital")
]
```

### Example 3: Smart Lighting System

**Components:**
- RGB LED strip (3 PWM pins)
- Motion sensor (digital input)
- Brightness sensor (analog)
- Network module via UART
- Status indicator

**Configuration:**
```swift
let lightingPins: [PinAlias] = [
    PinAlias(alias: "led_red", physicalPin: 9, pinType: "pwm"),
    PinAlias(alias: "led_green", physicalPin: 10, pinType: "pwm"),
    PinAlias(alias: "led_blue", physicalPin: 11, pinType: "pwm"),
    PinAlias(alias: "motion_sensor", physicalPin: 7, pinType: "digital"),
    PinAlias(alias: "brightness_sensor", physicalPin: 1, pinType: "analog"),
    PinAlias(alias: "uart_tx", physicalPin: 1, pinType: "digital"),
    PinAlias(alias: "uart_rx", physicalPin: 0, pinType: "digital"),
    PinAlias(alias: "status_led", physicalPin: 13, pinType: "digital")
]
```

---

## Pin Configuration Best Practices

### 1. **Use Descriptive Aliases**
```
✓ Good:  soil_moisture_sensor, water_pump, status_led
✗ Bad:   sensor1, pin8, led
```

### 2. **Group Related Pins**
```
Sensors (Analog):
- temp_sensor (A0)
- humidity_sensor (A1)
- light_sensor (A2)

Actuators (Digital/PWM):
- pump (PWM pin 3)
- heater (Digital pin 5)
- fan (PWM pin 6)
```

### 3. **Document Pin Purpose**
```swift
PinAlias(
    alias: "motor_speed",
    physicalPin: 3,
    description: "PWM speed control for 12V DC motor (max 2A)",  // ← Include specs
    pinType: "pwm"
)
```

### 4. **Consider Board Limitations**
- Arduino Uno: Pins 5, 6 share timer → different PWM frequency
- ESP32: Some pins restricted (boot pins, etc.)
- Raspberry Pi: GPIO bias resistors affect some pins

### 5. **Plan for Expansion**
```swift
// Leave room for future sensors
let currentPins: [PinAlias] = [
    PinAlias(alias: "sensor_1", physicalPin: 0, pinType: "analog"),
    PinAlias(alias: "sensor_2", physicalPin: 1, pinType: "analog"),
    // pins 2-5 reserved for future sensors
    PinAlias(alias: "led_status", physicalPin: 13, pinType: "digital")
]
```

---

## Troubleshooting Pin Configuration

### Issue: "Pin not found" Error
**Cause**: Pin alias doesn't exist
**Solution**: Verify alias name matches exactly (case-sensitive)
```swift
// ✗ Won't work
let pin = app.hardwareManager.getPinAlias(boardId: id, aliasName: "Red_LED")

// ✓ Correct
let pin = app.hardwareManager.getPinAlias(boardId: id, aliasName: "red_led")
```

### Issue: Duplicate Pin Alias Names
**Cause**: Two pins with same alias on same board
**Solution**: Use unique names
```
✗ pin_1, pin_2 (too generic)
✓ sensor_1, button_1 (specific)
```

### Issue: Wrong Pin Type
**Cause**: Configured digital pin as PWM or vice versa
**Solution**: Match physical pin capability
```swift
// Arduino Uno PWM pins: 3, 5, 6, 9, 10, 11
// Correct:
PinAlias(alias: "led_dim", physicalPin: 3, pinType: "pwm")

// Incorrect:
PinAlias(alias: "led_dim", physicalPin: 4, pinType: "pwm")  // pin 4 not PWM
```

---

## Next Steps

1. **Create your custom board** (use Method 1 or 2 above)
2. **Configure all pins** (option 84 or programmatically)
3. **Add board metadata** (tags, notes for project context)
4. **Create peripherals** for complex device groups
5. **Integrate with AI** (see [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md))

See [HARDWARE_EXAMPLES.md](HARDWARE_EXAMPLES.md) for complete project examples.
