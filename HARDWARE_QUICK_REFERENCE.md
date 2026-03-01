# Hardware Boards - Quick Reference

Fast lookup for all supported boards, pins, and configurations.

## Default Board Templates (5 Built-In)

### 1. Arduino Uno
```
Type:        arduino-uno
Speed:       9600 baud
Port:        /dev/ttyUSB0 (or COM3 on Windows)
Digital:     14 pins (0-13)
Analog:      6 pins (A0-A5)
PWM:         6 pins (3, 5, 6, 9, 10, 11)

Pre-configured Pins (8):
┌─ Sensors
├── soil_moisture_sensor     → A0 (analog)
├── temp_sensor             → A1 (analog)
└─ Outputs
├── red_led                 → 13 (digital)
├── green_led               → 12 (digital)
├── blue_led                → 11 (pwm)
└─ Control
├── button                  → 2 (digital)
├── pwm_pin                 → 3 (pwm)
└── motor_pin               → 9 (pwm)
```

**Best For**: Beginners, simple projects, hobby electronics

**Example Projects**:
- LED blinking
- Button control
- Simple sensors
- Motor speed control

---

### 2. Nucleo-F401RE
```
Type:        nucleo-f401re
Speed:       115200 baud (fast!)
Port:        /dev/ttyACM0 (or COM4 on Windows)
Digital:     84 GPIO pins
Analog:      16 ADC channels
PWM:         12 channels
CPU:         STM32F401RE (100 MHz Cortex-M4)

Pre-configured Pins (10):
┌─ LEDs
├── user_led                → 5 (digital)
├── led_1                   → 6 (digital)
└── led_2                   → 7 (digital)
┌─ Buttons
├── user_button             → 13 (digital)
└─ Communication
├── uart_tx                 → 1 (digital)
├── uart_rx                 → 0 (digital)
├── spi_clk                 → 10 (digital)
├── spi_mosi                → 11 (digital)
├── i2c_sda                 → 9 (digital)
└── i2c_scl                 → 8 (digital)
```

**Best For**: Professional projects, industrial use, high-speed I/O

**Example Projects**:
- Data acquisition
- Real-time control
- Multi-sensor systems
- Industrial automation

---

### 3. ESP32
```
Type:        esp32
Speed:       115200 baud (very fast!)
Port:        /dev/ttyUSB0
Digital:     30+ GPIO pins
Analog:      12 ADC channels
PWM:         16 channels
CPU:         Dual-core 240 MHz (Xtensa 32-bit)
Wireless:    WiFi 802.11 b/g/n + Bluetooth 4.2

Pre-configured Pins (12):
┌─ Outputs
├── built_in_led            → 2 (digital)
├── pwm_pin                 → 27 (pwm)
└─ GPIO
├── gpio_4                  → 4 (digital)
├── gpio_5                  → 5 (digital)
├── gpio_12                 → 12 (digital)
├── gpio_13                 → 13 (digital)
├── gpio_14                 → 14 (digital)
├── gpio_15                 → 15 (digital)
├── gpio_16                 → 16 (digital)
├── adc_pin                 → 35 (analog)
├── i2c_sda                 → 21 (digital)
└── i2c_scl                 → 22 (digital)
```

**Best For**: IoT projects, WiFi connectivity, cloud integration

**Example Projects**:
- Smart home devices
- Weather monitoring
- Cloud data logging
- Wireless sensor networks

---

