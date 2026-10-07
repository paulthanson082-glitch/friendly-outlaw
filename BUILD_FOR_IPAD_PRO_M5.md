# Build and Setup — iPad Pro M5

**Project**: friendly-outlaw (WritersApp)
**Target**: iPadOS 17+ on iPad Pro M4, iPadOS 18+ on iPad Pro M5
**Last Updated**: March 27, 2026

---

## Supported iPad Pro Hardware

| Model | Chip | iPadOS Min | Status |
|-------|------|-----------|--------|
| iPad Pro 13-inch (M5, 2026) | Apple M5 | iPadOS 18 | ✅ Supported |
| iPad Pro 11-inch (M5, 2026) | Apple M5 | iPadOS 18 | ✅ Supported |
| iPad Pro 13-inch (M4, 2024) | Apple M4 | iPadOS 17 | ✅ Supported |
| iPad Pro 11-inch (M4, 2024) | Apple M4 | iPadOS 17 | ✅ Supported |

> **Note:** The app requires iPadOS 16 minimum and is fully optimised for ProMotion (120 Hz), Apple Pencil Pro, Stage Manager, and the M-series Neural Engine.

---

## Prerequisites

### On Your Mac (Build Machine)

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 14 Sonoma+ | Required for Xcode 16+ |
| Xcode | 16+ | Download from Mac App Store |
| Swift | 5.9+ | Bundled with Xcode 16 |
| Apple Developer account | Free or Paid | Paid ($99/yr) required for device deployment |

### Verify Build Machine

```bash
# Check macOS
sw_vers

# Check Xcode
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check Swift
swift --version
# Should report Swift 5.9 or later

# Verify Xcode Command Line Tools
xcode-select --version
```

### On Your iPad Pro M5

- iPadOS 18.0 or later
- Developer Mode enabled (Settings → Privacy & Security → Developer Mode)
- Connected to Mac via USB-C Thunderbolt 4 cable (for direct deployment)

---

## Enable Developer Mode on iPad Pro

1. Open **Settings** on iPad Pro
2. Go to **Privacy & Security**
3. Scroll down to **Developer Mode** and toggle it **on**
4. Tap **Restart** when prompted
5. After restart, tap **Turn On** to confirm

---

## Build for iPad Pro Using Xcode

### 1. Open the Project in Xcode

```bash
cd /path/to/friendly-outlaw

# Open the Swift Package in Xcode
open Package.swift
```

Xcode will automatically resolve the SPM dependencies and index the project.

### 2. Select the Target

In Xcode:
1. Select the **WritersApp** scheme from the scheme selector (top toolbar)
2. Set the destination to your iPad Pro M5:
   - Click the device selector next to the scheme name
   - Select your connected iPad from the list
   - Or select **iPad Pro (M4)** simulator for testing without hardware

### 3. Configure Signing

1. In Xcode, select the **WritersApp** package in the project navigator
2. Go to **Signing & Capabilities**
3. Set **Team** to your Apple Developer account
4. Xcode will automatically manage provisioning profiles

### 4. Build and Run

Click **▶ Run** (or `⌘R`) to build and deploy to your iPad Pro M5.

**Expected first-build time on M2 Mac:**
- iPad Simulator: ~30–60 seconds
- Physical iPad (arm64): ~45–90 seconds

---

## Build via Command Line (Simulator)

For CI or command-line workflows, build and test on an iPad simulator:

```bash
# List available iPad simulators
xcrun simctl list devices | grep iPad

# Build for iOS (arm64-simulator)
xcodebuild \
  -scheme WritersApp \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  build

# Run tests on simulator
xcodebuild \
  -scheme WritersAppTests \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' \
  test
```

---

## iPad Pro M5 — Specific Features

The WritersApp includes first-class support for iPad Pro M5 hardware features:

### ProMotion Display (120 Hz)

The Metal Dashboard view uses the ProMotion 120 Hz refresh rate for silky-smooth animations:

```swift
// Enabled automatically in MetalDashboardView.swift
// No manual configuration required
```

Enable ProMotion in `iPadProModels.swift`:
```swift
iPadProConfiguration(
    proMotionEnabled: true   // default: true
)
```

### Apple Pencil Pro

Full Apple Pencil Pro support including:
- **Pressure sensitivity** — variable line weight in annotations
- **Tilt detection** — shading and brush angle control
- **Hover detection** — cursor preview before touch (iPadOS 16.1+)
- **Squeeze gesture** — quick tool switching

Managed by `ApplePencilManager.swift`:
```swift
let pencilManager = ApplePencilManager()
pencilManager.onPencilInput = { stroke in
    // Handle stroke input
}
```

### Stage Manager

Full Stage Manager support for overlapping, resizable windows:
- Multiple documents open simultaneously
- Drag-and-drop between windows
- External display support (USB-C to HDMI/DisplayPort)

Managed by `StageManagerSupport.swift`:
```swift
let stageManager = StageManagerSupport()
stageManager.enableMultiWindowSupport()
```

### Keyboard Shortcuts

Hardware keyboard support via `KeyboardShortcutManager.swift`:

| Shortcut | Action |
|----------|--------|
| `⌘N` | New document |
| `⌘O` | Open document |
| `⌘S` | Save |
| `⌘⇧E` | Export |
| `⌘⇧A` | AI assistance |
| `⌘⌥K` | Kanban board |

### Metal GPU Dashboard

The Metal dashboard uses the M5's GPU for real-time writing analytics visualisation. Available in `MetalDashboardView.swift`:
- Word count charts with GPU-accelerated rendering
- Real-time session progress
- ProMotion-optimised animation loop

