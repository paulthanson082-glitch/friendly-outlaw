# Hardware Setup Guide

Complete platform-specific instructions for connecting and configuring hardware boards with friendly-outlaw.

## Prerequisites

- friendly-outlaw CLI installed and working (`swift run WritersAppCLI`)
- A supported microcontroller board (Arduino, Nucleo, ESP32, Raspberry Pi, Teensy)
- USB cable (for serial boards) or appropriate connection method

## macOS Setup

### Finding Your Serial Port

```bash
ls /dev/cu.usb*
# Example: /dev/cu.usbmodem14201
```

### Testing Connection

```bash
screen /dev/cu.usbmodem14201 9600
# Press Ctrl+A, then Ctrl+\ to exit screen
```

## Linux Setup

### Finding Your Serial Port

```bash
dmesg | tail -20
ls /dev/tty* | grep -E 'USB|ACM'
```

### Setting Permissions

```bash
sudo usermod -aG dialout $USER
newgrp dialout
```

## Windows Setup

1. Open Device Manager (Win+X → Device Manager)
2. Look under "Ports (COM & LPT)"
3. Your board appears as "COMx" (e.g., COM3, COM4)

## Board-Specific Setup

### Arduino Uno
- **Default Baud Rate:** 9600
- macOS: `/dev/cu.usbmodem*`
- Linux: `/dev/ttyUSB0`
- Windows: COM3 (typical)

### Nucleo-F401RE
- **Default Baud Rate:** 115200
- macOS: `/dev/cu.usbmodem*`
- Linux: `/dev/ttyACM0`
- Windows: COM4 (typical)

### ESP32
- **Default Baud Rate:** 115200
- macOS: `/dev/cu.usbserial-*`
- Linux: `/dev/ttyUSB0`
- Windows: COM5 (typical)

### Raspberry Pi (GPIO)
- **Transport:** Native GPIO (no serial cable needed)
- Configure with transport type `native`

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Port not found | Check USB cable, try different port |
| Permission denied (Linux) | Run `sudo usermod -aG dialout $USER` |
| Baud rate mismatch | Verify firmware baud rate matches CLI config |
| Port already in use | Close other serial applications |

## Next Steps

- See [HARDWARE.md](../HARDWARE.md) for general hardware overview
- See [CUSTOM_BOARD_SETUP.md](CUSTOM_BOARD_SETUP.md) for custom boards
- See [CUSTOM_TOOLS.md](CUSTOM_TOOLS.md) for AI integration
