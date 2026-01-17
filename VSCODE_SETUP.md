# VS Code Setup for iPad and MacBook Pro

This guide will help you set up Visual Studio Code for developing the Writers App on both your iPad and MacBook Pro with seamless synchronization.

## Table of Contents
- [Initial Setup](#initial-setup)
- [MacBook Pro Setup](#macbook-pro-setup)
- [iPad Setup](#ipad-setup)
- [Settings Sync](#settings-sync)
- [Recommended Extensions](#recommended-extensions)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Tips & Tricks](#tips--tricks)

---

## Initial Setup

### Prerequisites
- **MacBook Pro**: macOS 13+ with Swift 5.9+
- **iPad**: iPadOS 16+ with VS Code installed
- Microsoft account (for Settings Sync)
- Git configured on both devices

### Install VS Code

#### MacBook Pro
1. Download from [code.visualstudio.com](https://code.visualstudio.com)
2. Or install via Homebrew:
   ```bash
   brew install --cask visual-studio-code
   ```

#### iPad
1. Download from the App Store
2. Or use [vscode.dev](https://vscode.dev) in Safari for web-based editing

---

## MacBook Pro Setup

### 1. Install Swift and SourceKit-LSP

Ensure Swift is installed:
```bash
swift --version
```

Verify SourceKit-LSP location:
```bash
which sourcekit-lsp
```

### 2. Install Required Extensions

Open VS Code and install these extensions (or let VS Code prompt you based on `extensions.json`):

**Essential:**
- Swift Development Environment (vknabel.vscode-swift-development-environment)
- Swift Language Support (sswg.swift-lang)

**Recommended:**
- GitLens (eamodio.gitlens)
- Error Lens (usernamehw.errorlens)
- Code Spell Checker (streetsidesoftware.code-spell-checker)
- Todo Tree (gruntfuggly.todo-tree)

### 3. Configure Swift Path

If Swift is not in the default location, update `.vscode/settings.json`:
```json
{
  "swift.path": "/path/to/your/swift",
  "swift.sourcekit-lsp.serverPath": "/path/to/sourcekit-lsp"
}
```

### 4. Build the Project

Test the setup:
```bash
# Clean build
swift build

# Run tests
swift test

# Run the CLI
swift run WritersAppCLI
```

### 5. Use VS Code Tasks

Access tasks via:
- **Cmd+Shift+P** → "Tasks: Run Task"
- Or use **Cmd+Shift+B** for the default build task

Available tasks:
- Swift: Build (default)
- Swift: Build Release
- Swift: Test
- Swift: Clean
- Swift: Run CLI
- Swift: Update Dependencies

---

## iPad Setup

### Option 1: VS Code for iPad (Native App)

1. **Install from App Store**
   - Search for "Visual Studio Code"
   - Install and open

2. **Clone Repository**
   - Open Command Palette: Tap the hamburger menu
   - Select "Git: Clone"
   - Enter repository URL
   - Choose local folder

3. **Install Extensions**
   - Open Extensions view
   - Search and install recommended extensions
   - Note: Some extensions may not be available on iPad

### Option 2: Remote Development via SSH

For full development capabilities on iPad, connect to a remote server or your MacBook:

1. **On MacBook Pro:**
   ```bash
   # Enable Remote Login
   sudo systemsetup -setremotelogin on

   # Find your IP address
   ifconfig | grep "inet "
   ```

2. **On iPad:**
   - Install "Remote - SSH" extension
   - Connect to MacBook: `ssh username@macbook-ip`
   - Open the project folder remotely

### Option 3: GitHub Codespaces

1. Navigate to your repository on GitHub
2. Click "Code" → "Codespaces" → "Create codespace"
3. Access from VS Code for iPad
4. Full development environment in the cloud

### Option 4: VS Code for Web

1. Navigate to [vscode.dev](https://vscode.dev)
2. Sign in with GitHub
3. Open your repository directly
4. Note: Limited terminal access, best for editing only

---

## Settings Sync

Keep your settings, extensions, and keybindings synchronized across devices.

### Enable Settings Sync

1. **On MacBook Pro:**
   - Click the gear icon (⚙️) → "Turn on Settings Sync"
   - Sign in with your Microsoft or GitHub account
   - Select what to sync:
     - ✅ Settings
     - ✅ Keyboard Shortcuts
     - ✅ Extensions
     - ✅ User Snippets
     - ✅ UI State

2. **On iPad:**
   - Tap the gear icon → "Turn on Settings Sync"
   - Sign in with the same account
   - Your settings will automatically sync

### What Gets Synced

- Editor preferences (font size, theme, etc.)
- Extension installations
- Keyboard shortcuts
- Code snippets
- Git configuration
- Workspace settings (from `.vscode/` folder)

### What Doesn't Sync

- Local file paths
- Swift installation paths (device-specific)
- SSH configurations
- Local git repositories

---

## Recommended Extensions

### Core Development
| Extension | Purpose | iPad Compatible |
|-----------|---------|-----------------|
| Swift Development Environment | Swift language support, IntelliSense | ✅ |
| Swift Language | Additional Swift tooling | ✅ |
| GitLens | Advanced Git features | ✅ |
| Error Lens | Inline error highlighting | ✅ |

### Productivity
| Extension | Purpose | iPad Compatible |
|-----------|---------|-----------------|
| Todo Tree | Track TODOs in code | ✅ |
| Code Spell Checker | Catch typos | ✅ |
| Markdown All in One | Markdown editing | ✅ |
| Git Graph | Visual git history | ✅ |

### Remote Development
| Extension | Purpose | iPad Compatible |
|-----------|---------|-----------------|
| Remote - SSH | Connect to remote machines | ✅ |
| Remote Explorer | Browse remote connections | ✅ |

---

## Keyboard Shortcuts

### MacBook Pro

| Action | Shortcut |
|--------|----------|
| Command Palette | `Cmd+Shift+P` |
| Quick Open | `Cmd+P` |
| Build (Default Task) | `Cmd+Shift+B` |
| Run Task | `Cmd+Shift+P` → "Tasks: Run Task" |
| Toggle Terminal | `Ctrl+` ` |
| Go to Definition | `F12` |
| Find References | `Shift+F12` |
| Rename Symbol | `F2` |
| Format Document | `Shift+Option+F` |
| Toggle Sidebar | `Cmd+B` |

### iPad (with External Keyboard)

| Action | Shortcut |
|--------|----------|
| Command Palette | `Cmd+Shift+P` |
| Quick Open | `Cmd+P` |
| Toggle Terminal | `Ctrl+` ` |
| Save | `Cmd+S` |
| Find | `Cmd+F` |
| Replace | `Cmd+Option+F` |

### iPad (Touch)

- **Command Palette**: Tap hamburger menu → "Command Palette"
- **Open File**: Tap Explorer icon → Navigate
- **Save**: Tap File menu → "Save"
- **Terminal**: Tap hamburger menu → "Terminal" → "New Terminal"

---

## Tips & Tricks

### For MacBook Pro

1. **Use Integrated Terminal**
   - `Ctrl+` ` to toggle terminal
   - Run Swift commands directly: `swift build`, `swift test`

2. **Multi-cursor Editing**
   - `Option+Click` to add cursors
   - `Cmd+D` to select next occurrence

3. **Split Editor**
   - `Cmd+\` to split editor
   - Work on multiple files simultaneously

4. **Breadcrumbs Navigation**
   - Enable in View → "Show Breadcrumbs"
   - Quick navigation through code structure

### For iPad

1. **External Keyboard Recommended**
   - Significantly improves productivity
   - Access all keyboard shortcuts

2. **Use Trackpad/Mouse Support**
   - iPadOS supports trackpad for better code navigation
   - Hover for IntelliSense and tooltips

3. **Split View**
   - Use iPad's Split View to have documentation open alongside VS Code
   - Safari + VS Code for quick reference

4. **Cloud Storage**
   - Use iCloud Drive or GitHub for file access
   - Commit frequently to sync work

### Cross-Device Workflow

1. **Commit Frequently**
   ```bash
   git add .
   git commit -m "Work in progress"
   git push
   ```

2. **Use Branches**
   - Create feature branches for experimental work
   - Keep main branch stable

3. **Pull Before Working**
   ```bash
   git pull origin main
   ```

4. **AI Features**
   - Set `ANTHROPIC_API_KEY` environment variable on both devices
   - MacBook: Add to `~/.zshrc` or `~/.bash_profile`
   - iPad: Set in terminal before running

---

## Building and Running

### Quick Commands

```bash
# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test

# Run the CLI app
swift run WritersAppCLI

# Clean build artifacts
swift package clean

# Update dependencies
swift package update
```

### Using VS Code Tasks

1. Open Command Palette (`Cmd+Shift+P`)
2. Type "Tasks: Run Task"
3. Select from:
   - Swift: Build
   - Swift: Build Release
   - Swift: Test
   - Swift: Run CLI
   - Swift: Clean

---

## Troubleshooting

### Swift not found on iPad

- iPad doesn't natively support Swift compilation
- Use Remote SSH to connect to MacBook or a Linux server
- Or use GitHub Codespaces for cloud-based development

### SourceKit-LSP not working

```bash
# Verify installation
which sourcekit-lsp

# Update settings.json with correct path
"swift.sourcekit-lsp.serverPath": "/usr/bin/sourcekit-lsp"
```

### Extensions not syncing

- Ensure Settings Sync is enabled on both devices
- Check that you're signed in with the same account
- Some extensions may not be available on iPad

### Git authentication issues on iPad

```bash
# Use personal access token instead of password
git config --global credential.helper store

# Or use SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
```

---

## Additional Resources

- [VS Code Swift Extension Documentation](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang)
- [Swift Package Manager Guide](https://swift.org/package-manager/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [GitHub Codespaces](https://github.com/features/codespaces)

---

## Quick Start Checklist

### MacBook Pro
- [ ] Install VS Code
- [ ] Install Swift and SourceKit-LSP
- [ ] Clone repository
- [ ] Install recommended extensions
- [ ] Enable Settings Sync
- [ ] Run `swift build` to verify setup
- [ ] Run `swift test` to verify tests work

### iPad
- [ ] Install VS Code from App Store
- [ ] Sign in to Settings Sync
- [ ] Set up remote connection (SSH or Codespaces)
- [ ] Clone repository
- [ ] Install available extensions
- [ ] Test file editing and git operations

---

## Need Help?

If you encounter issues:
1. Check the VS Code Output panel (`Cmd+Shift+U`)
2. Look for Swift-related errors
3. Verify Swift installation: `swift --version`
4. Check extension logs in Output panel
5. Consult the troubleshooting section above

Happy coding! 🚀
