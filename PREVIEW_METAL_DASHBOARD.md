# Metal Dashboard - iPad Pro Interface

A brutal, heavy metal-themed command center for writers on iPad Pro. Inspired by the darkness of Whitechapel and the raw aggression of Lamb of God.

## Overview

The Metal Dashboard is a SwiftUI-based iPad interface that provides a powerful, visually striking way to manage your writing projects, track productivity, and stay motivated with a heavy metal aesthetic.

## Features

### Dashboard Sections

#### 🤘 The Mantra
Rotating heavy metal-inspired motivational quotes to fuel your writing sessions. Examples:
- "Split Your Mind" — Whitechapel
- "Redneck" — Lamb of God
- "Walk With Me In Hell" — Lamb of God
- "Now You've Got Something To Die For" — Lamb of God

#### 💀 Kill Count
Real-time statistics tracking:
- Total words written across all documents
- Document count
- Writing streaks (consecutive days)
- Total focus time
- Average word count per document

#### ⚔️ The Armory
Quick-start focus sessions:
- **Pomodoro** (25 min) — Classic focused writing with breaks
- **Sprint** (15 min) — Short, intense writing burst
- **Deep Work** (90 min) — Extended concentration session
- **Marathon** (120 min) — Long-form sustained writing

#### 📜 War Room
Recent documents list with:
- Document title and preview
- Word count
- Last modified date
- Quick access to continue editing

#### 🎯 The Gauntlet
Writing goals and progress tracking:
- Active goals with progress bars
- Goal deadlines and word targets
- Achievement indicators
- Completed goals summary

#### 🔥 The Forge
Quick actions for creating new content:
- Create blank document
- Browse and use templates
- Start new project from scratch

## Design System

### Color Palette

The Metal Theme provides a dark, aggressive color scheme:

| Color | Usage | RGB Values |
|-------|-------|-----------|
| **Abyss** | Primary background | (0.03, 0.03, 0.03) |
| **Obsidian** | Card backgrounds | (0.09, 0.09, 0.09) |
| **Gunmetal** | Nested surfaces | (0.15, 0.15, 0.15) |
| **Blood Red** | Primary accent | (0.55, 0.0, 0.0) |
| **Crimson** | Active states | (0.86, 0.08, 0.24) |
| **Ember** | Warm highlights | (1.0, 0.27, 0.0) |
| **Chrome** | Primary text | (0.88, 0.88, 0.88) |
| **Steel** | Secondary text | (0.55, 0.55, 0.55) |
| **Chain Link** | Borders/dividers | (0.22, 0.22, 0.22) |
| **Gold** | Achievements | (0.85, 0.65, 0.13) |
| **Toxic Green** | Streak indicators | (0.0, 0.75, 0.25) |

### Typography

Custom font styling for metal aesthetic:
- **Brutal**: Large, heavy headers (28-36pt)
- **Aggro**: Medium weight for sections (20-24pt)
- **Relentless**: Body text and stats (16-18pt)
- **Subdued**: Secondary information (12-14pt)

### Gradients

- **Fire Gradient**: Blood Red → Crimson → Ember (for accent bars)
- **Abyss Gradient**: Deep black with subtle red tint (for backgrounds)
- **Hell Glow**: Red radial glow for active elements

## Architecture

### Components

```
Sources/WritersApp/Views/
├── MetalDashboardView.swift        # Main dashboard UI
├── MetalDashboardViewModel.swift   # Observable state and logic
└── MetalTheme.swift                # Theme colors and styling
```

### View Model

The `MetalDashboardViewModel` bridges WritersApp services into SwiftUI:

**Published State:**
- Document statistics and recent documents
- Writing goals and progress
- Focus session tracking
- Current mantra rotation
- Navigation state

**Services Integration:**
- `WritersApp` — Core app functionality
- `FocusSessionManager` — Timed writing sessions
- `WritingGoalManager` — Goal tracking and analytics

### Usage

```swift
import WritersApp
import SwiftUI

// Initialize the dashboard
let app = WritersApp()
let viewModel = MetalDashboardViewModel(app: app)

// Display in SwiftUI
struct ContentView: View {
    var body: some View {
        MetalDashboardView(viewModel: viewModel)
    }
}
```

## Platform Requirements

- iOS 16.0+ or macOS 13.0+
- SwiftUI framework
- Optimized for iPad Pro (12.9" and 11" displays)
- Works on iPhone and Mac with responsive layout

## Testing

### Test Coverage

The Metal Dashboard includes comprehensive test coverage:

```bash
# Run all Metal Dashboard tests
swift test --filter MetalDashboardTests
```

**Test Results:**
- `swift test` executed on 2026-02-08 — 201 tests passed, 0 failures
- All tests run on `MainActor` for SwiftUI compatibility

### Test Categories

- View model initialization and state updates
- Statistics calculations and formatting
- Focus session management
- Goal tracking integration
- Mantra rotation logic
- Navigation state handling

## Preview Mode

The dashboard includes a preview harness for development:

```swift
// Sources/WritersApp/Previews/MetalDashboardPreview.swift
import SwiftUI

struct MetalDashboardPreview: PreviewProvider {
    static var previews: some View {
        MetalDashboardView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
    }
}
```

## Roadmap

Future enhancements planned:
- **Animations**: Heavy entrance animations with shake effects
- **Sound Effects**: Optional guitar riff sound cues for achievements
- **Customization**: User-selectable metal themes (Death Metal, Thrash, Doom)
- **Widgets**: Home screen widgets with metal aesthetic
- **Apple Pencil**: Handwritten notes with blood splatter effects
- **Achievements**: Metal-themed badges and milestones

## References

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [iPad Pro Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Metal Graphics Framework](https://developer.apple.com/metal/) (not used, but inspired the name)

## Inspiration

Bands that influenced the aesthetic:
- Whitechapel — For the darkness and brutality
- Lamb of God — For the relentless energy
- Gojira — For the atmospheric weight
- Architects — For the modern edge
