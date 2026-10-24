# Samsung S24 DevTools — Installation Guide

## Step 1: Install Termux (MUST use F-Droid, not Google Play)

1. Open browser on your S24
2. Go to: **https://f-droid.org**
3. Download and install F-Droid
4. Open F-Droid → Search **Termux** → Install
5. Also install **Termux:API** from F-Droid (same search)

> The Google Play version of Termux is outdated and broken. F-Droid version is required.

---

## Step 2: Get the DevTools onto Your Phone

**Option A — Clone from Git (easiest if you have the repo URL):**
```bash
# In Termux:
pkg install git -y
git clone <your-repo-url> ~/devtools
cd ~/devtools/android-devtools
bash install.sh
```

**Option B — Via USB + ADB from PC:**
```bash
# On your PC (with adb installed):
adb push android-devtools/ /sdcard/devtools/

# Then in Termux on your phone:
bash /sdcard/devtools/install.sh
```

**Option C — Via SSH (if SSH server is already running):**
```bash
scp -r android-devtools/ user@<phone-ip>:~/devtools/
```

---

## Step 3: Run the Installer

Open Termux and run:
```bash
bash ~/devtools/android-devtools/install.sh
```

The installer will:
- Grant storage access
- Update Termux packages
- Install 40+ tools (nmap, adb, tshark, frida-tools, sqlmap, objection, htop, ssh, etc.)
- Download Frida server for arm64 (matched to your frida-tools version)
- Install apktool + jadx (APK analysis)
- Set up SSH server
- Add `devtools` command to your PATH
- Add shortcut aliases

---

## Step 4: Launch

```bash
source ~/.bashrc
devtools
```

Or use shortcut aliases:
```
sysinfo      → Device info & hardware
nettools     → Network tools menu
perfmon      → Performance monitor
logwatch     → Log viewer
adbtools     → ADB & Android debug
sectools     → Security & pentesting
pkgtools     → APK & package tools
sshserver    → SSH server management
fridatools   → Frida instrumentation
```

---

## What Gets Installed

### System Packages (via pkg)
| Tool | Purpose |
|------|---------|
| `android-tools` | adb + fastboot |
| `nmap` | Network & port scanner |
| `tshark` | Wireshark CLI — packet analysis |
| `tcpdump` | Packet capture |
| `openssh` | SSH client + server |
| `htop` | Interactive process manager |
| `neofetch` | System info display |
| `mtr` | Traceroute + ping combined |
| `hydra` | Credential testing |
| `netcat-openbsd` | Network swiss army knife |
| `socat` | Data relay |
| `tor` + `proxychains-ng` | Anonymous routing |
| `gdb` + `lldb` | Debuggers |
| `strace` | System call tracer |
| `binutils` | strings, objdump, nm, readelf |
| `openjdk-17` | Java runtime |
| `python` + `nodejs` | Scripting runtimes |
| `iperf3` | Bandwidth testing |
| `dnsutils` | dig, nslookup |
| `masscan` | High-speed port scanner |

### Python Tools (via pip)
| Tool | Purpose |
|------|---------|
| `frida-tools` | Dynamic instrumentation |
| `objection` | Runtime mobile exploration |
| `sqlmap` | SQL injection testing |
| `scapy` | Packet crafting |
| `impacket` | Network protocol tools |
| `pwntools` | CTF & exploit dev toolkit |
| `androguard` | Android APK static analysis |
| `cryptography` | Crypto primitives |
| `paramiko` | SSH library |

### Java Tools (manual install)
| Tool | Purpose |
|------|---------|
| `apktool` | Decompile/recompile APKs |
| `jadx` | Decompile APKs to Java |

### Frida Server
- Matches your `frida-tools` version exactly
- Pre-built for arm64 (Snapdragon 8 Gen 3 / Samsung S24)
- Push to device via ADB with `start-frida-server`

---

## Developer Options Setup on S24

Enable before using ADB tools:

1. **Settings → About Phone → Software Information**
2. Tap **Build Number** 7 times (shows "Developer mode enabled")
3. **Settings → Developer Options:**
   - USB Debugging → ON
   - Wireless Debugging → ON (for wireless ADB)
   - Stay awake → ON (recommended)

---

## Wireless ADB (No cable needed)

1. Developer Options → Wireless Debugging → Enable
2. Tap "Pair device with pairing code"
3. In DevTools → ADB Tools → [2] Wireless ADB Setup
4. Enter the IP:port and code shown on screen

---

## Connect From PC to Phone via SSH

After starting SSH server in DevTools:
```bash
ssh -p 8022 $(whoami)@<your-phone-ip>
```

Find your phone's IP in DevTools → System Info → Network Interfaces.

---

## Notes

- **Root not required** for most tools
- Tools needing root: `tcpdump`, `frida-server`, `tombstone access`
- **Shizuku** (from Play Store) gives ADB-level permissions without root — recommended for S24
- Frida gadget injection (`objection patchapk`) works without root
- SSH server runs on port **8022** by default (not 22)
