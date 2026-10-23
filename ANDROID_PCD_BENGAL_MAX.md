# Android PCD Commands & Secrets — Bengal Max

**Device:** Bengal Max  
**Last Updated:** 2026-09-17  
**Owner:** Paul Thanson (paulthanson082@gmail.com)

---

## Quick Start

```bash
# Enable developer mode on Bengal Max
adb devices                    # List connected devices
adb shell                      # Open shell on device
adb push <file> /data/local   # Push file to device
adb pull /data/local/<file>   # Pull file from device
adb logcat                     # View device logs
```

---

## Part 1: ADB Commands Reference

### Device Connection & Info

```bash
# List connected devices
adb devices
adb devices -l                 # List with model/device info

# Get device info
adb shell getprop ro.build.version.release          # Android version
adb shell getprop ro.build.version.sdk              # SDK level
adb shell getprop ro.product.model                  # Device model (Bengal Max)
adb shell getprop ro.serialno                       # Serial number
adb shell wm size                                   # Screen resolution
adb shell dumpsys battery                           # Battery status
adb shell dumpsys thermal                           # Thermal info

# Reboot device
adb reboot                     # Normal reboot
adb reboot bootloader          # Reboot to bootloader
adb reboot recovery            # Reboot to recovery
```

### App Management

```bash
# List installed packages
adb shell pm list packages
adb shell pm list packages -3                       # Third-party only
adb shell pm list packages -s                       # System packages only

# Install APK
adb install <app.apk>
adb install -r <app.apk>                           # Force reinstall
adb install -g <app.apk>                           # Grant permissions

# Uninstall app
adb uninstall <package.name>
adb uninstall -k <package.name>                    # Keep data

# Clear app data
adb shell pm clear <package.name>

# Get app info
adb shell dumpsys package <package.name>           # App details
adb shell pm get-app-links <package.name>          # App links
```

### File Transfer

```bash
# Push (device ← host)
adb push <local-file> /data/local/tmp/<remote-file>
adb push <local-dir> /data/local/tmp/<remote-dir>/

# Pull (device → host)
adb pull /data/local/tmp/<remote-file> <local-file>
adb pull /data/local/tmp/<remote-dir>/ <local-dir>/

# List device files
adb shell ls -la /data/local/tmp
adb shell find /data -name "<filename>" 2>/dev/null
```

### Logcat & Debugging

```bash
# View logs (all)
adb logcat

# View logs filtered by tag
adb logcat -s TAG_NAME

# View logs for specific app (by PID)
adb shell ps | grep <package.name>
adb logcat --pid=<PID>

# Save logs to file
adb logcat > logcat_$(date +%s).log

# Clear logs
adb logcat -c

# View system events
adb shell dumpsys events

# Monitor in real-time
adb logcat -v threadtime                           # Timestamp + thread
adb logcat -v time                                 # Timestamp only
```

### Shell Commands on Device

```bash
# Open interactive shell
adb shell

# Inside shell:
su                             # Become root (if available)
cat /proc/version              # Kernel version
free -m                        # Memory usage
df -h                          # Disk usage
netstat -tuln                  # Network connections
ps aux                         # Running processes
top                            # Real-time processes
```

### Database & Storage Access

```bash
# Access app databases
adb shell run-as <package.name> cat /data/data/<package.name>/databases/<db.sqlite>

# Access shared preferences
adb shell run-as <package.name> cat /data/data/<package.name>/shared_prefs/*.xml

# View app storage
adb shell ls -la /data/data/<package.name>/

# Check storage permissions
adb shell dumpsys package <package.name> | grep permissions
```

### Network Testing

```bash
# Check network connectivity
adb shell ping -c 4 8.8.8.8

# Test DNS resolution
adb shell nslookup google.com

# View network interface info
adb shell ifconfig
adb shell ip link show

# Monitor network traffic
adb shell netstat -i
adb shell iptables -L -n -v
```

### Performance & Profiling

```bash
# CPU usage
adb shell top -m 5                                 # Top 5 processes
adb shell ps -o %CPU,%MEM,COMMAND

# Memory dump
adb shell dumpsys meminfo <package.name>

# ANR (Application Not Responding) traces
adb shell cat /data/anr/traces.txt

# Frame rate / GPU profiling
adb shell dumpsys gfxinfo <package.name>

# Battery drain
adb shell dumpsys batterystats
```

### Accessibility & Input

