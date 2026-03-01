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
├── red_led                 → 13 (digital)
├── green_led               → 12 (digital)
├── button                  → 2 (digital)
├── analog_sensor           → A0 (analog)
├── temp_sensor             → A1 (analog)
├── pwm_pin                 → 3 (pwm)
├── motor_pin               → 9 (pwm)
└── soil_moisture_sensor    → A2 (analog)
```

**Best For**: Beginners, simple projects, hobby electronics

---

### 2. Nucleo-F401RE
```
Type:        nucleo-f401re
Speed:       115200 baud (fast!)
Port:        /dev/ttyACM0 (or COM4 on Windows)
CPU:         STM32F401RE (100 MHz Cortex-M4)

Pre-configured Pins (10):
├── user_led                → 5 (digital)
├── led_1                   → 6 (digital)
├── led_2                   → 7 (digital)
├── user_button             → 13 (digital)
├── uart_tx                 → 1 (digital)
├── uart_rx                 → 0 (digital)
├── spi_clk                 → 10 (digital)
├── spi_mosi                → 11 (digital)
├── i2c_sda                 → 9 (digital)
└── i2c_scl                 → 8 (digital)
```

**Best For**: Professional projects, industrial use, high-speed I/O

---

### 3. ESP32
```
Type:        esp32
Speed:       115200 baud (very fast!)
Port:        /dev/ttyUSB0
CPU:         Dual-core 240 MHz (Xtensa 32-bit)
Wireless:    WiFi 802.11 b/g/n + Bluetooth 4.2

Pre-configured Pins (12):
├── built_in_led            → 2 (digital)
├── pwm_pin                 → 27 (pwm)
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

---

### 4. Raspberry Pi 4
```
Type:        rpi-gpio
Speed:       Native GPIO (no serial)
Transport:   Direct GPIO access

Pre-configured Pins (14):
├── led_red                 → 17 (digital)
├── led_green               → 27 (digital)
├── led_blue                → 22 (digital)
├── button_1                → 23 (digital)
├── button_2                → 24 (digital)
├── motor_1_fwd             → 25 (pwm)
├── motor_1_rev             → 26 (pwm)
├── i2c_sda                 → 2 (digital)
├── i2c_scl                 → 3 (digital)
├── spi_clk                 → 11 (digital)
├── spi_mosi                → 10 (digital)
├── spi_miso                → 9 (digital)
├── uart_tx                 → 14 (digital)
└── uart_rx                 → 15 (digital)
```

**Best For**: Robotics, complex systems, Linux integration

---

### 5. Teensy 4.0
```
Type:        teensy-40
Speed:       115200 baud
Port:        /dev/ttyACM0
CPU:         NXP iMXRT1062 (600 MHz Cortex-M7)

Pre-configured Pins (13):
├── led_pin                 → 13 (digital)
├── button                  → 0 (digital)
├── analog_1                → 14 (analog)
├── analog_2                → 15 (analog)
├── pwm_1                   → 3 (pwm)
├── pwm_2                   → 4 (pwm)
├── uart_tx                 → 1 (digital)
├── uart_rx                 → 0 (digital)
├── i2c_sda                 → 18 (digital)
├── i2c_scl                 → 19 (digital)
├── spi_clk                 → 27 (digital)
├── spi_mosi                → 26 (digital)
└── spi_miso                → 1 (digital)
```

**Best For**: Real-time audio/video, precision timing, high-speed control

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
analog      - Voltage measurement (0-5V), values: 0-1023
pwm         - Pulse-width modulation, values: 0-255
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

## CLI Commands Quick Map

```
Option 80 → Add Hardware Board
Option 81 → List Hardware Boards
Option 82 → View Board Details
Option 83 → Remove Hardware Board
Option 84 → Manage Pin Aliases
Option 85 → View Board Statistics
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
