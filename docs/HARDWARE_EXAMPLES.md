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

### Traffic Light Controller

**Hardware Setup:**
- Red LED on pin 13 (`red_led`)
- Green LED on pin 12 (`green_led`)
- Blue LED on pin 11 (`blue_led` with PWM)
- Button on pin 2 (`button`)

**CLI Configuration:**
```
Option 80: Add Hardware Board
Name: Traffic Light Controller
Type: arduino-uno
Port: /dev/ttyUSB0
Baud: 9600
```

### Analog Sensor Monitoring

**Hardware Setup:**
- Temperature sensor on A1 (`temp_sensor`)
- Moisture sensor on A0 (`analog_sensor`)
- Status LED on pin 13 (`red_led`)

---

## Nucleo-F401RE Projects

### Environmental Monitor Pro

**Hardware Setup:**
- DHT22 on pin 5 (`user_led` as signal)
- LCD display via I2C (`i2c_sda`/`i2c_scl`)
- Alert buzzer on pin 6 (`led_1`)

**Board Configuration:**
```
Name: Environmental Monitor Pro
Type: nucleo-f401re
Port: /dev/ttyACM0
Baud: 115200
```

---

## ESP32 Projects

### IoT Home Automation Hub

**Hardware:**
- Built-in LED on GPIO 2 (`built_in_led`)
- Motion sensor on GPIO 4 (`gpio_4`)
- Temperature sensor on ADC pin 35 (`adc_pin`)
- Relay control on GPIO 13 (`gpio_13`)

**Configuration:**
```
Name: IoT Home Hub
Type: esp32
Port: /dev/ttyUSB0
Baud: 115200
```

---

## Raspberry Pi Projects

### Robotics Platform

**Hardware:**
- 2 DC motors: GPIO 25/26 (`motor_1_fwd`/`motor_1_rev`)
- Status LEDs: GPIO 17/27/22
- Buttons: GPIO 23/24
- IMU via I2C

**Configuration:**
```
Name: Mobile Robot Platform
Type: rpi-gpio
Transport: native
```

---

## Teensy 4.0 Projects

### Real-Time Audio Processing

**Hardware:**
- Audio I/O via I2S
- ADC on pin 14 (`analog_1`)
- Status LED on pin 13 (`led_pin`)

**Configuration:**
```
Name: Audio DSP Module
Type: teensy-40
Port: /dev/ttyACM0
Baud: 115200
```

---

## Multi-Board Systems

### Distributed Sensor Network

**Architecture:**
```
Raspberry Pi (Master)
  ├─ I2C Bus
  │  ├─ Arduino Uno (sensors, 9600 baud)
  │  └─ Teensy 4.0 (processing, 115200 baud)
  └─ ESP32 (cloud sync, WiFi)
```

---

## Quick Reference: Board Selection

| Project Type | Recommended Board | Reason |
|--------------|-------------------|--------|
| Beginners | Arduino Uno | Simple, 9600 baud |
| Real-time control | Teensy 4.0 | 600 MHz, precise timing |
| IoT/Connectivity | ESP32 | WiFi + Bluetooth built-in |
| Robotics | Raspberry Pi | GPIO flexibility |
| Industrial | Nucleo-F401RE | High speed, industrial support |

---

## Creating Your Own Project

1. **Choose base board** (see table above)
2. **Identify all hardware connections**
3. **Map pins to aliases** using option 84
4. **Write board description** with project context
5. **Add to AI context** for hardware-aware assistance

See [HARDWARE.md](../HARDWARE.md) for detailed API reference and [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI tool integration patterns.
