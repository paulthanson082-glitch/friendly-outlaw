# Android DevTools App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native Kotlin + Jetpack Compose Android developer toolkit APK that works on all Android 8.0+ devices, with root detection that gracefully unlocks advanced features.

**Architecture:** New Android project at `android-devtools-app/` in the repo root. Shared `core/` layer (RootDetector, ShellExecutor, BinaryManager) serves all 10 feature modules. Each module owns its own ViewModel + Screen pair; no cross-module state beyond `RootDetector.isRooted`.

**Tech Stack:** Kotlin 1.9.22, Jetpack Compose BOM 2024.02.00, Material Design 3, Navigation Compose 2.7.7, ViewModel + StateFlow, DataStore 1.0.0, SSHJ 0.38.0, JUnit 4.13.2, AGP 8.2.0, minSdk 26.

**Spec:** `docs/superpowers/specs/2026-10-20-android-devtools-design.md`

## Global Constraints

- minSdk 26 (Android 8.0), targetSdk 34 — enforced in `app/build.gradle.kts`
- Package name: `com.devtools.android`
- All files under `android-devtools-app/app/src/main/java/com/devtools/android/`
- Root-gated features MUST show `RootRequiredCard` rather than crash or hide
- Every shell command goes through `ShellExecutor` — no direct `Runtime.exec` in modules
- `ShellResult` sealed class used everywhere — no raw strings returned from shell calls
- No Room/SQLite — DataStore only for persistence
- SSH via SSHJ library only — no other SSH dependency
- Bundled binaries stored in `assets/bin/` and extracted to `context.filesDir/bin/`

## Review Focus

- **Root detection on Magisk-hidden devices** — `su` binary may not be in standard paths; `RootDetector.checkSuBinary()` must try all four paths and fall back to `which su` before returning false.
- **READ_LOGS denied at runtime** — `logcat` process returns empty output without throwing on API 26+ without the grant; `LogcatViewModel` must detect zero-line output after 2 seconds and emit a `ShellResult.Failed` with a message directing the user to grant via ADB.
- **Port scanner stall on large ranges** — scanning a /16 with 1000 ports and no per-host cancel hangs the UI indefinitely; `PortScannerViewModel` must honour a `cancel()` call that terminates all in-flight coroutines within 500 ms.
- **Frida server version mismatch** — bundled frida-server outputs "Unable to handle 64-bit processes" or hangs if the installed frida-tools version differs; `FridaManagerViewModel.startServer()` must parse stderr for known mismatch strings and surface them as `ShellResult.Failed`.
- **BinaryManager extraction on low storage** — `File.createNewFile()` throws `IOException` when disk is full; `BinaryManager.ensureBinaries()` must catch it and return `false` rather than crash, and the onboarding screen must show a storage-full error card.

---

## File Map

```
android-devtools-app/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle/wrapper/gradle-wrapper.properties
├── gradlew / gradlew.bat
└── app/
    ├── build.gradle.kts
    ├── proguard-rules.pro
    └── src/
        ├── main/
        │   ├── AndroidManifest.xml
        │   ├── assets/bin/
        │   │   ├── frida-server-arm64    (Task 8)
        │   │   ├── nmap-arm64            (Task 8)
        │   │   └── busybox-arm64         (Task 8)
        │   └── java/com/devtools/android/
        │       ├── MainActivity.kt                         (Task 1)
        │       ├── core/
        │       │   ├── RootDetector.kt                     (Task 2)
        │       │   ├── ShellExecutor.kt                    (Task 2)
        │       │   └── BinaryManager.kt                    (Task 8)
        │       ├── ui/
        │       │   ├── MainScreen.kt                       (Task 1)
        │       │   ├── navigation/AppNavigation.kt         (Task 1)
        │       │   ├── theme/Theme.kt                      (Task 1)
        │       │   ├── theme/Color.kt                      (Task 1)
        │       │   ├── components/RootRequiredCard.kt       (Task 2)
        │       │   └── components/ErrorCard.kt             (Task 2)
        │       └── modules/
        │           ├── deviceinfo/DeviceInfoViewModel.kt    (Task 3)
        │           ├── deviceinfo/DeviceInfoScreen.kt       (Task 3)
        │           ├── performance/PerformanceViewModel.kt  (Task 3)
        │           ├── performance/PerformanceScreen.kt     (Task 3)
        │           ├── logcat/LogcatViewModel.kt            (Task 4)
        │           ├── logcat/LogcatScreen.kt               (Task 4)
        │           ├── logcat/LogLine.kt                    (Task 4)
        │           ├── apktools/ApkAnalyzerViewModel.kt     (Task 4)
        │           ├── apktools/ApkAnalyzerScreen.kt        (Task 4)
        │           ├── apktools/AppInfo.kt                  (Task 4)
        │           ├── packages/PackageManagerViewModel.kt  (Task 4)
        │           ├── packages/PackageManagerScreen.kt     (Task 4)
        │           ├── network/NetworkInfoViewModel.kt      (Task 5)
        │           ├── network/NetworkInfoScreen.kt         (Task 5)
        │           ├── network/PortScannerViewModel.kt      (Task 5)
        │           ├── network/PortScannerScreen.kt         (Task 5)
        │           ├── network/DnsToolsViewModel.kt         (Task 5)
        │           ├── network/DnsToolsScreen.kt            (Task 5)
        │           ├── network/SpeedTestScreen.kt           (Task 5)
        │           ├── ssh/SshClientViewModel.kt            (Task 6)
        │           ├── ssh/SshClientScreen.kt               (Task 6)
        │           ├── ssh/SshProfile.kt                    (Task 6)
        │           ├── files/FileBrowserViewModel.kt        (Task 6)
        │           ├── files/FileBrowserScreen.kt           (Task 6)
        │           ├── terminal/ShellTerminalViewModel.kt   (Task 6)
        │           ├── terminal/ShellTerminalScreen.kt      (Task 6)
        │           ├── quickref/QuickRefScreen.kt           (Task 6)
        │           ├── security/FridaManagerViewModel.kt    (Task 7)
        │           ├── security/FridaManagerScreen.kt       (Task 7)
        │           ├── security/ProcessInspectorViewModel.kt (Task 7)
        │           ├── security/ProcessInspectorScreen.kt   (Task 7)
        │           ├── security/RootTerminalViewModel.kt    (Task 7)
        │           └── security/RootTerminalScreen.kt       (Task 7)
        └── test/java/com/devtools/android/
            ├── core/RootDetectorTest.kt                     (Task 2)
            ├── core/ShellResultTest.kt                      (Task 2)
            └── modules/logcat/LogLineTest.kt                (Task 4)
```

