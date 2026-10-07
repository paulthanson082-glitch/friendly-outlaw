# Build and Setup — MacBook Pro & iPad Pro M5

**Project**: friendly-outlaw (WritersApp + AIMS platform)
**Targets**: macOS (MacBook Pro), iPadOS (iPad Pro M5)
**Last Updated**: March 27, 2026

---

## MacBook Pro Setup

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 14+ (Sonoma or later) | Required for full feature support |
| Xcode | 15.3+ | Install from App Store or developer.apple.com |
| Swift | 5.9+ | Bundled with Xcode |
| SQLite3 | any | Pre-installed on macOS |
| Git | any | Pre-installed on macOS |

### Verify Prerequisites

```bash
# Check Swift version (should be 5.9+)
swift --version

# Check Xcode installation
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer

# Check SQLite3 (pre-installed on macOS)
sqlite3 --version

# Verify git
git --version
```

If Xcode Command Line Tools are not installed:
```bash
xcode-select --install
```

If you need to install SQLite3 headers separately:
```bash
brew install sqlite3
```

---

### Quick Build (MacBook Pro)

```bash
# Clone and enter the project
git clone https://github.com/paulthanson082-glitch/friendly-outlaw.git
cd friendly-outlaw

# Debug build
swift build

# Optimized release build (recommended for daily use)
swift build -c release
```

**Expected build times on MacBook Pro (Apple Silicon):**

| Build type | First build | Incremental |
|-----------|------------|-------------|
| Debug | ~30–60 seconds | ~5–15 seconds |
| Release | ~60–90 seconds | ~10–20 seconds |

---

### Run the CLI (MacBook Pro)

```bash
# Option 1: Convenience script
./run.sh

# Option 2: Direct Swift execution
swift run WritersAppCLI

# Option 3: Pre-built release binary
.build/release/WritersAppCLI

# Option 4: With AI features enabled
export ANTHROPIC_API_KEY="sk-ant-..."
./run.sh
```

---

### Open in Xcode (MacBook Pro)

```bash
open Package.swift
```

This opens the full SPM project in Xcode, with full debugging, breakpoints, and the SwiftUI preview canvas.

---

### Open in VS Code (MacBook Pro)

```bash
code .
```

Pre-configured tasks are available via `Cmd+Shift+B`:
- **Swift: Build** (default)
- **Swift: Build Release**
- **Swift: Test**
- **Swift: Clean**
- **Swift: Run CLI**

---

## iPad Pro M5 Setup

The iPad Pro M5 is fully supported by this project. It ships with the same 11-inch and 13-inch form factors as the M4, with the same OLED Ultra Retina XDR display and Apple Pencil Pro support.

### Supported Models

| Model | Raw value | Screen | PPI | Apple Pencil |
|-------|-----------|--------|-----|--------------|
| `iPadProM5_11` | iPad Pro 11-inch (M5) | 11-inch OLED | 264 | Apple Pencil Pro |
| `iPadProM5_13` | iPad Pro 13-inch (M5) | 13-inch OLED | 264 | Apple Pencil Pro |

### iPad Pro M5 Features Supported

- ✅ ProMotion 120 Hz adaptive refresh
- ✅ Apple Pencil Pro (squeeze, barrel roll, haptic feedback, double-tap)
- ✅ Stage Manager with multi-window support
- ✅ Split View (primary and secondary)
- ✅ Slide Over
- ✅ Hardware keyboard shortcuts
- ✅ Metal GPU-accelerated dashboard

### Run on iPad (via TestFlight / Xcode)

1. Open the project in Xcode on your MacBook Pro: `open Package.swift`
2. Select your iPad Pro M5 as the target device in the device picker
3. Build and run with `Cmd+R`

Alternatively, for Xcode previews of iPad Pro M5 layouts, select **iPad Pro 13-inch (M5)** from the preview device list in the SwiftUI Canvas.

### Programmatic Model Detection

To detect or configure for iPad Pro M5 in code:

```swift
// Select the right model
let model: iPadProModel = .iPadProM5_13   // or .iPadProM5_11

// Read screen dimensions
let screen = model.screenSize
print(screen.widthInches)          // 11.09
print(screen.recommendedEditorWidth)  // 780
print(screen.supportsApplePencil)     // .pro

// Configure the app for M5
var config = iPadProConfiguration()
config.proMotionEnabled = true
config.applePencilEnabled = true
config.stageManagerEnabled = true
```

---

## Test Suite

Run all tests to verify your setup:

```bash
# Standard test run
swift test

# Verbose output
swift test --verbose

# Run only iPad Pro tests
swift test --filter iPadProFeaturesTests
```

M5-specific tests included:
- `testiPadProM5ScreenSizes` — Verifies dimensions, PPI, ProMotion, Face ID, and Apple Pencil Pro support
- `testiPadProM5ModelProperties` — Verifies display names and `CaseIterable` membership
- `testiPadProM5EditorLayout` — Verifies recommended editor width and font size for both M5 models

---

## Troubleshooting

### "module 'CSQLite' not found"

```bash
# Install SQLite3 via Homebrew
brew install sqlite3

# Or install Xcode Command Line Tools
xcode-select --install
```

### "error: unable to load standard library"

- Ensure Swift 5.9+ is installed: `swift --version`
- Update Xcode from the App Store if needed

### Clean Build

If you encounter unexpected build errors:

```bash
swift package clean
swift build
```

### Database Location

- Default: `~/Documents/writersapp.db`
- For tests: in-memory (`:memory:`) — no persistent file needed

---

## Build Artifacts

```
.build/
├── debug/
│   └── WritersAppCLI       # Debug binary (~11 MB)
└── release/
    └── WritersAppCLI       # Release binary (optimized)
```

---

## Key Files

| File | Purpose |
|------|---------|
| `Package.swift` | SPM manifest — platforms, targets, dependencies |
| `Sources/WritersApp/Models/iPadProModels.swift` | iPad Pro model definitions (M4, M5, legacy) |
| `Sources/WritersApp/Services/ApplePencilManager.swift` | Apple Pencil Pro integration |
| `Sources/WritersApp/Services/MultitaskingManager.swift` | Split View / Stage Manager support |
| `Sources/WritersApp/Views/iPadProViews.swift` | iPad Pro SwiftUI views |
| `Sources/WritersApp/Views/MetalDashboardView.swift` | Metal GPU-accelerated dashboard |
| `Tests/WritersAppTests/iPadProFeaturesTests.swift` | iPad Pro feature tests (inc. M5) |
| `run.sh` | Convenience build + run script |

---

## Documentation Reference

- **[CLAUDE.md](CLAUDE.md)** — Full architecture and API guide
- **[README.md](README.md)** — Project overview
- **[SETUP_AND_RUN.md](SETUP_AND_RUN.md)** — General setup guide
- **[BUILD_FOR_MAC_PRO.md](BUILD_FOR_MAC_PRO.md)** — Desktop Mac Pro build notes
