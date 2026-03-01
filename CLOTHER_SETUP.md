# Clother Setup Guide for Contributors

This guide helps contributors set up **friendly-outlaw** for development with **Clother**, enabling multi-provider LLM support during testing and implementation.

## Prerequisites

- Swift 5.9+
- macOS 13+, iOS 16+, or Linux with SQLite3
- Claude CLI installed
- Clother installed

## Installation Steps

### Step 1: Install Claude CLI

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Verify installation:
```bash
claude --version
```

### Step 2: Install Clother

```bash
curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash
```

Verify installation:
```bash
clother status
```

### Step 3: Verify PATH Configuration

Ensure Clother's bin directory is in your PATH:

**macOS:**
```bash
echo $PATH | grep -q "$HOME/bin" && echo "✓ ~/bin is in PATH" || echo "✗ Add ~/bin to PATH"
```

**Linux:**
```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "✓ ~/.local/bin is in PATH" || echo "✗ Add ~/.local/bin to PATH"
```

If not in PATH, add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
# macOS
export PATH="$HOME/bin:$PATH"

# Linux
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Provider Configuration

### Quick Setup (Recommended for First-Time Contributors)

Use the interactive setup wizard:

```bash
clother config
# Follow prompts to choose a provider and configure it
clother test     # Verify connectivity
```

### Provider-Specific Setup

Choose one provider based on your preference:

#### Option A: Claude (Anthropic) - Best Quality

Your existing Claude Pro/Team subscription provides access:

```bash
# Already configured if you have Claude CLI + Pro/Team subscription
clother-native swift run WritersAppCLI --help
```

#### Option B: Z.AI (GLM-5) - Cost-Effective

```bash
clother config zai
# Enter your Z.AI API key from https://z.ai
clother test
clother-zai swift run WritersAppCLI --help
```

#### Option C: DeepSeek - Affordable Alternative

```bash
clother config deepseek
# Enter your DeepSeek API key from https://deepseek.com
clother test
clother-deepseek swift run WritersAppCLI --help
```

#### Option D: Local Ollama - No API Key (Offline Development)

```bash
# Install Ollama if not already installed
# Download from https://ollama.com

# Start Ollama service
ollama serve

# In another terminal, pull a model
ollama pull qwen3-coder

# Test with friendly-outlaw
clother-ollama --model qwen3-coder swift run WritersAppCLI --help
```

#### Option E: OpenRouter - Access 100+ Models

```bash
clother config openrouter
# Enter your OpenRouter API key from https://openrouter.ai
clother test

# Available models:
# - anthropic/claude-opus-4.6 (Claude)
# - z-ai/glm-5 (GLM-5)
# - deepseek/deepseek-v3 (DeepSeek)
# - mistralai/mixtral-8x7b (Mistral)
# - google/gemini-2.0 (Gemini)

clother-or-grok-3 swift run WritersAppCLI --help  # Use Grok
```

## Development Workflow

### Building the Project

```bash
# Standard build
swift build

# Release build (optimized)
swift build -c release
```

### Running with CLI Arguments

```bash
# List documents
clother-native swift run WritersAppCLI --list

# Run help
clother-native swift run WritersAppCLI --help

# Open a document
clother-native swift run WritersAppCLI --open "My Document"

# Start a focus session
clother-native swift run WritersAppCLI --run pomodoro
```

### Running Interactive Mode

```bash
# Default provider (usually clother-native)
clother-native swift run WritersAppCLI

# Or use any configured provider
clother-zai swift run WritersAppCLI
clother-deepseek swift run WritersAppCLI
clother-ollama --model qwen3-coder swift run WritersAppCLI
```

### Testing with Different Providers

**Test to ensure all AI features work with each provider:**

```bash
# Test with Claude
clother-native swift run WritersAppCLI

# Test with Z.AI
clother-zai swift run WritersAppCLI

# Test with DeepSeek
clother-deepseek swift run WritersAppCLI

# Test with Local Ollama
clother-ollama --model qwen3-coder swift run WritersAppCLI
```

In each session:
1. Create a test document
2. Test AI features (continue writing, improve text, analyze)
3. Verify output quality and consistency

## Running Tests

```bash
# Standard test suite
swift test

# Verbose output
swift test --verbose

# Run specific test
swift test WritersAppTests
```

Tests automatically use the Anthropic API if `ANTHROPIC_API_KEY` is set. For testing with alternative providers, set environment variables before running tests:

```bash
# Test with Z.AI
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
swift test

# Test with DeepSeek
export ANTHROPIC_BASE_URL="https://api.deepseek.com/beta/claude"
export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
swift test
```

## VS Code Integration

To use Clother with VS Code's Claude Code extension:

1. Open VS Code Settings (`Cmd+,` on macOS, `Ctrl+,` on Windows/Linux)
2. Search for "Claude Process Wrapper"
3. Set the path to your Clother launcher:
   - **macOS**: `/Users/yourname/bin/clother-native`
   - **Linux**: `/home/yourname/.local/bin/clother-native`
   - **Custom**: Adjust for your configured provider

