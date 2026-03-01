# ZeroClaw Hardware Integration Guide

This guide explains how to add and manage hardware boards with friendly-outlaw using the ZeroClaw hardware subsystem.

## Overview

ZeroClaw provides a flexible framework for connecting and controlling microcontroller boards from friendly-outlaw. It supports:

- **Multiple board types**: Arduino Uno, Nucleo F401RE, ESP32, Raspberry Pi, Teensy, and custom boards
- **Transport layers**: Serial (USB), native (direct GPIO), and network connections
- **Pin aliasing**: Human-readable names for physical pins (e.g., `red_led` → pin 13)
- **Peripheral management**: Track sensors, actuators, and other devices connected to boards
- **AI integration**: Invoke hardware tools during Claude AI tool loops

## Quick Start: Add a Board via CLI

```bash
# Launch interactive CLI
swift run WritersAppCLI

# From main menu, select option 80: "Add Hardware Board"
# Follow prompts to configure:
# - Board name (e.g., "My Arduino")
# - Board type (Arduino Uno, Nucleo, etc.)
# - Serial port (/dev/ttyUSB0, /dev/cu.usbmodem*, COM3, etc.)
# - Baud rate (9600, 115200, etc.)

# List all boards (option 81)
# View board details (option 82)
# Manage pin aliases (option 84)
```

## Supported Boards

| Board | Type | Transport | Typical Path |
|-------|------|-----------|--------------|
| Arduino Uno | `arduino-uno` | serial | `/dev/ttyUSB0`, `COM3` |
| Nucleo-F401RE | `nucleo-f401re` | serial | `/dev/ttyACM0`, `COM4` |
| ESP32 | `esp32` | serial | `/dev/ttyUSB0`, `/dev/cu.usbserial-*` |
| Raspberry Pi | `rpi-gpio` | native | `native` |
| Teensy 4.0 | `teensy-40` | serial | `/dev/ttyACM0`, `COM*` |
| Custom | `custom` | configurable | user-defined |

## Transport Types

- **Serial**: USB/UART connections (most common for Arduino, Nucleo, ESP32)
- **Native**: Direct GPIO access (Raspberry Pi on Linux)
- **Network**: TCP/UDP network connections (future feature)

## Pin Aliasing System

Pin aliases allow you to reference pins by human-readable names instead of numbers:

```
red_led → 13 (Arduino Uno)
user_button → 2
analog_sensor → A0 (Arduino) or PA0 (STM32)
pwm_led → 3
```

### Adding Pin Aliases

Via CLI (option 84, "Manage Pin Aliases"):
```
1. Select board
2. Add pin alias
3. Enter: alias name (e.g., "green_led")
4. Enter: physical pin (e.g., 12)
5. Enter: description (optional)
6. Enter: pin type (digital, analog, pwm)
```

Programmatically:
```swift
let board = app.hardwareManager.getBoard(id: boardId)
let alias = PinAlias(
    alias: "red_led",
    physicalPin: 13,
    description: "Red LED on breadboard",
    pinType: "digital"
)
try app.hardwareManager.addPinAlias(to: boardId, alias: alias)
```

## Managing Peripherals

Peripherals are devices connected to your board (LEDs, buttons, sensors, motors, etc.).

### Creating a Peripheral

Programmatically:
```swift
let peripheral = Peripheral(
    name: "Traffic Light System",
    boardId: board.id,
    type: "led_array",
    pins: [
        PeripheralPin(pinAlias: "red_led", mode: "output"),
        PeripheralPin(pinAlias: "yellow_led", mode: "output"),
        PeripheralPin(pinAlias: "green_led", mode: "output")
    ]
)
try app.hardwareManager.createPeripheral(peripheral)
```

## Default Templates

friendly-outlaw provides two default board templates that you can clone and customize:

1. **Arduino Uno Template**
   - 14 digital pins, 6 analog inputs
   - 9600 baud serial connection
   - Pre-configured pins: red_led (13), button (2), analog_sensor (A0), pwm_pin (3)

2. **Nucleo F401RE Template**
   - STM32F401RE Arm Cortex-M4
   - 115200 baud serial connection
   - Pre-configured pins: user_led (5), user_button (13), uart_tx (1), uart_rx (0)

## Platform-Specific Serial Ports

### macOS
- Arduino: `/dev/cu.usbmodem*` (e.g., `/dev/cu.usbmodem14101`)
- Nucleo: `/dev/cu.usbmodem*` (similar pattern)
- List ports: `ls /dev/cu.usb*`

### Linux
- Arduino: `/dev/ttyUSB0`, `/dev/ttyUSB1`, etc.
- Nucleo: `/dev/ttyACM0`, `/dev/ttyACM1`, etc.
- List ports: `ls /dev/tty*` or use `dmesg` when plugging in device

### Windows
- Arduino: `COM3`, `COM4`, etc.
- Find COM port: Device Manager → Ports (COM & LTS)

## Baud Rates

Default baud rates:
- Arduino Uno: **9600**
- Arduino Nano: **9600**
- Nucleo F401RE: **115200**
- ESP32: **115200**
- Teensy: **115200**

Verify in your firmware or board documentation.

## AI Integration

Hardware boards can be invoked during Claude AI tool loops to:
- Read sensor values
- Control actuators (LEDs, motors)
- Query board state
- Execute custom hardware tools

See [CUSTOM_TOOLS.md](docs/CUSTOM_TOOLS.md) for AI tool examples.

## CLI Options

| Option | Action |
|--------|--------|
| 80 | Add Hardware Board |
| 81 | List Hardware Boards |
| 82 | View Board Details |
| 83 | Remove Hardware Board |
| 84 | Manage Pin Aliases |
| 85 | View Board Statistics |

## Documentation

- [HARDWARE_QUICK_REFERENCE.md](HARDWARE_QUICK_REFERENCE.md) - Quick lookup for pins and configs
- [docs/HARDWARE_SETUP.md](docs/HARDWARE_SETUP.md) - Platform-specific setup instructions
- [docs/CUSTOM_BOARD_SETUP.md](docs/CUSTOM_BOARD_SETUP.md) - Custom board creation guide
- [docs/HARDWARE_EXAMPLES.md](docs/HARDWARE_EXAMPLES.md) - Real-world project examples
- [docs/CUSTOM_TOOLS.md](docs/CUSTOM_TOOLS.md) - AI hardware tool integration
- [docs/ADD_CUSTOM_BOARD.md](docs/ADD_CUSTOM_BOARD.md) - Adding custom boards
- [examples/custom_board_examples.swift](examples/custom_board_examples.swift) - Code examples