### 4. Raspberry Pi 4
```
Type:        rpi-gpio
Speed:       Native GPIO (no serial)
Transport:   Direct GPIO access
Digital:     28 usable GPIO pins (BCM numbering)
PWM:         2 hardware channels
CPU:         Broadcom BCM2711 (1.5 GHz Quad-core ARM)

Pre-configured Pins (15):
┌─ LEDs
├── led_red                 → 17 (digital)
├── led_green               → 27 (digital)
└── led_blue                → 22 (digital)
┌─ Buttons
├── button_1                → 23 (digital)
└── button_2                → 24 (digital)
┌─ Motors
├── motor_1_fwd             → 25 (pwm)
└── motor_1_rev             → 26 (pwm)
┌─ Communication
├── i2c_sda                 → 2 (digital)
├── i2c_scl                 → 3 (digital)
├── spi_clk                 → 11 (digital)
├── spi_mosi                → 10 (digital)
├── spi_miso                → 9 (digital)
├── uart_tx                 → 14 (digital)
└── uart_rx                 → 15 (digital)
```

**Best For**: Robotics, complex systems, Linux integration

**Example Projects**:
- Robot platforms
- Media centers
- Smart cameras
- Complex automation

---

### 5. Teensy 4.0
```
Type:        teensy-40
Speed:       115200 baud
Port:        /dev/ttyACM0
Digital:     32 GPIO pins
Analog:      14 ADC channels
PWM:         14 channels
CPU:         NXP iMXRT1062 (600 MHz Cortex-M7)

Pre-configured Pins (13):
┌─ Status
├── led_pin                 → 13 (digital)
├── button                  → 0 (digital)
└─ Analog
├── analog_1                → 14 (analog)
├── analog_2                → 15 (analog)
┌─ PWM
├── pwm_1                   → 3 (pwm)
└── pwm_2                   → 4 (pwm)
┌─ Communication
├── uart_tx                 → 1 (digital)
├── uart_rx                 → 0 (digital)
├── i2c_sda                 → 18 (digital)
├── i2c_scl                 → 19 (digital)
├── spi_clk                 → 27 (digital)
├── spi_mosi                → 26 (digital)
└── spi_miso                → 1 (digital)
```

**Best For**: Real-time audio/video, precision timing, high-speed control

**Example Projects**:
- Audio processing
- Real-time signal processing
- Motion control
- High-speed data acquisition

---

## Custom Board Options

### BoardType Enum Values
```
.arduinoUno      - Arduino Uno (9600 baud)
.nucleoF401RE    - STM32 Nucleo-F401RE (115200 baud)
.esp32           - ESP32 dual-core (115200 baud + WiFi)
.rpiGPIO         - Raspberry Pi GPIO (native, no serial)
.teensy40        - Teensy 4.0 (115200 baud)
.custom          - Custom board (user-defined)
```

### Transport Types
```
.serial          - Serial/USB (TTL/UART)
.native          - Direct GPIO (no serial overhead)
.network         - Network-based (TCP/UDP)
```

---

## Pin Type Reference

```
digital     - On/off (HIGH/LOW)
            Examples: LED, relay, button, switch
            Values: 0 (LOW) or 1 (HIGH)

analog      - Voltage measurement (0-5V)
            Examples: sensor, potentiometer, LDR
            Values: 0-1023 (10-bit ADC)

pwm         - Pulse-width modulation
            Examples: LED dimming, motor speed, servo
            Values: 0-255 (duty cycle %)

i2c         - I2C communication (2-wire)
            Examples: sensor, display, memory
            Speed: 100-400 kHz

spi         - SPI communication (4-wire)
            Examples: SD card, Flash, sensor
            Speed: 1-10 MHz typical
```

---

## Baud Rate Reference

```
Arduino Uno       → 9600
Nucleo-F401RE     → 115200
ESP32             → 115200
Teensy 4.0        → 115200
Raspberry Pi      → Native (no baud)
Custom boards     → Configurable
```

---

## Communication Protocol Mapping

| Protocol | Pins | Arduino | Nucleo | ESP32 | Teensy | RPi |
|----------|------|---------|--------|-------|--------|-----|
| **UART** | TX/RX | 0,1 | 0,1 / 8,9 | 1,3 / 16,17 | 0,1 / 7,8 | 14,15 |
| **I2C** | SDA/SCL | 20,21 | 9,8 / 20,21 | 21,22 | 18,19 | 2,3 |
| **SPI** | CLK/MOSI/MISO | 13,11,12 | 10,11,12 | 5,23,19 | 27,26,1 | 11,10,9 |