4. Reload VS Code

This allows Claude Code to use your configured LLM provider when generating code suggestions.

## Contributing Features with Multiple Providers

When implementing new AI features:

1. **Test with Multiple Providers**: Ensure features work with:
   - Anthropic Claude (baseline)
   - At least one alternative (Z.AI, DeepSeek, OpenRouter)
   - Consider local provider testing for offline support

2. **Document Provider-Specific Behavior**: If a feature behaves differently with certain providers, note it in code comments and PR description

3. **Use Environment Variables**: Don't hardcode provider logic; rely on environment variables set by Clother:
   - `ANTHROPIC_BASE_URL` (API endpoint)
   - `ANTHROPIC_AUTH_TOKEN` (authentication token)
   - `ANTHROPIC_MODEL` (model override)

Example in Swift:

```swift
let apiUrl = ProcessInfo.processInfo.environment["ANTHROPIC_BASE_URL"]
    ?? "https://api.anthropic.com/v1"
let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_AUTH_TOKEN"]
    ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    ?? ""
```

## Troubleshooting

### "clother-* command not found"

**Cause**: Bin directory not in PATH

**Solution**:
```bash
# Check installation
clother status

# Add to PATH (macOS)
export PATH="$HOME/bin:$PATH"

# Add to PATH (Linux)
export PATH="$HOME/.local/bin:$PATH"

# Make permanent by adding to ~/.zshrc or ~/.bashrc
```

### "API connection failed"

**Cause**: Provider not configured or API key invalid

**Solution**:
```bash
clother config <provider>  # Reconfigure
clother test              # Verify connectivity
```

### "API key not set"

**Cause**: Missing authentication token

**Solution**:
```bash
clother config
# Enter your API key when prompted
```

### "Model not available"

**Cause**: Model doesn't exist for the provider

**Solution**:
```bash
# For OpenRouter, check available models
open https://openrouter.ai/models

# Try with exact model ID
clother config openrouter
clother-or-claude-opus-4-6 swift run WritersAppCLI
```

### "Swift build fails"

**Cause**: Missing SQLite development libraries

**Solution (Linux)**:
```bash
# Ubuntu/Debian
sudo apt-get install libsqlite3-dev

# Fedora/RHEL
sudo dnf install sqlite-devel
```

**Solution (macOS)**:
```bash
brew install sqlite3
export PKG_CONFIG_PATH="/opt/homebrew/opt/sqlite/lib/pkgconfig"
swift build
```

## Recommended Setup for Contributors

### Development Machine Setup

```bash
# Step 1: Install prerequisites
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash

# Step 2: Configure primary provider (e.g., Claude Pro)
clother config

# Step 3: Clone and enter project
git clone <friendly-outlaw-repo>
cd friendly-outlaw

# Step 4: Build and test
swift build
swift test

# Step 5: Run with Clother
clother-native swift run WritersAppCLI

# Step 6: (Optional) Configure secondary provider for testing
clother config zai
clother-zai swift run WritersAppCLI
```

### CI/CD Provider Selection

For GitHub Actions or other CI systems:

```yaml
# Use OpenRouter for multi-model coverage in CI
env:
  ANTHROPIC_BASE_URL: https://openrouter.ai/api/v1
  ANTHROPIC_AUTH_TOKEN: ${{ secrets.OPENROUTER_API_KEY }}
  ANTHROPIC_MODEL: anthropic/claude-opus-4.6
```

## Git Workflow

When making changes that use Clother:

1. **Create feature branch** (already provided in git workflow requirements)
2. **Test with multiple providers** before committing:
   ```bash
   clother-native swift test
   clother-zai swift test
   clother-ollama swift test
   ```
3. **Commit with clear messages** indicating provider compatibility
4. **Push to feature branch** and create PR

Example commit message:
```
feat: add provider-agnostic AI tool executor

- Works with Anthropic Claude, Z.AI, DeepSeek, and OpenRouter
- Tested with local Ollama (qwen3-coder model)
- Uses environment variables for provider configuration
- No hardcoded API endpoints or models
```

## Performance Considerations

| Provider | Speed | Cost | Best For |
|----------|-------|------|----------|
| Claude (Anthropic) | Fast | High | Production, high quality |
| Z.AI (GLM-5) | Fast | Low | Budget-conscious dev |
| DeepSeek | Fast | Low | General development |
| OpenRouter | Fast | Variable | Testing multiple models |
| Ollama (Local) | Slow first, fast after | Free | Offline dev, cost-free testing |

## Additional Resources

- **Clother GitHub**: https://github.com/jolehuit/clother
- **OpenRouter Models**: https://openrouter.ai/models
- **Ollama Library**: https://ollama.com/library
- **Project Guide**: See [CLOTHER.md](CLOTHER.md) for detailed provider setup
- **Main README**: See [README.md](README.md) for project overview
