# Clother Integration Guide

**friendly-outlaw** integrates seamlessly with [Clother](https://github.com/jolehuit/clother), a CLI wrapper that enables access to 100+ LLM providers with a single interface.

## Quick Start

### 1. Install Claude CLI (Required)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### 2. Install Clother

```bash
curl -fsSL https://raw.githubusercontent.com/jolehuit/clother/main/clother.sh | bash
```

### 3. Configure Your Provider

```bash
clother config                  # Interactive setup wizard
clother test                    # Verify connectivity
```

### 4. Run friendly-outlaw with Clother

```bash
# Using default Clother launcher (usually claude-native)
clother-native swift run WritersAppCLI

# Or configure a specific provider
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
swift run WritersAppCLI
```

## Available Providers

### Cloud Providers (with API Key)

| Provider | Command | Model | Setup |
|----------|---------|-------|-------|
| **Anthropic Claude** | `clother-native` | Claude 3.5 Sonnet | Your Claude Pro/Team subscription |
| **Z.AI (GLM-5)** | `clother-zai` | GLM-5 | `clother config zai` |
| **MiniMax** | `clother-minimax` | MiniMax M2.5 | `clother config minimax` |
| **Kimi** | `clother-kimi` | Kimi K2.5 | `clother config kimi` |
| **Moonshot** | `clother-moonshot` | Kimi K2.5 | `clother config moonshot` |
| **DeepSeek** | `clother-deepseek` | DeepSeek Chat | `clother config deepseek` |
| **Xiaomi MiMo** | `clother-mimo` | MiMo V2 Flash | `clother config mimo` |
| **Alibaba** | `clother-alibaba` | Qwen 3.5+ | `clother config alibaba` |
| **OpenRouter** | `clother-or-*` | 100+ models | `clother config openrouter` |

### Local Providers (No API Key Required)

| Provider | Command | Port | Setup |
|----------|---------|------|-------|
| **Ollama** | `clother-ollama` | 11434 | [ollama.com](https://ollama.com) |
| **LM Studio** | `clother-lmstudio` | 1234 | [lmstudio.ai](https://lmstudio.ai) |
| **llama.cpp** | `clother-llamacpp` | 8000 | [github.com/ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) |

### China Endpoints

| Provider | Command | Endpoint |
|----------|---------|----------|
| Z.AI | `clother-zai-cn` | open.bigmodel.cn |
| MiniMax | `clother-minimax-cn` | api.minimaxi.com |
| Volcano | `clother-ve` | ark.cn-beijing.volces.com |
| Alibaba | `clother-alibaba-cn` | coding.dashscope.aliyuncs.com |

## Provider Setup Examples

### Using Z.AI (GLM-5)

```bash
# Configure Z.AI
clother config zai
# Enter your Z.AI API key when prompted

# Run with Z.AI
clother-zai swift run WritersAppCLI
```

### Using DeepSeek

```bash
# Configure DeepSeek
clother config deepseek
# Enter your DeepSeek API key when prompted

# Run with DeepSeek
clother-deepseek swift run WritersAppCLI
```

### Using Local Ollama

```bash
# Start Ollama server
ollama serve

# In another terminal, pull a model
ollama pull qwen3-coder

# Run with Ollama
clother-ollama --model qwen3-coder swift run WritersAppCLI
```

### Using OpenRouter

```bash
# Configure OpenRouter (supports 100+ models)
clother config openrouter
# Enter your OpenRouter API key when prompted

# See available models at: https://openrouter.ai/models

# Use Grok via OpenRouter
clother-or-grok-3 swift run WritersAppCLI

# Use Gemini via OpenRouter
clother-or-google-gemini-2-0 swift run WritersAppCLI

# Use Mistral via OpenRouter
clother-or-mistral-7b swift run WritersAppCLI
```

## Environment Variables

When using Clother, the following environment variables are automatically set by the launcher scripts:

```bash
# Set by Clother launchers
ANTHROPIC_BASE_URL      # Custom API endpoint URL
ANTHROPIC_AUTH_TOKEN    # API key/token for the provider
ANTHROPIC_MODEL         # Override default model for the provider
```

You can also override these manually:

```bash
# Use a specific model from a provider
export ANTHROPIC_MODEL="claude-opus-4.6"
clother-native swift run WritersAppCLI

# Or inline
clother-native --model claude-opus-4.6 swift run WritersAppCLI
```

## Integration with WritersAppCLI

The CLI automatically detects which provider is configured and uses it for:

- ✅ AI writing assistance (continue, improve, brainstorm, etc.)
- ✅ Document analysis and insights
- ✅ Title generation and outline creation
- ✅ Character development and dialogue improvement
- ✅ Grammar checking and tone adjustment

No additional configuration needed! The CLI uses the environment variables set by Clother.

### Example Workflow

```bash
# 1. Configure your favorite provider (one time)
clother config zai

# 2. Run the CLI with that provider
clother-zai swift run WritersAppCLI

# 3. All AI features now use Z.AI (GLM-5) instead of Anthropic
# 4. Switch providers anytime by using a different launcher
clother-deepseek swift run WritersAppCLI  # Now using DeepSeek

# 5. Or run locally with Ollama
clother-ollama --model qwen3-coder swift run WritersAppCLI  # Now using local Ollama
```

## Changing Default Models

Each Clother launcher comes with a default model. Override it in three ways:

### Option 1: Command-line Flag (One-time)

```bash
clother-zai --model glm-4.7 swift run WritersAppCLI
```

### Option 2: Environment Variable (Persistent)

```bash
export ANTHROPIC_MODEL="glm-4.7"
clother-zai swift run WritersAppCLI
```

### Option 3: Edit Launcher Script (Permanent)

```bash
nano ~/bin/clother-zai
# Replace model name on all relevant lines
```

## Troubleshooting

### "claude: command not found"
Install Claude CLI first:
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### "clother: command not found"
Add Clother's bin directory to PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"  # Linux
export PATH="$HOME/bin:$PATH"         # macOS

# Or check installation directory
clother status
```

### "API key not set"
Configure your provider:
```bash
clother config
```

### "API connection failed"
Test your provider configuration:
```bash
clother test
```

### Model not available
Check available models for your provider:
```bash
# For OpenRouter
open https://openrouter.ai/models

# Or check provider's documentation
clother list                # List configured providers
```

## VS Code Integration

To use Clother with Claude Code extension:

1. Open VS Code Settings (`Cmd+,` or `Ctrl+,`)
2. Search for "Claude Process Wrapper" (`claudeProcessWrapper`)
3. Set to your Clother launcher path:
   - macOS: `/Users/yourname/bin/clother-zai`
   - Linux: `/home/yourname/.local/bin/clother-zai`
4. Reload VS Code

**Requires Clother v2.6+**

## Custom Providers

Create custom Clother launchers for proprietary or internal LLM services:

```bash
clother config                # Choose "custom"
clother-myprovider           # Ready to use
```

Edit the custom launcher in `~/.local/bin/clother-myprovider` to configure your endpoint and auth token.

## Security

- API keys are stored in `~/.local/share/clother/secrets.env` with restricted permissions (`chmod 600`)
- Never commit `.env` files or API keys to version control
- Clother launchers are simple shell scripts—inspect before running untrusted code

## Performance Notes

- **Cloud providers**: Low latency, high availability, subject to rate limits
- **Local providers** (Ollama, LM Studio): High latency on first generation, subsequent tokens are fast, no rate limits
- **OpenRouter**: Reliable uptime, aggregates 100+ models, subject to per-model limits

## Model Recommendations for Writing

| Use Case | Provider | Model |
|----------|----------|-------|
| **Best Quality** | `clother-native` | Claude 3.5 Sonnet |
| **Budget-Friendly** | `clother-deepseek` | DeepSeek Chat |
| **Creative Writing** | `clother-zai` | GLM-5 |
| **Local/Offline** | `clother-ollama` | Qwen 3-Coder |
| **Multi-Provider** | `clother-or-*` | See [OpenRouter](https://openrouter.ai) |

## Further Resources

- [Clother GitHub](https://github.com/jolehuit/clother)
- [OpenRouter Models](https://openrouter.ai/models)
- [Ollama Models](https://ollama.com/library)
- [Claude API Documentation](https://docs.anthropic.com)
- [Anthropic Console](https://console.anthropic.com)
