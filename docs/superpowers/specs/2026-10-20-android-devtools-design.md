# Android DevTools App — Design Spec

**Date:** 2026-10-20  
**Status:** Approved

## Overview

A native Android developer toolkit application that provides a tap-friendly GUI for system inspection, network analysis, security research, APK analysis, log viewing, and SSH tools. Runs on all Android devices (API 26+). Detects root at launch and gracefully unlocks advanced features — Frida instrumentation, raw network scanning, full filesystem access, root terminal — when root is available. Non-rooted devices get full access to everything achievable via standard Android APIs.

## Goals

- Replace the Termux bash toolkit with a professional native Android app
- Work on any Android device (API 26 / Android 8.0+, ~95% of active devices)
- Non-root: full functionality via Android APIs
- Root: unlocks Security tab and advanced capabilities in all other modules
- Self-contained APK — no Termux, no PC required

## Non-Goals

- iOS support (Android only)
- Cloud sync or accounts
- Remote device management from a PC
- Play Store distribution (sideload APK via ADB or direct install)

---

## Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Language | Kotlin | Android-native, full API access |
| UI | Jetpack Compose + Material Design 3 | Modern, maintained, composable |
| Min SDK | API 26 (Android 8.0) | ~95% device coverage |
| Build | Gradle with Kotlin DSL | Standard Android toolchain |
| SSH | SSHJ library | Active, pure-Java, no native deps |
| State | ViewModel + StateFlow | Jetpack standard, lifecycle-safe |
| Persistence | DataStore<Preferences> | Lightweight, async, no schema |

No database (Room/SQLite) — this is a tools app, not a data app.

---

## Project Structure

```
app/
├── src/main/
│   ├── assets/bin/
│   │   ├── frida-server-arm64      # ~50MB, extracted on first root run
│   │   ├── nmap-arm64              # bundled nmap binary
│   │   └── busybox-arm64           # bundled busybox
│   ├── java/com/devtools/android/
│   │   ├── core/
│   │   │   ├── RootDetector.kt
│   │   │   ├── ShellExecutor.kt
│   │   │   └── BinaryManager.kt
│   │   ├── modules/
│   │   │   ├── deviceinfo/
│   │   │   ├── performance/
│   │   │   ├── network/
│   │   │   ├── adb/
│   │   │   ├── security/
│   │   │   ├── apktools/
│   │   │   ├── logcat/
│   │   │   ├── files/
│   │   │   ├── ssh/
│   │   │   └── quickref/
│   │   ├── ui/
│   │   │   ├── MainScreen.kt
│   │   │   ├── navigation/
│   │   │   └── theme/
│   │   └── MainActivity.kt
│   └── res/
│       └── AndroidManifest.xml
├── build.gradle.kts
└── proguard-rules.pro
```

---

## Core Infrastructure

### RootDetector

Runs once at app start; result cached via `lazy`. Checks in order:
1. `su` binary present in `/system/bin/su`, `/system/xbin/su`, `/sbin/su`, `/su/bin/su`
2. `ro.build.tags` contains `test-keys`
3. `/system/app/Superuser.apk` or `/system/app/SuperSU` present
4. `which su` returns a path

```kotlin
object RootDetector {
    val isRooted: Boolean by lazy {
        checkSuBinary() || checkBuildTags() || checkSuperuserApp()
    }
}
```

### ShellExecutor

Wraps `Runtime.exec`. Returns a `Flow<String>` for live streaming output (logcat, frida output) and a `suspend fun execCollect` for one-shot commands. All errors surface as sealed `ShellResult`:

```kotlin
sealed class ShellResult {
    data class Success(val output: String) : ShellResult()
    object RootRequired : ShellResult()
    data class BinaryMissing(val name: String) : ShellResult()
    data class Failed(val stderr: String, val exitCode: Int) : ShellResult()
}

object ShellExecutor {
    suspend fun exec(cmd: String, root: Boolean = false): Flow<String>
    suspend fun execCollect(cmd: String, root: Boolean = false): ShellResult
}
```

