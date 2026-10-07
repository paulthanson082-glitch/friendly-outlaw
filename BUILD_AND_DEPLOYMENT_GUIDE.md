# Build and Deployment Guide

This guide covers building and deploying **friendly-outlaw** to both macOS and iOS (iPad Pro).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Building for macOS](#building-for-macos)
- [Building for iOS](#building-for-ios)
- [Running on macOS](#running-on-macos)
- [Deploying to iPad Pro](#deploying-to-ipad-pro)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### For All Platforms
- **Xcode 15.0+** (includes Swift 5.9+)
- **macOS 14+** (for development)
- **Git** (for version control)

### For iOS/iPad Deployment
- **iOS 16+** runtime
- **iPad Pro** with iOS 16+ or iPad simulator
- **Apple Developer Account** (free account for simulator testing; paid for physical device deployment)
- **Apple Developer Certificate** (for physical device installation)

### System Requirements Check
```bash
# Verify Swift version
swift --version

# Verify Xcode version
xcode-select --print-path

# Ensure Xcode Command Line Tools are installed
xcode-select --install
```

---

## Environment Setup

### 1. Install Dependencies
The project uses Swift Package Manager (SPM) and the following system libraries:

```bash
# Install sqlite3 (if not already installed)
brew install sqlite3

# Verify sqlite3
pkg-config --cflags --libs sqlite3
```

### 2. Configure API Keys (Optional)
For AI features, set the Anthropic API key:

```bash
export ANTHROPIC_API_KEY="sk-ant-your-api-key-here"
```

### 3. Clone and Navigate to Project
```bash
git clone <repository-url>
cd friendly-outlaw

# Check out the development branch
git checkout claude/add-design-feature-docs-I7xXQ
```

### 4. Verify Project Structure
```bash
# Confirm Package.swift exists and is valid
swift package describe

# List available products
swift package dump-package | grep -A 20 '"products"'
```

---

## Building for macOS

### Debug Build
```bash
# Navigate to project root
cd /path/to/friendly-outlaw

# Build in debug mode (faster compilation, larger binary)
swift build

# Output: .build/debug/WritersAppCLI
```

### Release Build (Optimized)
```bash
# Build in release mode (slower compilation, optimized runtime)
swift build -c release

# Output: .build/release/WritersAppCLI
```

### Build Verification
```bash
# Verify build artifacts
ls -lh .build/release/WritersAppCLI

# Check binary
file .build/release/WritersAppCLI

# Expected output: Mach-O 64-bit executable x86_64 (or arm64 for Apple Silicon)
```

---

## Building for iOS

### Option 1: Using Xcode (Recommended)

#### a. Open in Xcode
```bash
# Open project in Xcode
open -a Xcode .
```

#### b. Create iOS App Target (if needed)
1. In Xcode: **File → New → Target**
2. Select **iOS → App**
3. Set **Product Name**: `WritersApp`
4. Select **SwiftUI** for interface
5. Ensure **Deployment Target**: iOS 16.0 or later

#### c. Add WritersApp Library as Dependency
1. Select target → **Build Phases**
2. Add `WritersApp` library under **Link Binary With Libraries**
3. Configure **Build Settings**:
   - **Search Paths**: Add library path
   - **Swift Version**: 5.9+

#### d. Configure iPad Pro Scheme
1. Select scheme: **WritersApp (iOS)**
2. Edit scheme: **⌘ + <**
3. Set **Run** destination: **iPad Pro** (simulator or device)
4. Build & run: **⌘ + R**

### Option 2: Using Swift Package Manager (CLI)

#### Build for iOS (arm64 - Physical Device)
```bash
swift build --product WritersApp \
  -Xswiftc -target -Xswiftc arm64-apple-ios16.0 \
  -c release
```

#### Build for iOS Simulator (x86_64)
```bash
swift build --product WritersApp \
  -Xswiftc -target -Xswiftc x86_64-apple-ios16.0-simulator \
  -c release
```

#### Build Verification
```bash
# List build products
ls -R .build/release/

# Expected products:
# - WritersApp (library)
# - WritersApp.swiftmodule (module interface)
```

---

## Running on macOS

### 1. Run CLI (macOS)
```bash
# Debug build
./.build/debug/WritersAppCLI

# Release build
./.build/release/WritersAppCLI
```

### 2. Run with AI Features Enabled
```bash
# Set API key and run
ANTHROPIC_API_KEY="sk-ant-your-key-here" \
  ./.build/release/WritersAppCLI
```

### 3. Interactive CLI Commands
```
>> create-document
>> list-documents
>> export-document
>> ai-help
>> quit
```

### 4. Run Tests on macOS
```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test
swift test --filter WritersAppTests.DocumentTests
```

---

## Deploying to iPad Pro

### Prerequisite: Create iOS App Target

If you haven't already, create a minimal iOS app that imports and uses `WritersApp`:

**Minimal SwiftUI App Structure:**
```swift
import SwiftUI
import WritersApp

@main
struct WritersAppIOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var app = WritersApp()
    
    var body: some View {
        VStack {
            Text("Writers App for iPad")
            Button("Create Document") {
                _ = app.documentManager.createBlankDocument(
                    title: "New Draft",
                    category: .novel
                )
            }
        }
        .padding()
    }
}
```

### Option 1: Deploy to iPad Simulator

#### Start iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Boot iPad Pro simulator
xcrun simctl boot "iPad Pro (12.9-inch) (7th generation)"

# Or use Xcode UI:
# Xcode → Product → Destination → iPad Pro (simulator)
```

#### Build and Run on Simulator
```bash
# Using Xcode
⌘ + R  # Build and run (with iPad simulator selected)

# Or via command line
xcodebuild -scheme WritersApp \
  -destination "generic/platform=iOS Simulator" \
  -configuration Release \
  build
```

### Option 2: Deploy to Physical iPad Pro

#### Step 1: Configure Signing & Capabilities
1. **Xcode** → **Project Settings**
2. Select target → **Signing & Capabilities**
3. **Team**: Select your Apple Developer Team
4. **Bundle Identifier**: `com.yourcompany.WritersApp`
5. **Minimum Deployment**: iOS 16.0

#### Step 2: Enable Capabilities (if using advanced features)
- **iCloud** (optional, for CloudKit sync)
- **Push Notifications** (optional, for reminders)
- **Background Modes** (optional)

#### Step 3: Connect iPad to Mac
```bash
# Verify iPad is recognized
instruments -s devices

# Expected output: iPad Pro (Connected)
```

#### Step 4: Build and Deploy
```bash
# Using Xcode
1. Select target iPad from device menu (⌘ + Shift + O)
2. Build & run: ⌘ + R
3. Xcode will sign, build, and install on iPad

# Or via command line
xcodebuild -scheme WritersApp \
  -destination "id=<device-udid>" \
  -configuration Release \
  install
```

#### Step 5: Trust Developer on iPad
1. On iPad: **Settings** → **General** → **Device Management**
2. Tap developer account
3. Tap **Trust** [Developer Name]

#### Step 6: Launch App
1. On iPad: Open **Writers App**
2. Grant permissions as needed (Documents, etc.)

### Option 3: Create IPA for Distribution

#### Generate IPA Archive
```bash
# Build for App Store (requires certificates)
xcodebuild -scheme WritersApp \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/WritersApp.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/WritersApp.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath build/ipa
```

---

## Troubleshooting

### Build Issues

#### "swift: command not found"
```bash
# Ensure Xcode Command Line Tools are installed
xcode-select --install

# Or set Xcode path explicitly
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### SQLite3 Library Not Found
```bash
# Reinstall sqlite3
brew reinstall sqlite3

# Set pkg-config path
export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig"
```

#### Dependency Resolution Fails
```bash
# Clear Swift package cache
rm -rf .build
rm -rf .swiftpm

# Fetch dependencies again
swift package resolve
swift build
```

### iOS/Simulator Issues

#### iPad Simulator Won't Start
```bash
# Reset simulator
xcrun simctl erase all

# Or reset specific device
xcrun simctl erase "iPad Pro (12.9-inch) (7th generation)"

# Restart Simulator
killall "Simulator"
open -a Simulator
```

#### Code Signing Failures
1. **Xcode** → **Preferences** → **Accounts**
2. Sign in with Apple ID
3. **Manage Certificates** → Add Apple Development certificate
4. Project → **Signing & Capabilities** → Select Team

#### App Won't Launch on iPad
1. Check **Console** output in Xcode
2. Verify `Bundle Identifier` format
3. Ensure iOS deployment target ≥ 16.0
4. Clear iPad cache: **Settings** → **General** → **Storage** → Delete app → Reinstall

### Runtime Issues

#### Database File Not Found
```bash
# Verify database path
defaults write com.yourcompany.WritersApp database-path "<path>"

# Or use default location
# macOS: ~/Documents/writersapp.db
# iOS: App Documents folder (automatic)
```

#### AI Features Not Working
```bash
# Verify API key is set
echo $ANTHROPIC_API_KEY

# If not set, add to shell profile
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc
source ~/.zshrc
```

---

## Build Configuration Summary

| Platform | Destination | Command | Output |
|----------|-------------|---------|--------|
| **macOS (Debug)** | Local machine | `swift build` | `.build/debug/WritersAppCLI` |
| **macOS (Release)** | Local machine | `swift build -c release` | `.build/release/WritersAppCLI` |
| **iOS (Simulator)** | iPad Simulator | Xcode or `xcodebuild -destination "generic/platform=iOS Simulator"` | Runs in Simulator |
| **iOS (Physical)** | iPad Pro (connected) | Xcode or `xcodebuild -destination "id=<udid>"` | Installed on device |

---

## Next Steps

1. **Build macOS CLI**: `swift build -c release`
2. **Test macOS**: `./.build/release/WritersAppCLI`
3. **Set up iOS target** in Xcode (if not already done)
4. **Build for iOS Simulator**: Select iPad in Xcode, press ⌘ + R
5. **Deploy to iPad Pro**: Connect iPad, select device, press ⌘ + R
6. **Verify AI features**: Set `ANTHROPIC_API_KEY` and test

---

## References

- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [Xcode Help](https://help.apple.com/xcode/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Project README](./README.md)
- [Project Architecture](./CLAUDE.md)