```bash
# Tap screen
adb shell input tap <x> <y>

# Swipe
adb shell input swipe <x1> <y1> <x2> <y2> <duration_ms>

# Type text
adb shell input text "Hello World"

# Key press (HOME, BACK, MENU, etc.)
adb shell input keyevent 3                         # HOME
adb shell input keyevent 4                         # BACK
adb shell input keyevent 82                        # MENU
```

### System Settings

```bash
# View/set system properties
adb shell getprop ro.build.fingerprint
adb shell setprop debug.force_rtl true             # RTL debugging

# Enable/disable WiFi
adb shell svc wifi enable
adb shell svc wifi disable

# Enable/disable Bluetooth
adb shell svc bluetooth enable
adb shell svc bluetooth disable

# Screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Screen recording
adb shell screenrecord /sdcard/recording.mp4
# (Press Ctrl+C to stop; then pull file)
```

---

## Part 2: Device Configuration & Secrets

### Required Credentials & API Keys

Store these in a **`.env.local`** file (never commit to git):

```bash
# .env.local (ADD TO .gitignore)

# Device Connection
DEVICE_SERIAL=<bengal-max-serial-number>
DEVICE_IP=<192.168.x.x>
DEVICE_PORT=5555

# Firebase / Backend Services
FIREBASE_API_KEY=<your-firebase-key>
FIREBASE_PROJECT_ID=<your-firebase-project>
FIREBASE_MESSAGING_SENDER_ID=<sender-id>

# Claude API (for Jules mobile app if used)
ANTHROPIC_API_KEY=<your-anthropic-api-key>

# Database Credentials
DB_USER=<database-user>
DB_PASSWORD=<database-password>
DB_HOST=<database-host>
DB_PORT=<database-port>

# WiFi Debugging (Optional)
ADB_WIFI_HOST=<device-ip>
ADB_WIFI_PORT=5555

# Test Accounts
TEST_USER_EMAIL=<test@example.com>
TEST_USER_PASSWORD=<test-password>
TEST_DEVICE_ID=<test-device-id>
```

### Setup Instructions

#### 1. Enable Developer Mode
```bash
Settings → About phone → Build number
Tap 7 times to enable Developer Options

Settings → System → Developer Options
- Enable USB Debugging
- Enable Wireless Debugging (if available)
- Disable "Verify apps over USB" (optional, for faster installs)
```

#### 2. Connect via USB
```bash
# Plug Bengal Max into computer via USB
adb devices
# You'll see a popup on device — tap "Allow" to authorize

# Verify connection
adb shell getprop ro.product.model
# Should output: Bengal Max
```

#### 3. Connect via WiFi (Wireless ADB)
```bash
# On device:
Settings → System → Developer Options → Wireless Debugging
Note the IP address and port (usually 5555)

# On host:
adb connect <device-ip>:5555
adb devices                    # Confirm connection

# Disconnect USB (optional now)
```

#### 4. Load Secrets from .env.local
```bash
# Source your .env.local before running scripts
source .env.local

# Or in your build/deploy script:
export $(cat .env.local | xargs)
adb -s $DEVICE_SERIAL shell getprop ro.build.version.release
```

### Device-Specific Properties

```bash
# View all properties on Bengal Max
adb shell getprop

# Key properties for Bengal Max:
ro.build.version.release       # Android version
ro.build.version.sdk           # SDK level
ro.product.model               # "Bengal Max"
ro.product.manufacturer        # Device manufacturer
ro.hardware                     # Hardware platform
ro.board.platform              # Board platform
ro.build.fingerprint           # Build fingerprint (unique ID)
ro.serialno                     # Device serial number
ro.build.id                     # Build ID
ro.build.date.utc              # Build timestamp
```

### Keystore & Certificate Management

```bash
# List keystores on device
adb shell ls -la ~/.android/

# View debug keystore info
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Export debug certificate
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | openssl x509 -inform DER -text
```

---

## Part 3: Development Workflows

### Deploy to Bengal Max

```bash
# Build and install (from friendly-outlaw mobile app)
cd mobile
npx expo start --android

# Or manually build APK:
cd mobile
npm run build:android
adb install build/outputs/apk/debug/app-debug.apk

# With logging:
adb logcat -s "WritersApp" &
npm run start
```

### Run Tests on Device

```bash
# Push test data
adb push test_data/ /data/local/tmp/test_data/

# Run app tests
adb shell am instrument -w <package.name>.test/androidx.test.runner.AndroidJUnitRunner

# Collect results
adb pull /data/local/tmp/test_results.xml ./
```