### BinaryManager

On first launch (or APK update), extracts `assets/bin/*` to `context.filesDir/bin/`. Sets executable permission via root shell. Tracks extraction version in DataStore — re-extracts if APK version changed.

```kotlin
object BinaryManager {
    suspend fun ensureBinaries(context: Context): Boolean  // false = root not available
    fun binaryPath(name: String, context: Context): String
}
```

---

## Navigation

Bottom navigation bar with 5 tabs:

| Tab | Icon | Root badge |
|-----|------|------------|
| System | phone_android | — |
| Network | wifi | — |
| Security | security | 🔒 if not rooted |
| APK & Logs | bug_report | — |
| Tools | build | — |

Root-gated screens show a `RootRequiredCard` explaining the missing capability rather than hiding the tab. The Security tab is always visible — it explains what root unlocks.

---

## Feature Modules

### System Tab

**Device Info**
- Android version, build fingerprint, kernel, Java/ART version
- CPU: hardware name, core count, per-core frequency from `/proc/cpuinfo`
- RAM: total/available via `ActivityManager.MemoryInfo`
- Storage: internal/external via `StatFs`
- Battery: level, voltage, temperature, health, charging state via `BatteryManager`
- Network interfaces list
- Root adds: GPU info from `/sys/kernel/gpu` (Adreno) or `/sys/class/kgsl`

**Performance Monitor**
- Live dashboard refreshing every 2 seconds
- CPU usage per core (from `/proc/stat` delta)
- RAM used / available
- All thermal zones from `/sys/class/thermal/thermal_zone*/temp`
- Top 10 memory-consuming processes via `ActivityManager.getRunningAppProcesses()`
- Battery current draw in mA (from `/sys/class/power_supply/battery/current_now`)
- Root adds: GPU load/frequency, I/O stats

### Network Tab

**Network Info**
- WiFi SSID, BSSID, signal strength, frequency, link speed via `WifiManager`
- IP address, subnet, gateway, DNS servers via `ConnectivityManager`
- All network interfaces via `NetworkInterface.getNetworkInterfaces()`

**Port Scanner**
- Non-root: TCP connect scan using Kotlin coroutines (`Socket.connect` with timeout), no binary needed
- Input: target IP/range, port range, timeout
- Root adds: `nmap` full scan via bundled binary with output parsing

**DNS Tools**
- Forward/reverse lookup via `InetAddress`
- Custom DNS server support via `DnsResolver` (API 29+) / fallback to `dig` via busybox
- whois via busybox

**Speed Test**
- `iperf3` client connecting to user-specified iperf3 server
- Upstream/downstream/bidirectional modes
- Requires user to run iperf3 server on a PC or cloud instance

### Security Tab *(root required for all features)*

**Frida Manager**
- Start/stop frida-server (extracted from assets, runs as root daemon)
- List running processes with PIDs (`frida-ps -U`)
- Attach to process by name or PID
- Pre-built script library: SSL pinning bypass (TrustManager + OkHttp3), root detection bypass
- Custom script injection

**Process Inspector**
- Full process list via `su -c ps -A`
- Filter by name
- Kill process by PID

**Root Terminal**
- Interactive terminal emulator (using JavaTerminal or custom `TerminalView`)
- Runs `su` shell
- Command history

### APK & Logs Tab

**APK Analyzer**
- Non-root: all installed apps via `PackageManager.getInstalledPackages(GET_PERMISSIONS or GET_ACTIVITIES)`
- Shows: package name, version, permissions, activities, services, receivers, providers
- Min/target SDK, signing cert fingerprint
- APK file size and path
- Root adds: extract system APKs from `/system/app/`

**Logcat Viewer**
- Live logcat via `Runtime.exec("logcat")` with `READ_LOGS` permission
- Color-coded by level: Error=red, Warn=yellow, Info=green, Debug=cyan, Verbose=white
- Filter by package, tag, level, or text search
- Save to file
- Root adds: all process logs (non-root limited to own-app logs on API 26+ without READ_LOGS)

