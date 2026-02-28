# Hardware Setup Guide

Complete platform-specific instructions for connecting and configuring hardware boards with friendly-outlaw.

## Prerequisites

- friendly-outlaw CLI installed and working
- A supported microcontroller board (Arduino, Nucleo, ESP32, Raspberry Pi, Teensy)
- USB cable (for serial boards) or appropriate connection method
- Optional: Device drivers (platform-dependent)

## macOS Setup

### Finding Your Serial Port

1. Plug in your board via USB
2. Open Terminal and list USB devices:
   ```bash
   ls /dev/cu.usb*
   ```
   You should see something like:
   - `/dev/cu.usbmodem14201` (Arduino)
   - `/dev/cu.usbserial-0001` (Nucleo)

3. Note the port path for CLI configuration

### Installing Drivers (if needed)

**Arduino Boards:**
- Download: https://www.arduino.cc/en/software
- Run installer, drivers auto-install

**ST-Link (Nucleo/STM32):**
- Download: https://www.st.com/en/development-tools/stsw-link009.html
- Follow ST-Link installation instructions

**ESP32:**
- Usually auto-detected (built-in CP210x driver on macOS 10.11+)
- If needed: http://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers

### Testing Connection

```bash
# List all serial ports
ls /dev/cu.usb*

# Check if device responds (replace with your port)
screen /dev/cu.usbmodem14201 9600

# Press Ctrl+A, then Ctrl+\ to exit screen
```

## Linux Setup

### Finding Your Serial Port

1. Plug in board and check system messages:
   ```bash
   dmesg | tail -20
   ```

2. Or list tty devices:
   ```bash
   ls /dev/tty*
   ```
   Look for `/dev/ttyUSB*` or `/dev/ttyACM*`

3. Check which device it is:
   ```bash
   ls -la /dev/tty* | grep -E 'USB|ACM'
   ```

### Installing Drivers

**Arduino Boards:**
- Usually work out-of-the-box
- If not: `sudo apt-get install arduino`

**Nucleo/STM32 (STLink):**
```bash
sudo apt-get install stlink-tools libusb-1.0-0
```

**ESP32:**
```bash
sudo apt-get install python3 python3-pip
pip3 install esptool
```

### Setting Permissions

By default, you need `sudo` to access serial ports. To allow user access:

```bash
# Add current user to dialout group
sudo usermod -aG dialout $USER

# Apply group changes (logout/login, or run)
newgrp dialout

# Verify
groups $USER
# Should show: user wheel dialout (or similar)
```

### Testing Connection

```bash
# Install minicom if not present
sudo apt-get install minicom

# Connect to board (replace port and baud)
minicom -D /dev/ttyUSB0 -b 9600

# Press Ctrl+A, then X to exit
```

## Windows Setup

### Finding Your Serial Port

1. Plug in board via USB
2. Open Device Manager (Win+X → Device Manager)
3. Look under "Ports (COM & LPT)"
4. Your board should appear as "COMx" (e.g., COM3, COM4)

### Installing Drivers

**Arduino Boards:**
- Download IDE: https://www.arduino.cc/en/software
- Run installer → includes USB drivers

**Nucleo/STM32:**
- Download: https://www.st.com/en/development-tools/stsw-link009.html
- Run installer

**ESP32:**
- Download driver: http://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers
- Run installer

### Testing Connection

1. Open Device Manager
2. Right-click on COM port → Properties
3. Check status shows "This device is working properly"

Or use PuTTY:
- Download: https://www.putty.org/
- Open serial session: COM3 @ 9600 baud

## Board-Specific Setup

### Arduino Uno

**Default Baud Rate:** 9600

**Serial Port:**
- macOS: `/dev/cu.usbmodem*`
- Linux: `/dev/ttyUSB0`
- Windows: COM3 (typical)

**Setup Steps:**
1. Connect via USB
2. Wait 2-3 seconds for driver to load
3. Use above commands to find port
4. Configure in CLI:
   ```
   Board name: My Arduino
   Board type: arduino-uno
   Serial port: [your port]
   Baud rate: 9600
   ```

**Default Pin Aliases:**
- `red_led` → Pin 13
- `button` → Pin 2
- `analog_sensor` → A0
- `pwm_pin` → Pin 3

### Nucleo-F401RE

**Default Baud Rate:** 115200

**Serial Port:**
- macOS: `/dev/cu.usbmodem*` or `/dev/cu.usbserial-*`
- Linux: `/dev/ttyACM0`
- Windows: COM4 (typical)

**Setup Steps:**
1. Connect via STLink USB
2. STLink drivers auto-install (macOS) or require manual install
3. Find port using above commands
4. Configure in CLI:
   ```
   Board name: My Nucleo
   Board type: nucleo-f401re
   Serial port: [your port]
   Baud rate: 115200
   ```

**Default Pin Aliases:**
- `user_led` → Pin 5
- `user_button` → Pin 13
- `uart_tx` → Pin 1
- `uart_rx` → Pin 0

### ESP32

**Default Baud Rate:** 115200

**Serial Port:**
- macOS: `/dev/cu.usbserial-*` (with driver) or auto-detected
- Linux: `/dev/ttyUSB0`
- Windows: COM5 (typical)

**Setup:**
1. Download firmware uploader if flashing from friendly-outlaw
2. Connect via Micro-USB
3. Find port using platform commands
4. Configure:
   ```
   Board name: My ESP32
   Board type: esp32
   Serial port: [your port]
   Baud rate: 115200
   ```

**Pin Notes:**
- 25 GPIO pins
- PWM support on most pins
- 12 ADC channels
- Wireless: WiFi + Bluetooth

### Raspberry Pi (GPIO)

**Default:** Native GPIO (no serial cable needed)

**Setup:**
1. Ensure GPIO pins accessible (Linux only)
2. Configure:
   ```
   Board name: My Pi
   Board type: rpi-gpio
   Transport: native
   Serial port: native
   ```

**Pin Layout:**
- 40-pin GPIO header (BCM numbering)
- Add aliases for your connected peripherals

## Troubleshooting

### Serial Port Not Appearing

1. **Check USB cable**: Try different USB port
2. **Check Device Manager/dmesg** for unknown devices
3. **Install drivers**: See board-specific setup above
4. **Restart application**: Sometimes USB detection lags
5. **Restart computer**: Last resort for driver issues

### "Port Already in Use" Error

1. Check if another application is using the port:
   - macOS: `lsof | grep USB`
   - Linux: `lsof | grep tty`
   - Windows: Device Manager → Properties

2. Close other applications (IDE, serial monitor, etc.)
3. Try restarting

### Baud Rate Mismatch

- Symptoms: Garbled output, no connection
- **Fix**: Check board's firmware/bootloader baud rate
- Must match between board and CLI configuration
- Common rates: 9600, 115200

### Permission Denied (Linux)

```bash
# Add user to dialout group
sudo usermod -aG dialout $USER
newgrp dialout
```

### Driver Installation Failed

1. Unplug board
2. Reboot system
3. Plug board back in
4. Retry driver installation
5. If still failing, check board manufacturer's support

## Testing Your Setup

Once board is connected and configured:

```bash
# In CLI, select option 82: "View Board Details"
# Should show:
# - Board name
# - Serial port (/dev/ttyUSB0, etc.)
# - Baud rate
# - Status: Active or Inactive

# Test connection:
# Select option 80-85 for hardware operations
# Should respond without errors
```

## Next Steps

- See [HARDWARE.md](../HARDWARE.md) for general hardware overview
- See [ADD_CUSTOM_BOARD.md](ADD_CUSTOM_BOARD.md) for custom boards
- See [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI integration
