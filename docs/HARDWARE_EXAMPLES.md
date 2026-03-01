# Hardware Board Examples

Practical examples using friendly-outlaw's hardware board system with real-world projects.

## Table of Contents
1. [Arduino Uno Projects](#arduino-uno-projects)
2. [Nucleo-F401RE Projects](#nucleo-f401re-projects)
3. [ESP32 Projects](#esp32-projects)
4. [Raspberry Pi Projects](#raspberry-pi-projects)
5. [Teensy 4.0 Projects](#teensy-40-projects)
6. [Multi-Board Systems](#multi-board-systems)

---

## Arduino Uno Projects

### Project 1: Traffic Light Controller

**Hardware Setup:**
- Red LED on pin 13 (red_led)
- Yellow LED on pin 12 (green_led)
- Green LED on pin 11 (blue_led with PWM)
- Button on pin 2 (button)

**Board Configuration:**
```
Board Name: Traffic Light Controller
Board Type: Arduino Uno
Serial Port: /dev/ttyUSB0 (or COM3 on Windows)
Baud Rate: 9600

Pre-configured Pins:
- red_led → Pin 13
- green_led → Pin 12
- blue_led → Pin 11 (PWM for dimming)
- button → Pin 2
```

**Usage with AI:**
```swift
let context = """
Traffic light system with 3 LEDs and manual control button.
Can cycle through states: red → yellow → green.
Button can interrupt current cycle.
"""

let response = try await app.getAIAssistanceWithTools(
    documentId: docId,
    type: .custom("traffic_controller"),
    context: context
)
// Claude can now call hardware tools to control the lights
```

### Project 2: Analog Sensor Monitoring

**Hardware Setup:**
- Temperature sensor on A1 (temp_sensor)
- Moisture sensor on A0 (analog_sensor)
- Status LED on pin 13 (red_led)

**Features:**
- Real-time temperature and humidity monitoring
- LED status indication
- Data logging to document

**CLI Configuration:**
```
1. Launch WritersApp CLI
2. Select Option 80: "Add Hardware Board"
3. Name: "Sensor Monitor"
4. Type: arduino-uno
5. Port: /dev/ttyUSB0
6. Baud: 9600
7. Then use option 84 to add custom pin aliases for sensors
```

---

## Nucleo-F401RE Projects

### Project 1: Precision Temperature and Humidity System

**Hardware Setup:**
- DHT22 sensor on pin 5 (user_led as signal)
- LCD display via I2C (i2c_sda/i2c_scl)
- Alert buzzer on pin 6 (led_1)
- Status indicator on pin 7 (led_2)

**Features:**
- I2C communication for LCD display
- High-speed serial (115200 baud)
- Multiple LED status indicators
- UART for data logging

**Board Configuration:**
```
Name: Environmental Monitor Pro
Type: nucleo-f401re
Port: /dev/ttyACM0
Baud: 115200

Key Pins:
- I2C for sensors (i2c_sda, i2c_scl)
- UART for logging (uart_tx, uart_rx)
- Status LEDs (user_led, led_1, led_2)
```

### Project 2: Data Acquisition System

**Hardware:**
- 4 analog sensors on A0-A3
- SD card module via SPI (spi_clk, spi_mosi, spi_miso)
- Real-time clock (RTC) via I2C
- Status display via UART

**Capabilities:**
- 115200 baud fast serial
- SPI bus for SD card storage
- I2C for RTC synchronization
- Multi-sensor data logging

---

## ESP32 Projects

### Project 1: IoT Home Automation Hub

**Hardware Setup:**
- Red LED on GPIO 2 (built_in_led)
- Motion sensor on GPIO 4 (gpio_4)
- Temperature sensor on ADC pin 35 (adc_pin)
- Relay control on GPIO 13 (gpio_13)
- WiFi enabled (on-board)

**Features:**
- WiFi connectivity
- Bluetooth support
- Real-time sensor monitoring
- Remote control via cloud

**Configuration:**
```
Name: IoT Home Hub
Type: esp32
Port: /dev/ttyUSB0
Baud: 115200

Features:
- WiFi 802.11 b/g/n
- Bluetooth 4.2
- 12 ADC channels for analog sensors
- PWM on any GPIO (36 channels)
```

**AI Integration Example:**
```swift
// ESP32 can report WiFi status, sensors, and respond to commands
let context = """
ESP32 home automation hub connected to:
- Living room temperature sensor
- Front door motion detector
- Garage light relay
- WiFi network enabled for remote monitoring
"""

let response = try await app.getAIAssistanceWithTools(
    documentId: docId,
    type: .custom("home_control"),
    context: context
)
```

### Project 2: Wireless Sensor Network

**Hardware:**
- 6 analog sensors (ADC inputs)
- 2 SPI devices (SD card + RTC)
- 2 I2C devices (humidity sensor + pressure sensor)
- Status LEDs on GPIO 2, 4, 5
- WiFi for cloud sync

**Capabilities:**
- Multiple sensor fusion
- Local SD card storage
- Cloud synchronization via WiFi
- Real-time Bluetooth monitoring

---

## Raspberry Pi Projects

### Project 1: Robotics Platform

**Hardware Setup:**
- 2 DC motors with H-bridge
  - Motor 1 Forward: GPIO 25 (motor_1_fwd - PWM)
  - Motor 1 Reverse: GPIO 26 (motor_1_rev - PWM)
- Status LEDs (LED red/green/blue)
- Button controls (button_1, button_2)
- IMU sensor via I2C (i2c_sda, i2c_scl)

**Features:**
- Native GPIO (no serial needed)
- PWM motor control
- I2C sensor communication
- Multiple button inputs

**Configuration:**
```
Name: Mobile Robot Platform
Type: rpi-gpio
Transport: native (GPIO direct access)

Motor Control:
- motor_1_fwd → GPIO 25 (PWM forward)
- motor_1_rev → GPIO 26 (PWM reverse)

Sensors:
- IMU on I2C
- Movement feedback
```

### Project 2: Security Camera System

**Hardware:**
- Camera module (CSI)
- Motion detector on GPIO 23 (button_1)
- Pan/Tilt servos via PWM
- Status LEDs (red, green, blue)
- Alert buzzer on GPIO 24 (button_2)
- UART for serial communication

**Features:**
- High-resolution imaging
- Motion detection
- Pan/tilt control
- Email/cloud alerts

---

## Teensy 4.0 Projects

### Project 1: Real-Time Audio Processing

**Hardware Setup:**
- Audio I/O via I2S
- ADC for analog input
- DAC for analog output
- Status LED on pin 13 (led_pin)
- Serial debug on UART

**Features:**
- 600 MHz ARM Cortex-M7
- Floating-point acceleration
- Audio codec support
- Real-time performance

**Configuration:**
```
Name: Audio DSP Module
Type: teensy-40
Port: /dev/ttyACM0
Baud: 115200

Audio Path:
- Analog input A0 (analog_1)
- Analog output (PWM pins)
- Debug output via UART
```

### Project 2: Motion Control System

**Hardware:**
- 4 servo motors (PWM capable)
- 4 analog feedback sensors
- Encoder input on UART RX
- Status display via I2C OLED
- Data logging via SPI SD card

**Capabilities:**
- Precise timing (600 MHz)
- Multiple PWM channels
- Analog feedback
- Real-time control loop

---

## Multi-Board Systems

### Project 1: Distributed Sensor Network

**Setup:**
- **Master**: Raspberry Pi 4 with local storage and WiFi
- **Slave 1**: Arduino Uno for analog sensors
- **Slave 2**: Teensy 4.0 for real-time processing
- **Slave 3**: ESP32 for cloud sync

**Architecture:**
```
Raspberry Pi (Master)
  ├─ I2C Bus
  │  ├─ Arduino Uno (sensors)
  │  └─ Teensy 4.0 (processing)
  ├─ UART (Slave 3)
  │  └─ ESP32 (cloud)
  └─ SSD for data storage
```

**Data Flow:**
1. Arduino reads analog sensors (9600 baud)
2. Teensy processes data in real-time (115200 baud)
3. Raspberry Pi aggregates results
4. ESP32 syncs to cloud

### Project 2: Hybrid Control System

**Master Board**: Nucleo-F401RE
- High-speed processing (115200 baud)
- I2C communication hub
- SPI slave for external sensors

**Peripherals:**
- Arduino Uno: Analog sensors (9600)
- ESP32: WiFi gateway (115200)
- Teensy: Real-time feedback (115200)
- Raspberry Pi: Data logging (native GPIO)

**Communication Matrix:**
```
Nucleo F401RE (Master)
├─ UART1 → Arduino Uno (sensor data)
├─ UART2 → ESP32 (cloud commands)
├─ I2C   ├─ Teensy 4.0 (feedback)
│        └─ Various I2C sensors
└─ SPI   └─ SD card storage
```

---

## Quick Reference: Board Selection

| Project Type | Recommended Board | Reason |
|--------------|-------------------|--------|
| Beginners | Arduino Uno | Simple, well-documented, 9600 baud |
| Real-time control | Teensy 4.0 | 600 MHz, precise timing |
| IoT/Connectivity | ESP32 | WiFi + Bluetooth built-in |
| Robotics | Raspberry Pi | GPIO flexibility, high performance |
| Industrial/Professional | Nucleo-F401RE | High speed (115200), industrial support |
| Multi-sensor | Raspberry Pi + Slaves | Distributed architecture |

## Pin Count Comparison

| Board | Digital | Analog | PWM | I2C | SPI | UART |
|-------|---------|--------|-----|-----|-----|------|
| Arduino Uno | 14 | 6 | 6 | 1 | 1 | 1 |
| Nucleo-F401RE | 84 | 16 | 12 | 3 | 3 | 6 |
| ESP32 | 30+ | 12 | 16 | 2 | 4 | 3 |
| Raspberry Pi | 28 | 0 | 2 | 2 | 2 | 2 |
| Teensy 4.0 | 32 | 14 | 14 | 2 | 2 | 4 |

## Common Communication Protocols

**I2C (Two-wire)**
- Supported: All boards (Nucleo, ESP32, Teensy, Raspberry Pi)
- Uses: Sensors, displays, RTC, IMU
- Speed: 100 kHz - 400 kHz typical

**SPI (Four-wire)**
- Supported: Arduino Uno (limited), Nucleo, ESP32, Teensy, Raspberry Pi
- Uses: SD cards, Flash memory, some sensors
- Speed: Up to 50 MHz

**UART/Serial**
- Supported: All boards
- Uses: Debugging, inter-board communication
- Speed: 9600 - 115200 typical (up to 3 Mbps on ESP32/Teensy)

**Native GPIO**
- Supported: Raspberry Pi (best), others
- Uses: Direct digital I/O without serial overhead
- Speed: Microsecond response times

---

## Creating Your Own Project

1. **Choose base board** (see Quick Reference table)
2. **Identify all hardware connections**
3. **Map pins to aliases** using option 84 (Manage Pin Aliases)
4. **Create peripherals** for complex devices
5. **Write board description** with project context
6. **Add to AI context** for hardware-aware assistance

Example workflow:
```
Option 80 → Add board "My Project"
Option 84 → Add pin aliases for all connections
Option 82 → Verify setup
Option 85 → Check statistics
Create document with hardware context
Option 16 → Generate AI ideas with hardware knowledge
```

See [HARDWARE.md](../HARDWARE.md) for detailed API reference and [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI tool integration patterns.