**Package Manager**
- List installed packages with search
- Show APK path, extract user APK to Downloads
- Launch app, view app settings, force stop
- Root adds: uninstall system apps, disable/enable packages

### Tools Tab

**SSH Client**
- Connect to remote hosts (SSHJ library)
- Password and key-based auth
- Interactive terminal session
- SCP file transfer
- Save connection profiles in DataStore

**File Browser**
- Non-root: app storage, Downloads, SD card via Storage Access Framework
- Root adds: full filesystem navigation via `su -c ls`
- File info, permissions, checksums (MD5/SHA256 via busybox)
- Copy, move, delete, rename
- Text file viewer

**Shell Terminal**
- Non-root: `sh` shell in app sandbox
- Root adds: `su` root shell
- Color prompt, command history

**Quick Reference**
- ADB cheat sheet (wireless pairing, common commands)
- Frida/objection snippets
- nmap flag reference
- Logcat filter syntax
- Keyboard-searchable

---

## Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.READ_LOGS" />
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

`READ_LOGS` and `PACKAGE_USAGE_STATS` are granted via ADB or root — the app guides the user through granting them on first launch.

---

## State Management

Each module has its own `ViewModel` with `StateFlow`. No shared global state beyond `RootDetector.isRooted`.

```kotlin
// Pattern used across all modules
class LogcatViewModel : ViewModel() {
    private val _lines = MutableStateFlow<List<LogLine>>(emptyList())
    val lines: StateFlow<List<LogLine>> = _lines.asStateFlow()
    private var captureJob: Job? = null

    fun startCapture(filter: String) {
        captureJob = viewModelScope.launch {
            ShellExecutor.exec("logcat $filter").collect { line ->
                _lines.update { it + LogLine.parse(line) }
            }
        }
    }
    fun stopCapture() { captureJob?.cancel() }
    fun clearLines() { _lines.value = emptyList() }
}
```

---

## Persistence (DataStore)

Stored preferences:
- Last SSH host/port/username
- Saved command presets (nmap, frida scripts)
- Theme preference (dark/light/system)
- Binary extraction version hash
- `READ_LOGS` / `PACKAGE_USAGE_STATS` grant status

---

## Error Handling

`ShellExecutor` wraps every command in `ShellResult`. Every screen has three states:
1. **Loading** — `CircularProgressIndicator`
2. **Error** — `ErrorCard(message, retryAction)` for transient errors; `RootRequiredCard(feature)` for root-gated
3. **Content** — the actual UI

No uncaught exceptions from shell commands. Binary extraction failures show a recovery screen.

---

## Build Variants

| Variant | Logging | R8 | Signing |
|---------|---------|-----|---------|
| `debug` | Enabled | Disabled | Debug keystore |
| `release` | Disabled | Enabled | User keystore |

---

## Testing

- Unit tests for: `RootDetector` logic, `ShellExecutor` output parsing, APK metadata parsing, `LogLine.parse()`
- `RootDetector` injected as interface so tests mock rooted/non-rooted scenarios
- Manual test matrix: rooted device, non-rooted device, Android emulator (API 26, API 34)
- No UI tests initially — app is inherently device-dependent

---

## Implementation Order

1. Project scaffold (Gradle, Manifest, theme, navigation)
2. Core: RootDetector, ShellExecutor, BinaryManager
3. System tab: Device Info, Performance Monitor
4. APK & Logs tab: Logcat Viewer, APK Analyzer, Package Manager
5. Network tab: Network Info, Port Scanner, DNS Tools
6. Tools tab: SSH Client, File Browser, Shell Terminal, Quick Reference
7. Security tab: Frida Manager, Process Inspector, Root Terminal
8. Binary bundling: frida-server, nmap, busybox assets
9. Polish: onboarding, permission grant flow, dark theme
10. Build release APK