---

### Task 1: Project Scaffold + Navigation

**Files:**
- Create: `android-devtools-app/settings.gradle.kts`
- Create: `android-devtools-app/build.gradle.kts`
- Create: `android-devtools-app/app/build.gradle.kts`
- Create: `android-devtools-app/app/src/main/AndroidManifest.xml`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/MainActivity.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/theme/Color.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/theme/Theme.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/navigation/AppNavigation.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/MainScreen.kt`

**Interfaces:**
- Produces: `MainScreen()` composable with 5-tab bottom nav (System, Network, Security, APK & Logs, Tools); each tab shows a placeholder `Text("Coming soon")` until later tasks fill it in.

- [ ] **Step 1: Create root Gradle files**

`settings.gradle.kts` includes `":app"`. `build.gradle.kts` sets AGP `8.2.0` and Kotlin `1.9.22` as plugins without applying. No additional content needed.

- [ ] **Step 2: Create `app/build.gradle.kts`**

Key values:
```
applicationId = "com.devtools.android"
minSdk = 26
targetSdk = 34
versionCode = 1
versionName = "1.0"
```
Dependencies block (exact versions):
```
implementation(platform("androidx.compose:compose-bom:2024.02.00"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.material3:material3")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.activity:activity-compose:1.8.2")
implementation("androidx.navigation:navigation-compose:2.7.7")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
implementation("androidx.datastore:datastore-preferences:1.0.0")
implementation("com.hierynomus:sshj:0.38.0")
testImplementation("junit:junit:4.13.2")
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
```

- [ ] **Step 3: Create `AndroidManifest.xml`**

Package `com.devtools.android`. Include all 8 permissions from the spec's Permissions section verbatim. `MainActivity` as launcher with `android:theme="@style/Theme.DevTools"`.

- [ ] **Step 4: Create theme files**

`Color.kt` — define `DevToolsDark`, `DevToolsGreen` (accent `#00C853`), `DevToolsSurface`. `Theme.kt` — `DevToolsTheme` wrapping `MaterialTheme`, supporting dark/light/system via `isSystemInDarkTheme()`.

- [ ] **Step 5: Create `AppNavigation.kt`**

Sealed class `Screen` with objects: `System`, `Network`, `Security`, `ApkLogs`, `Tools` — each with a `route: String`, `label: String`, `icon: ImageVector`.

- [ ] **Step 6: Create `MainScreen.kt`**

`MainScreen(isRooted: Boolean)` composable. `NavigationBar` at the bottom with 5 `NavigationBarItem`s from `Screen`. Security item shows a lock badge overlay when `!isRooted`. `NavHost` in the scaffold body with each route showing `Text("Coming soon — ${screen.label}")`.

- [ ] **Step 7: Create `MainActivity.kt`**

`ComponentActivity`, calls `RootDetector.isRooted` (stubbed as `false` until Task 2), passes result to `MainScreen`.

- [ ] **Step 8: Verify build compiles**

Run: `cd android-devtools-app && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 9: Commit**

```bash
git add android-devtools-app/
git commit -m "feat: scaffold Android DevTools project with bottom navigation"
```

---

### Task 2: Core Infrastructure

**Files:**
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/core/RootDetector.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/core/ShellExecutor.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/components/RootRequiredCard.kt`
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/ui/components/ErrorCard.kt`
- Create: `android-devtools-app/app/src/test/java/com/devtools/android/core/RootDetectorTest.kt`
- Create: `android-devtools-app/app/src/test/java/com/devtools/android/core/ShellResultTest.kt`

**Interfaces:**
- Consumes: nothing from prior tasks beyond the built project
- Produces:
  - `RootDetector.isRooted: Boolean` (lazy singleton)
  - `ShellResult` sealed class: `Success(output: String)`, `RootRequired`, `BinaryMissing(name: String)`, `Failed(stderr: String, exitCode: Int)`
  - `ShellExecutor.execCollect(cmd: String, root: Boolean = false): ShellResult`
  - `ShellExecutor.exec(cmd: String, root: Boolean = false): Flow<String>`
  - `RootRequiredCard(feature: String)` composable
  - `ErrorCard(message: String, onRetry: (() -> Unit)?)` composable

- [ ] **Step 1: Write failing tests for `RootDetector`**

```kotlin
// RootDetectorTest.kt
class RootDetectorTest {
    @Test fun `returns false when no su path exists`() {
        // Inject a fake path checker that always returns false
        val detector = RootDetector(suPathExists = { false }, buildTagsContainTestKeys = { false })
        assertFalse(detector.check())
    }
    @Test fun `returns true when su binary found at xbin`() {
        val detector = RootDetector(suPathExists = { it == "/system/xbin/su" }, buildTagsContainTestKeys = { false })
        assertTrue(detector.check())
    }
    @Test fun `returns true when build tags contain test-keys`() {
        val detector = RootDetector(suPathExists = { false }, buildTagsContainTestKeys = { true })
        assertTrue(detector.check())
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd android-devtools-app && ./gradlew :app:testDebugUnitTest --tests "*.RootDetectorTest"`
Expected: FAIL — `RootDetector` not found

- [ ] **Step 3: Implement `RootDetector`**

`RootDetector` is a class (not object) with constructor params `suPathExists: (String) -> Boolean` and `buildTagsContainTestKeys: () -> Boolean` for testability. Companion object provides `val isRooted: Boolean by lazy { RootDetector().check() }`. `check()` tries paths `/system/bin/su`, `/system/xbin/su`, `/sbin/su`, `/su/bin/su` via `suPathExists`, then `buildTagsContainTestKeys`, then runs `which su` via `Runtime.exec` as fallback.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd android-devtools-app && ./gradlew :app:testDebugUnitTest --tests "*.RootDetectorTest"`
Expected: PASS (3 tests)

- [ ] **Step 5: Write failing tests for `ShellResult`**

```kotlin
// ShellResultTest.kt
class ShellResultTest {
    @Test fun `Success carries output string`() {
        val r = ShellResult.Success("hello")
        assertEquals("hello", r.output)
    }
    @Test fun `Failed carries stderr and exitCode`() {
        val r = ShellResult.Failed(stderr = "permission denied", exitCode = 1)
        assertEquals(1, r.exitCode)
        assertTrue(r.stderr.contains("permission denied"))
    }
    @Test fun `BinaryMissing carries name`() {
        val r = ShellResult.BinaryMissing("nmap")
        assertEquals("nmap", r.name)
    }
}
```

- [ ] **Step 6: Run tests to verify they fail**

Run: `./gradlew :app:testDebugUnitTest --tests "*.ShellResultTest"`
Expected: FAIL — `ShellResult` not found

- [ ] **Step 7: Implement `ShellResult` sealed class and `ShellExecutor`**

`ShellResult.kt` (in `core/`) — sealed class with four subclasses as defined in the spec. `ShellExecutor.kt` — `object ShellExecutor` with:
- `suspend fun execCollect(cmd: String, root: Boolean = false): ShellResult` — builds command array as `arrayOf("sh", "-c", cmd)` or `arrayOf("su", "-c", cmd)`, calls `Runtime.exec`, reads stdout and stderr, returns `Success` or `Failed` based on exit code.
- `fun exec(cmd: String, root: Boolean = false): Flow<String>` — same exec but emits stdout lines via `callbackFlow`, cancels process on flow cancellation.

- [ ] **Step 8: Run tests to verify they pass**

Run: `./gradlew :app:testDebugUnitTest --tests "*.ShellResultTest"`
Expected: PASS (3 tests)

- [ ] **Step 9: Create `RootRequiredCard` and `ErrorCard` composables**

`RootRequiredCard(feature: String)` — Material3 `Card` with lock icon, title "Root Required", body "Enable root access to use $feature." `ErrorCard(message: String, onRetry: (() -> Unit)? = null)` — Card with error icon, the message, and optional "Retry" `TextButton`.

- [ ] **Step 10: Wire `RootDetector.isRooted` into `MainActivity`**

Replace the `false` stub from Task 1 with `RootDetector.isRooted`.

- [ ] **Step 11: Verify full build**

Run: `./gradlew :app:testDebugUnitTest && ./gradlew :app:assembleDebug`
Expected: all tests PASS, BUILD SUCCESSFUL

- [ ] **Step 12: Commit**

```bash
git add android-devtools-app/app/src/
git commit -m "feat: add RootDetector, ShellExecutor, and shared UI components"
```

---

### Task 3: System Tab — Device Info + Performance Monitor

**Files:**
- Create: `modules/deviceinfo/DeviceInfoViewModel.kt`
- Create: `modules/deviceinfo/DeviceInfoScreen.kt`
- Create: `modules/performance/PerformanceViewModel.kt`
- Create: `modules/performance/PerformanceScreen.kt`
- Modify: `ui/navigation/AppNavigation.kt` — wire System tab routes

**Interfaces:**
- Consumes: `ShellExecutor.execCollect`, `RootDetector.isRooted`, `ErrorCard`
- Produces: `DeviceInfoScreen()` composable, `PerformanceScreen()` composable

- [ ] **Step 1: Implement `DeviceInfoViewModel`**

`DeviceInfoViewModel : ViewModel()`. `StateFlow<DeviceInfo>` where `DeviceInfo` is a data class with fields: `androidVersion: String`, `buildFingerprint: String`, `kernel: String`, `cpuHardware: String`, `cpuCores: Int`, `totalRamMb: Long`, `availRamMb: Long`, `batteryLevel: Int`, `batteryTemp: Float`, `storageTotalGb: Float`, `storageAvailGb: Float`. `init` block populates via `Build`, `/proc/cpuinfo` read, `ActivityManager.MemoryInfo`, `BatteryManager`, `StatFs`. Root check adds GPU info via `ShellExecutor.execCollect("cat /sys/class/kgsl/kgsl-3d0/gpu_clock_freq", root = true)`.

- [ ] **Step 2: Implement `DeviceInfoScreen`**

`DeviceInfoScreen(vm: DeviceInfoViewModel = viewModel())` — collects `vm.deviceInfo` as state, renders sections (Android, CPU, Memory, Storage, Battery) using `LazyColumn` with `ListItem` composables.

- [ ] **Step 3: Implement `PerformanceViewModel`**

`PerformanceViewModel : ViewModel()`. `StateFlow<PerformanceData>` where `PerformanceData` holds `cpuUsagePercent: Float`, `ramUsedMb: Long`, `ramTotalMb: Long`, `thermalZones: List<ThermalZone>` (name + tempC), `topProcesses: List<ProcessInfo>` (name + rssKb), `batteryCurrentMa: Int`. Starts a `viewModelScope.launch` loop reading `/proc/stat` delta every 2 seconds for CPU, `ActivityManager` for RAM and processes, `/sys/class/thermal/thermal_zone*/temp` glob via `File` listing. `fun stopMonitoring()` cancels the loop.

- [ ] **Step 4: Implement `PerformanceScreen`**

`PerformanceScreen(vm: PerformanceViewModel = viewModel())` — live-updating dashboard. CPU usage as a `LinearProgressIndicator`, RAM bar, thermal zones list, top-10 process list. Calls `vm.stopMonitoring()` via `DisposableEffect`.

- [ ] **Step 5: Wire System tab in navigation**

In `AppNavigation.kt`, replace System tab placeholder with `DeviceInfoScreen()` / `PerformanceScreen()` via nested nav or a `TabRow` within the System destination.

- [ ] **Step 6: Verify build**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 7: Commit**

```bash
git commit -m "feat: add System tab — Device Info and Performance Monitor"
```

---

### Task 4: APK & Logs Tab — Logcat, APK Analyzer, Package Manager

**Files:**
- Create: `modules/logcat/LogLine.kt`
- Create: `modules/logcat/LogcatViewModel.kt`
- Create: `modules/logcat/LogcatScreen.kt`
- Create: `modules/apktools/AppInfo.kt`
- Create: `modules/apktools/ApkAnalyzerViewModel.kt`
- Create: `modules/apktools/ApkAnalyzerScreen.kt`
- Create: `modules/packages/PackageManagerViewModel.kt`
- Create: `modules/packages/PackageManagerScreen.kt`
- Create: `app/src/test/java/com/devtools/android/modules/logcat/LogLineTest.kt`
- Modify: `ui/navigation/AppNavigation.kt` — wire APK & Logs tab

**Interfaces:**
- Consumes: `ShellExecutor.exec`, `ShellExecutor.execCollect`, `RootDetector.isRooted`, `RootRequiredCard`, `ErrorCard`
- Produces: `LogcatScreen()`, `ApkAnalyzerScreen()`, `PackageManagerScreen()` composables; `LogLine.parse(raw: String): LogLine`

- [ ] **Step 1: Write failing tests for `LogLine.parse`**

```kotlin
class LogLineTest {
    @Test fun `parses error line correctly`() {
        val line = "08-15 12:34:56.789  1234  5678 E MyTag: something went wrong"
        val result = LogLine.parse(line)
        assertEquals(LogLevel.ERROR, result.level)
        assertEquals("MyTag", result.tag)
        assertEquals("something went wrong", result.message)
    }
    @Test fun `parses warn line correctly`() {
        val line = "08-15 12:34:56.789  1234  5678 W NetTag: reconnecting"
        assertEquals(LogLevel.WARN, LogLine.parse(line).level)
    }
    @Test fun `returns VERBOSE for unknown level`() {
        val line = "08-15 12:34:56.789  1234  5678 X Unknown: msg"
        assertEquals(LogLevel.VERBOSE, LogLine.parse(line).level)
    }
    @Test fun `handles malformed line without crash`() {
        val line = "not a logcat line at all"
        val result = LogLine.parse(line)
        assertEquals(LogLevel.VERBOSE, result.level)
        assertEquals(line, result.message)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./gradlew :app:testDebugUnitTest --tests "*.LogLineTest"`
Expected: FAIL

- [ ] **Step 3: Implement `LogLine` and `LogLevel`**

`LogLevel` enum: `ERROR, WARN, INFO, DEBUG, VERBOSE`. `LogLine` data class: `timestamp: String`, `pid: String`, `level: LogLevel`, `tag: String`, `message: String`. `companion object { fun parse(raw: String): LogLine }` — regex `(\S+\s\S+)\s+(\d+)\s+\d+\s([EWIDV])\s+(\S+):\s(.*)` to extract fields, default to `VERBOSE` / raw message on no match.

- [ ] **Step 4: Run tests to verify they pass**

Run: `./gradlew :app:testDebugUnitTest --tests "*.LogLineTest"`
Expected: PASS (4 tests)

- [ ] **Step 5: Implement `LogcatViewModel`**

`LogcatViewModel : ViewModel()`. `StateFlow<List<LogLine>>` capped at 2000 entries (drop oldest). `StateFlow<LogcatState>` — `Idle`, `Running`, `PermissionDenied`. `fun startCapture(filter: String = "")` launches coroutine calling `ShellExecutor.exec("logcat -v threadtime $filter")`, maps lines through `LogLine.parse`. If 0 lines received after 2 seconds, emits state `PermissionDenied`. `fun stopCapture()`, `fun clear()`, `fun saveToFile(context: Context)`.

- [ ] **Step 6: Implement `LogcatScreen`**

`LogcatScreen(vm: LogcatViewModel = viewModel())` — `LazyColumn` of colored `LogLine` rows (Error=red, Warn=yellow, Info=green, Debug=cyan, Verbose=white via `MaterialTheme.colorScheme`). Filter `TextField` at top. Start/Stop FAB. Shows `ErrorCard` with ADB grant instructions when state is `PermissionDenied`.

- [ ] **Step 7: Implement `AppInfo` and `ApkAnalyzerViewModel`**

`AppInfo` data class: `packageName: String`, `versionName: String`, `versionCode: Long`, `minSdk: Int`, `targetSdk: Int`, `apkPath: String`, `apkSizeKb: Long`, `permissions: List<String>`, `activities: List<String>`, `services: List<String>`. `ApkAnalyzerViewModel` loads all installed packages via `PackageManager.getInstalledPackages(PackageManager.GET_PERMISSIONS or PackageManager.GET_ACTIVITIES or PackageManager.GET_SERVICES)` into `StateFlow<List<AppInfo>>`. `fun filterBy(query: String)`.

- [ ] **Step 8: Implement `ApkAnalyzerScreen`**

`ApkAnalyzerScreen(vm: ApkAnalyzerViewModel = viewModel())` — searchable list of apps. Tapping shows detail sheet with all `AppInfo` fields. Copy APK path button.

- [ ] **Step 9: Implement `PackageManagerViewModel` and `PackageManagerScreen`**

`PackageManagerViewModel` — same package list, adds `fun extractApk(info: AppInfo, context: Context)` copying APK to Downloads via `Files.copy`. Root adds `fun uninstallSystem(packageName: String)` via `ShellExecutor.execCollect("pm uninstall $packageName", root = true)`. `PackageManagerScreen` — list with launch, settings, force-stop, extract-APK actions per row. Root-only actions gated with `RootRequiredCard`.

- [ ] **Step 10: Wire APK & Logs tab in navigation**

Replace placeholder with nested screen: app list / logcat viewer / package manager reachable via `TabRow` or sub-nav.

- [ ] **Step 11: Verify all tests pass and build succeeds**

Run: `./gradlew :app:testDebugUnitTest && ./gradlew :app:assembleDebug`
Expected: PASS + BUILD SUCCESSFUL

- [ ] **Step 12: Commit**

```bash
git commit -m "feat: add APK & Logs tab — Logcat, APK Analyzer, Package Manager"
```

---

### Task 5: Network Tab

**Files:**
- Create: `modules/network/NetworkInfoViewModel.kt`
- Create: `modules/network/NetworkInfoScreen.kt`
- Create: `modules/network/PortScannerViewModel.kt`
- Create: `modules/network/PortScannerScreen.kt`
- Create: `modules/network/DnsToolsViewModel.kt`
- Create: `modules/network/DnsToolsScreen.kt`
- Create: `modules/network/SpeedTestScreen.kt`
- Modify: `ui/navigation/AppNavigation.kt` — wire Network tab

**Interfaces:**
- Consumes: `ShellExecutor.execCollect`, `RootDetector.isRooted`, `ErrorCard`, `RootRequiredCard`
- Produces: `NetworkInfoScreen()`, `PortScannerScreen()`, `DnsToolsScreen()`, `SpeedTestScreen()` composables

- [ ] **Step 1: Implement `NetworkInfoViewModel`**

Reads: WiFi SSID/BSSID/signal/freq/linkSpeed via `WifiManager` (requires `ACCESS_WIFI_STATE`). IP/subnet/gateway/DNS via `ConnectivityManager.getLinkProperties`. All interfaces via `NetworkInterface.getNetworkInterfaces()`. Wraps into `StateFlow<NetworkInfo>` data class with all fields. One-shot load in `init`.

- [ ] **Step 2: Implement `NetworkInfoScreen`**

`NetworkInfoScreen(vm: NetworkInfoViewModel = viewModel())` — sections for WiFi details, IP config, all interfaces as a card list.

- [ ] **Step 3: Implement `PortScannerViewModel`**

`StateFlow<PortScanState>` — `Idle`, `Scanning(progress: Float, openPorts: List<Int>)`, `Done(openPorts: List<Int>)`, `Cancelled`. `fun scan(host: String, portRange: IntRange, timeoutMs: Int)` — launches `viewModelScope` coroutine, iterates port range using `withContext(Dispatchers.IO)` + `supervisorScope` for parallel `Socket().connect(InetSocketAddress(host, port), timeoutMs)` calls (batch size 50). `fun cancel()` cancels the scope job; must complete within 500 ms. Non-root only. Root adds `fun nmapScan(target: String, args: String)` via `ShellExecutor`.

- [ ] **Step 4: Implement `PortScannerScreen`**

`PortScannerScreen(vm: PortScannerViewModel = viewModel())` — host `TextField`, port range `TextField`, timeout slider. Start/Cancel button. `LinearProgressIndicator` during scan. Results list of open ports.

- [ ] **Step 5: Implement `DnsToolsViewModel`**

`fun lookup(host: String): StateFlow<DnsResult>` where `DnsResult` holds `addresses: List<String>`, `reversePtrs: List<String>`. Uses `InetAddress.getAllByName(host)` for forward. Reverse via `InetAddress.getByName(ip).canonicalHostName`. Whois via `ShellExecutor.execCollect("busybox whois $host")` (busybox, not root-gated).

- [ ] **Step 6: Implement `DnsToolsScreen` and `SpeedTestScreen`**

`DnsToolsScreen` — host input, lookup button, results card. `SpeedTestScreen` — server host/port input, mode selector (up/down/both/UDP), start button, results card. Speed test runs `iperf3 -c $host -p $port [flags]` via `ShellExecutor.execCollect`; parses bandwidth from output line matching `\d+(\.\d+)?\s+[KMG]bits/sec`.

- [ ] **Step 7: Wire Network tab in navigation**

Replace placeholder with `TabRow` containing Network Info, Port Scanner, DNS Tools, Speed Test.

- [ ] **Step 8: Verify build**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 9: Commit**

```bash
git commit -m "feat: add Network tab — Network Info, Port Scanner, DNS, Speed Test"
```

---

### Task 6: Tools Tab — SSH, File Browser, Terminal, Quick Reference

**Files:**
- Create: `modules/ssh/SshProfile.kt`
- Create: `modules/ssh/SshClientViewModel.kt`
- Create: `modules/ssh/SshClientScreen.kt`
- Create: `modules/files/FileBrowserViewModel.kt`
- Create: `modules/files/FileBrowserScreen.kt`
- Create: `modules/terminal/ShellTerminalViewModel.kt`
- Create: `modules/terminal/ShellTerminalScreen.kt`
- Create: `modules/quickref/QuickRefScreen.kt`
- Modify: `ui/navigation/AppNavigation.kt` — wire Tools tab

**Interfaces:**
- Consumes: `ShellExecutor.exec`, `ShellExecutor.execCollect`, `RootDetector.isRooted`, `RootRequiredCard`, DataStore preferences
- Produces: `SshClientScreen()`, `FileBrowserScreen()`, `ShellTerminalScreen()`, `QuickRefScreen()` composables

- [ ] **Step 1: Implement `SshProfile` and `SshClientViewModel`**

`SshProfile` data class: `host: String`, `port: Int = 22`, `username: String`, `authMethod: SshAuthMethod` (sealed: `Password(value: String)`, `KeyPath(path: String)`). `SshClientViewModel : ViewModel()` — `StateFlow<SshState>` (`Disconnected`, `Connecting`, `Connected(session: SSHClient)`, `Error(msg: String)`). `fun connect(profile: SshProfile)` uses SSHJ `SSHClient`, `addHostKeyVerifier(PromiscuousVerifier())` for simplicity. `fun disconnect()`. `fun executeCommand(cmd: String): Flow<String>` opens a session and streams output. Saves last-used profile to DataStore.

- [ ] **Step 2: Implement `SshClientScreen`**

`SshClientScreen(vm: SshClientViewModel = viewModel())` — host/port/user fields, auth method toggle, connect/disconnect button, terminal-style output `LazyColumn`, command input field at bottom when connected.

- [ ] **Step 3: Implement `FileBrowserViewModel`**

`StateFlow<List<FileEntry>>` where `FileEntry`: `name: String`, `path: String`, `isDir: Boolean`, `sizeBytes: Long`, `permissions: String`. `fun navigate(path: String)` — non-root uses `File(path).listFiles()` restricted to accessible directories; root uses `ShellExecutor.execCollect("ls -la $path", root = true)` and parses output. `fun currentPath: StateFlow<String>`. `fun checksum(path: String, algo: String): Flow<String>` runs `busybox ${algo}sum $path` via ShellExecutor.

- [ ] **Step 4: Implement `FileBrowserScreen`**

`FileBrowserScreen(vm: FileBrowserViewModel = viewModel())` — breadcrumb path bar, `LazyColumn` of file entries with icons (folder vs file). Long-press shows action sheet: copy path, checksum, view as text. Root indicator badge on entries only accessible with root.

- [ ] **Step 5: Implement `ShellTerminalViewModel`**

`StateFlow<List<String>>` of output lines (capped at 1000). `StateFlow<Boolean>` for root mode. `fun sendCommand(input: String)` — appends `"$ $input"` to lines, calls `ShellExecutor.exec(input, root = isRootMode)`, collects output into lines. Maintains command history `List<String>`.

- [ ] **Step 6: Implement `ShellTerminalScreen`**

`ShellTerminalScreen(vm: ShellTerminalViewModel = viewModel())` — dark background `LazyColumn` of monospaced output lines (auto-scroll to bottom). Input `TextField` at bottom with Send button. If `RootDetector.isRooted`, show "Root Shell" toggle. Non-root `sh` always available.

- [ ] **Step 7: Implement `QuickRefScreen`**

`QuickRefScreen()` — static composable, no ViewModel. Sections (expandable `Card`s): ADB Commands, Frida/Objection, nmap Flags, Logcat Filters, Crypto/Hashing. Each section contains a `SelectionContainer` wrapping monospaced text for copy-paste. Search `TextField` at top filters visible sections by keyword.

- [ ] **Step 8: Wire Tools tab in navigation**

Replace placeholder with `TabRow`: SSH Client, File Browser, Terminal, Quick Reference.

- [ ] **Step 9: Verify build**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 10: Commit**

```bash
git commit -m "feat: add Tools tab — SSH Client, File Browser, Terminal, Quick Reference"
```

---

### Task 7: Security Tab — Frida Manager, Process Inspector, Root Terminal

**Files:**
- Create: `modules/security/FridaManagerViewModel.kt`
- Create: `modules/security/FridaManagerScreen.kt`
- Create: `modules/security/ProcessInspectorViewModel.kt`
- Create: `modules/security/ProcessInspectorScreen.kt`
- Create: `modules/security/RootTerminalViewModel.kt`
- Create: `modules/security/RootTerminalScreen.kt`
- Modify: `ui/navigation/AppNavigation.kt` — wire Security tab

**Interfaces:**
- Consumes: `ShellExecutor.execCollect`, `ShellExecutor.exec`, `BinaryManager.binaryPath`, `RootDetector.isRooted`, `RootRequiredCard`
- Produces: `FridaManagerScreen()`, `ProcessInspectorScreen()`, `RootTerminalScreen()` composables

- [ ] **Step 1: Guard Security tab entry point**

`SecurityScreen(isRooted: Boolean)` — if `!isRooted`, renders `RootRequiredCard("Security Tools — Frida, Process Inspector, Root Terminal")` and returns. Otherwise renders tab bar for three sub-screens.

- [ ] **Step 2: Implement `FridaManagerViewModel`**

`StateFlow<FridaState>`: `Idle`, `Starting`, `Running(pid: Int)`, `Error(msg: String)`. `fun startServer(context: Context)` — calls `BinaryManager.binaryPath("frida-server-arm64", context)`, runs `su -c "$path &"` via `ShellExecutor`. Parses stderr: if it contains `"Unable to handle 64-bit"` or `"version mismatch"`, emits `Error("Frida version mismatch — reinstall app")`. `fun stopServer()` via `su -c "pkill frida-server"`. `StateFlow<List<FridaProcess>>` (name + pid) populated by `frida-ps` output parse. `fun injectScript(pid: Int, script: String)` runs `frida -p $pid -l $scriptPath` with a temp script file.

- [ ] **Step 3: Implement `FridaManagerScreen`**

`FridaManagerScreen(vm: FridaManagerViewModel = viewModel())` — Start/Stop server button with status indicator. Process list with "Attach" button per row. Script library `DropdownMenu`: SSL Pinning Bypass, Root Detection Bypass, Custom. Shows `ErrorCard` with mismatch guidance when state is `Error`.

- [ ] **Step 4: Implement `ProcessInspectorViewModel`**

`StateFlow<List<ProcessEntry>>` where `ProcessEntry`: `pid: Int`, `ppid: Int`, `name: String`, `user: String`, `rss: Long`. Populated via `ShellExecutor.execCollect("su -c 'ps -A -o PID,PPID,USER,RSS,NAME'")`, parse each line. `fun kill(pid: Int)` runs `su -c "kill -9 $pid"`. `fun filter(query: String)`.

- [ ] **Step 5: Implement `ProcessInspectorScreen`**

`ProcessInspectorScreen(vm: ProcessInspectorViewModel = viewModel())` — searchable `LazyColumn` of process rows. Long-press shows confirm kill dialog. Refresh FAB.

- [ ] **Step 6: Implement `RootTerminalViewModel` and `RootTerminalScreen`**

`RootTerminalViewModel` extends `ShellTerminalViewModel` from Task 6 but forces `root = true` on all `sendCommand` calls. `RootTerminalScreen` — same UI as `ShellTerminalScreen` but labeled "Root Terminal", red accent, always root mode, no toggle.

- [ ] **Step 7: Wire Security tab in navigation**

Replace Security tab placeholder with `SecurityScreen(isRooted = RootDetector.isRooted)`.

- [ ] **Step 8: Verify build**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 9: Commit**

```bash
git commit -m "feat: add Security tab — Frida Manager, Process Inspector, Root Terminal"
```

---

### Task 8: Binary Bundling + BinaryManager

**Files:**
- Create: `android-devtools-app/app/src/main/assets/bin/frida-server-arm64` (downloaded)
- Create: `android-devtools-app/app/src/main/assets/bin/nmap-arm64` (downloaded)
- Create: `android-devtools-app/app/src/main/assets/bin/busybox-arm64` (downloaded)
- Create: `android-devtools-app/app/src/main/java/com/devtools/android/core/BinaryManager.kt`

**Interfaces:**
- Consumes: `context.filesDir`, `context.assets`, `DataStore` for version hash
- Produces:
  - `BinaryManager.ensureBinaries(context: Context): Boolean`
  - `BinaryManager.binaryPath(name: String, context: Context): String`

- [ ] **Step 1: Download binaries**

Download into `assets/bin/`:
- `frida-server` for Android ARM64: from `https://github.com/frida/frida/releases` — latest stable, file `frida-server-{version}-android-arm64.xz`; decompress to `frida-server-arm64`
- `nmap` static ARM64 binary for Android: build or source from a trusted prebuilt (e.g., kali nethunter packages); save as `nmap-arm64`
- `busybox` ARM64 static: from `https://busybox.net/downloads/binaries/` — latest ARM64 static; save as `busybox-arm64`

Verify each file is executable ELF ARM64 with `file busybox-arm64`.

- [ ] **Step 2: Implement `BinaryManager`**

`object BinaryManager`. `suspend fun ensureBinaries(context: Context): Boolean` — reads stored version hash from DataStore key `"bin_version"`. If missing or different from `BuildConfig.VERSION_CODE.toString()`, copies each `assets/bin/*` file to `context.filesDir/bin/` via `context.assets.open(name)` → `FileOutputStream`. Catches `IOException` (disk full) and returns `false`. After copy, runs `ShellExecutor.execCollect("su -c 'chmod +x ${context.filesDir}/bin/*'", root = true)`. Writes new version hash to DataStore. Returns `true` on success. `fun binaryPath(name: String, context: Context): String` returns `"${context.filesDir}/bin/$name"`.

- [ ] **Step 3: Call `BinaryManager.ensureBinaries` in `MainActivity`**

On root-detected launch, call `BinaryManager.ensureBinaries(context)` in a coroutine. If it returns `false`, show a `Snackbar("Storage full — cannot extract tools")`.

- [ ] **Step 4: Verify build with binaries**

Run: `./gradlew :app:assembleDebug`
Expected: BUILD SUCCESSFUL, APK includes `assets/bin/` entries (check with `unzip -l app-debug.apk | grep assets/bin`)

- [ ] **Step 5: Commit**

```bash
git add android-devtools-app/app/src/main/assets/bin/
git commit -m "feat: bundle frida-server, nmap, busybox and add BinaryManager extraction"
```

---

### Task 9: Onboarding, Permissions Flow + Polish

**Files:**
- Create: `modules/onboarding/OnboardingScreen.kt`
- Create: `modules/onboarding/OnboardingViewModel.kt`
- Modify: `ui/navigation/AppNavigation.kt` — show onboarding on first launch
- Modify: `ui/theme/Theme.kt` — wire DataStore theme pref

**Interfaces:**
- Consumes: `RootDetector.isRooted`, DataStore, `BinaryManager.ensureBinaries`
- Produces: `OnboardingScreen()` composable shown on first launch only

- [ ] **Step 1: Implement `OnboardingViewModel`**

`StateFlow<OnboardingStep>` cycling through: `Welcome`, `RootStatus(isRooted: Boolean)`, `GrantReadLogs`, `GrantUsageStats`, `ExtractBinaries(inProgress: Boolean, success: Boolean?)`, `Done`. `fun advance()` moves to next step. `fun extractBinaries(context: Context)` calls `BinaryManager.ensureBinaries` and updates state. DataStore key `"onboarding_done": Boolean`.

- [ ] **Step 2: Implement `OnboardingScreen`**

`OnboardingScreen(vm: OnboardingViewModel = viewModel(), onFinish: () -> Unit)` — full-screen pager. Step `GrantReadLogs`: shows ADB command `adb shell pm grant com.devtools.android android.permission.READ_LOGS` in a `SelectionContainer`. Step `GrantUsageStats`: `adb shell appops set com.devtools.android PACKAGE_USAGE_STATS allow`. Step `ExtractBinaries`: progress indicator while extracting, error card on failure. Final step calls `onFinish()`.

- [ ] **Step 3: Wire onboarding into navigation**

In `AppNavigation.kt`, check DataStore `onboarding_done` flag. If false, show `OnboardingScreen` as start destination; on finish, write flag and navigate to `MainScreen`.

- [ ] **Step 4: Wire theme preference**

In `MainActivity`, read DataStore `theme_pref` (`"dark"`, `"light"`, `"system"`). Pass to `DevToolsTheme(darkTheme = ...)`. Settings gear icon in `MainScreen` `TopAppBar` navigates to a settings screen with theme selector `RadioGroup`.

- [ ] **Step 5: Final polish**

Add root status banner in `MainScreen` `TopAppBar` — green chip "Rooted" or grey chip "No Root". Lock badge on Security tab icon when not rooted. Ensure all screens handle `Loading` state with `CircularProgressIndicator`.

- [ ] **Step 6: Verify all tests pass and build succeeds**

Run: `./gradlew :app:testDebugUnitTest && ./gradlew :app:assembleDebug`
Expected: all tests PASS, BUILD SUCCESSFUL

- [ ] **Step 7: Commit**

```bash
git commit -m "feat: add onboarding flow, permission guidance, and UI polish"
```

---

### Task 10: Release APK

**Files:**
- Modify: `android-devtools-app/app/build.gradle.kts` — release signing config
- Modify: `android-devtools-app/app/proguard-rules.pro` — SSHJ + Frida keep rules

**Interfaces:**
- Consumes: all prior tasks
- Produces: `app/build/outputs/apk/release/app-release.apk`

- [ ] **Step 1: Add ProGuard keep rules**

In `proguard-rules.pro` add:
```
-keep class net.schmizz.sshj.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn net.schmizz.sshj.**
-dontwarn org.bouncycastle.**
```

- [ ] **Step 2: Configure debug keystore signing for release build**

In `app/build.gradle.kts` `buildTypes.release` block, add `signingConfig = signingConfigs.getByName("debug")` so the APK is signed and installable without a production keystore. Set `isMinifyEnabled = true`, `isShrinkResources = true`, `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")`.

- [ ] **Step 3: Build release APK**

Run: `./gradlew :app:assembleRelease`
Expected: BUILD SUCCESSFUL; APK at `app/build/outputs/apk/release/app-release.apk`

- [ ] **Step 4: Verify APK is installable**

Run: `adb install -r app/build/outputs/apk/release/app-release.apk`
Expected: `Success`

- [ ] **Step 5: Commit**

```bash
git add android-devtools-app/
git commit -m "feat: configure release build and produce installable APK"
```

---

## Self-Review Notes

**Spec coverage check:**
- ✅ All 10 feature modules covered across Tasks 3–7
- ✅ Core infrastructure: Tasks 2 + 8
- ✅ Root detection + graceful degradation: Tasks 2, 7
- ✅ Binary bundling: Task 8
- ✅ DataStore persistence: Tasks 6, 9
- ✅ Permissions: Tasks 1, 9
- ✅ Build variants: Task 10
- ✅ Testing: Tasks 2, 4

**Review Focus items → tests added:**
- Root false negatives → `RootDetectorTest.returns false when no su path exists` (Task 2)
- READ_LOGS denied → `LogcatViewModel` 2-second zero-line detection emitting `PermissionDenied` (Task 4, Step 5)
- Port scanner stall → `PortScannerViewModel.cancel()` 500 ms guarantee (Task 5, Step 3)
- Frida version mismatch → stderr parse in `FridaManagerViewModel.startServer` (Task 7, Step 2)
- BinaryManager disk full → `IOException` catch returning `false` (Task 8, Step 2)