### Monitor in Real-Time

```bash
# Watch logs while app runs
adb logcat -v threadtime | grep "WritersApp\|Jules\|Error"

# Watch memory usage
watch -n 1 'adb shell dumpsys meminfo | head -20'

# Watch battery drain
watch -n 5 'adb shell dumpsys battery'
```

### Backup & Restore

```bash
# Full device backup
adb backup -all -f bengal-max-backup-$(date +%s).ab

# Restore backup
adb restore bengal-max-backup-<timestamp>.ab

# Backup specific app
adb backup -apk <package.name> -f app-backup.ab

# Extract APK from device
adb shell pm path <package.name>              # Get path
adb pull /data/app/<path> app.apk
```

---

## Part 4: Troubleshooting

### Device Not Detected

```bash
# Check USB connection
lsusb | grep -i android

# Restart ADB daemon
adb kill-server
adb start-server
adb devices

# Unplug/replug USB, tap "Allow" on device

# On Linux, may need udev rules:
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="<vendor-id>", MODE="0666"' | sudo tee /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
```

### Slow ADB Transfer

```bash
# Use USB 3.0 port (faster than USB 2.0)
# Reduce resolution/frame rate if transferring video

# Check connection quality
adb shell cat /proc/net/tcp
adb shell netstat -i
```

### Permission Denied Errors

```bash
# Grant permissions at install time
adb install -g <app.apk>

# Or via shell
adb shell pm grant <package.name> android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant <package.name> android.permission.WRITE_EXTERNAL_STORAGE
```

### App Crashes / ANR

```bash
# View crash log
adb logcat *:E

# Capture ANR trace
adb pull /data/anr/traces.txt ./traces.txt
cat traces.txt | head -100

# Clear app and retry
adb shell pm clear <package.name>
```

---

## Security Best Practices

✅ **DO:**
- Store `.env.local` with secrets in `.gitignore`
- Use separate test/production credentials
- Rotate API keys regularly
- Enable USB Debugging only when needed
- Disable Wireless Debugging when not in use
- Keep Android OS updated

❌ **DON'T:**
- Commit `.env.local` to git
- Share serial numbers or device IDs publicly
- Use production API keys for testing
- Leave root access enabled (`su`)
- Enable "Unknown Sources" unless necessary
- Store plaintext passwords in code/logs

---

## File Organization

```
friendly-outlaw/
├── ANDROID_PCD_BENGAL_MAX.md      # This file
├── .env.local                      # Secrets (NEVER COMMIT)
├── .env.local.example              # Template for team
├── mobile/
│   ├── src/
│   ├── package.json
│   └── eas.json                    # EAS Build config
└── scripts/
    └── deploy_to_bengal.sh         # Deploy script
```

### .env.local.example (commit this, NOT .env.local)

```bash
# Copy this file to .env.local and fill in real values
# .env.local is in .gitignore and will never be committed

DEVICE_SERIAL=<your-device-serial>
DEVICE_IP=<your-device-ip>
FIREBASE_API_KEY=<get-from-firebase-console>
ANTHROPIC_API_KEY=<get-from-anthropic>
TEST_USER_EMAIL=<test-account-email>
TEST_USER_PASSWORD=<test-account-password>
```

---

## Quick Reference Cheat Sheet

| Task | Command |
|------|---------|
| Connect device | `adb devices` |
| Install app | `adb install app.apk` |
| View logs | `adb logcat -s TAG` |
| Push file | `adb push file /data/local/` |
| Pull file | `adb pull /data/local/file .` |
| Shell access | `adb shell` |
| Reboot device | `adb reboot` |
| Screenshot | `adb shell screencap -p /sdcard/ss.png` |
| Clear app | `adb shell pm clear package.name` |
| Grant perms | `adb install -g app.apk` |

---

## Links & Resources

- [Android Debug Bridge (ADB) Docs](https://developer.android.com/studio/command-line/adb)
- [Android Developer Options](https://developer.android.com/studio/debug/dev-options)
- [ADB Shell Command Reference](https://developer.android.com/reference/android/os/Debug)
- [friendly-outlaw Mobile App Docs](./mobile/README.md)

---

**Last tested:** 2026-09-17  
**Android Version:** Check with `adb shell getprop ro.build.version.release`  
**Questions?** Refer to `.claude/project.md` or run `./scripts/deploy_to_bengal.sh --help`