---

## Project Structure (iOS-relevant files)

```
Sources/WritersApp/
├── Models/
│   └── iPadProModels.swift        # iPad Pro configuration models
├── Views/
│   ├── iPadProViews.swift         # Main iPad Pro SwiftUI views
│   ├── MetalDashboardView.swift   # GPU-accelerated dashboard
│   ├── MetalDashboardViewModel.swift
│   └── MetalTheme.swift           # Metal rendering theme
├── Services/
│   ├── ApplePencilManager.swift   # Apple Pencil Pro integration
│   ├── KeyboardShortcutManager.swift # Hardware keyboard support
│   ├── MultitaskingManager.swift  # iPadOS multitasking
│   └── StageManagerSupport.swift  # Stage Manager windows
└── Previews/
    └── MetalDashboardPreview.swift
```

---

## SwiftUI Previews on iPad

Run live previews in Xcode Canvas:

1. Open `Sources/WritersApp/Views/iPadProViews.swift`
2. Click **▶** in the Canvas panel or press `⌘⌥↩`
3. Select **iPad Pro 13-inch (M4)** as the preview device
4. Previews update live as you edit

---

## TestFlight Distribution

To distribute to testers via TestFlight:

### 1. Archive the App

```bash
xcodebuild \
  -scheme WritersApp \
  -destination 'generic/platform=iOS' \
  -archivePath build/WritersApp.xcarchive \
  archive
```

### 2. Export for App Store Connect

```bash
xcodebuild \
  -exportArchive \
  -archivePath build/WritersApp.xcarchive \
  -exportPath build/WritersApp.ipa \
  -exportOptionsPlist ExportOptions.plist
```

### 3. Upload to App Store Connect

```bash
xcrun altool \
  --upload-app \
  --type ios \
  --file build/WritersApp.ipa \
  --username your@apple.id \
  --password @keychain:APP_STORE_PASSWORD
```

Or use **Xcode Organizer** (Window → Organizer) for a GUI workflow.

---

## Simulator Testing Matrix

Test on these simulator targets before deploying to physical hardware:

| Simulator | Resolution | Purpose |
|-----------|-----------|---------|
| iPad Pro 13-inch (M4) | 2064×2752 | Full size layout testing |
| iPad Pro 11-inch (M4) | 1668×2388 | Compact layout testing |
| iPad Air 13-inch (M2) | 2064×2752 | Mid-tier device testing |
| iPad mini (6th gen) | 1488×2266 | Small-screen compatibility |

```bash
# Create and boot an iPad Pro simulator
xcrun simctl create "iPad Pro M4" "iPad Pro 13-inch (M4)" "com.apple.CoreSimulator.SimRuntime.iOS-18-0"
xcrun simctl boot "iPad Pro M4"
open -a Simulator
```

---

## Performance on M5

The M5 chip provides exceptional performance for this app:

| Feature | M5 Capability |
|---------|--------------|
| Neural Engine | 38 TOPS — accelerates on-device AI text processing |
| GPU | 10-core GPU — powers Metal Dashboard at 120 fps |
| Memory bandwidth | 120 GB/s — fast SQLite reads/writes |
| ProMotion | 1–120 Hz adaptive — smooth document scrolling |
| Thunderbolt 4 | External display, USB-C peripherals |

### Recommended Build Settings for M5

For best performance on M5, use the release build configuration:

```bash
# Release build optimised for Apple Silicon
swift build -c release
```

In Xcode, set **Optimization Level** to **Optimize for Speed [-O]** under:
`Build Settings → Swift Compiler — Code Generation → Optimization Level`

---

## Troubleshooting

### "Could not find module 'WritersApp'"

Ensure the package is correctly linked:
1. In Xcode, go to **File → Packages → Reset Package Caches**
2. Clean build folder: `⌘⇧K`
3. Rebuild: `⌘B`

### Device Not Trusted

On iPad Pro when prompted:
1. Tap **Trust** on the iPad
2. On Mac, confirm in Xcode
3. Enter iPad passcode if prompted

### iPadOS Version Too Low

Ensure iPad Pro is running iPadOS 18+:
- **Settings → General → Software Update**

### Metal Dashboard Not Rendering

If the Metal Dashboard shows a blank screen:
1. Confirm Metal is supported: all M-series iPads support Metal
2. Check that the simulator has GPU enabled (physical device preferred for Metal)
3. Run on physical iPad Pro rather than simulator for Metal features

### Xcode Simulator Slow

For faster simulation on Apple Silicon Mac:
```bash
# Use the arm64 simulator (native, not Rosetta)
xcodebuild \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),arch=arm64' \
  build
```

---

## Next Steps After Build

1. **Run tests**: `swift test` (should pass 600+ tests)
2. **Try iOS Simulator**: Open in Xcode and run on iPad Pro simulator
3. **Deploy to device**: Connect iPad Pro M5 via USB-C and run from Xcode
4. **Explore iPad features**: Test Stage Manager, Apple Pencil Pro, keyboard shortcuts
5. **Check AI features**: Set `ANTHROPIC_API_KEY` for Claude-powered writing assistance

---

## Documentation Reference

- **[BUILD_FOR_MAC_PRO.md](BUILD_FOR_MAC_PRO.md)** — Mac Pro build instructions
- **[CLAUDE.md](CLAUDE.md)** — AI assistant guide (architecture, APIs, patterns)
- **[README.md](README.md)** — Main project documentation
- **[SETUP_AND_RUN.md](SETUP_AND_RUN.md)** — General setup guide