---

## CLI Commands Quick Map

```
Option 80 → Add Hardware Board
Option 81 → List Hardware Boards
Option 82 → View Board Details
Option 83 → Remove Hardware Board
Option 84 → Manage Pin Aliases
Option 85 → View Board Statistics
```

### Add Board Workflow
```
80 → Enter name → Select type → Enter port → Enter baud → Done
```

### Add Pin Alias Workflow
```
84 → Select board → Add pin alias → Enter name → Enter pin # → Enter type → Done
```

---

## Status LED Color Conventions

```
Green (led_status)    → System OK
Yellow (warning_led)  → Warning/Attention
Red (error_led)       → Error condition
Blue (gpio_16)        → WiFi connected
Blinking             → Activity
```

---

## Power Supply Requirements

```
Arduino Uno       → 5V (USB or external)
Nucleo-F401RE     → 3.3V (USB STLink)
ESP32             → 3.3V (USB or battery)
Raspberry Pi      → 5V / 2.5A (USB-C)
Teensy 4.0        → 3.3V (USB)
```

---

## Serial Port Detection

**macOS:**
```bash
ls /dev/cu.usb*
# Output: /dev/cu.usbmodem14201
```

**Linux:**
```bash
ls /dev/tty*
# Output: /dev/ttyUSB0 or /dev/ttyACM0
```

**Windows:**
```
Device Manager → Ports (COM & LPT)
# Look for COMx (typically COM3, COM4, etc.)
```

---

## Troubleshooting Quick Tips

| Problem | Solution |
|---------|----------|
| Board not found | Check USB cable, try different USB port |
| Garbled output | Verify baud rate matches |
| Permission denied | Run with sudo (Linux), install drivers (Windows) |
| Port already in use | Close other serial applications |
| No response | Check serial port name, try resetting board |
| Wrong pins firing | Verify pin alias name (case-sensitive) |

---

## Quick Start Templates

### Simplest Setup
```
Board: Arduino Uno
Port: /dev/ttyUSB0
Baud: 9600
Pins: red_led (13), button (2)
```

### Professional Setup
```
Board: Nucleo-F401RE
Port: /dev/ttyACM0
Baud: 115200
Pins: Full I2C/SPI configuration
```

### IoT Setup
```
Board: ESP32
Port: /dev/ttyUSB0
Baud: 115200
WiFi: Enabled
```

### Robotics Setup
```
Board: Raspberry Pi
Transport: Native GPIO
Motors: GPIO 25, 26 (PWM)
Sensors: I2C bus
```

---

## Documentation References

| Topic | Document |
|-------|----------|
| Hardware overview | [HARDWARE.md](HARDWARE.md) |
| Setup instructions | [docs/HARDWARE_SETUP.md](docs/HARDWARE_SETUP.md) |
| Custom boards | [docs/CUSTOM_BOARD_SETUP.md](docs/CUSTOM_BOARD_SETUP.md) |
| Real projects | [docs/HARDWARE_EXAMPLES.md](docs/HARDWARE_EXAMPLES.md) |
| AI integration | [docs/CUSTOM_TOOLS.md](docs/CUSTOM_TOOLS.md) |
| Code examples | [examples/custom_board_examples.swift](examples/custom_board_examples.swift) |

---

## Next Steps

1. **Choose your board** (see table above)
2. **Find the serial port** (see detection steps)
3. **Use CLI option 80** to add the board
4. **Use CLI option 84** to configure pins
5. **Verify with option 82** to see details

**For custom boards:** See [docs/CUSTOM_BOARD_SETUP.md](docs/CUSTOM_BOARD_SETUP.md)

**For project examples:** See [docs/HARDWARE_EXAMPLES.md](docs/HARDWARE_EXAMPLES.md)
