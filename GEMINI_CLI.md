# Gemini CLI

Installation, execution, and release information for the Gemini CLI tool.

---

## System Requirements

| Category | Requirement |
|----------|------------|
| **Operating System** | macOS 15+, Windows 11 24H2+, Ubuntu 20.04+ |
| **RAM (casual use)** | 4 GB+ (short sessions, common tasks and edits) |
| **RAM (power use)** | 16 GB+ (long sessions, large codebases, deep context) |
| **Runtime** | Node.js 20.0.0+ |
| **Shell** | Bash, Zsh, or PowerShell |
| **Network** | Internet connection required; Gemini Code Assist supported locations |

---

## Installation

Gemini CLI comes pre-installed on **Cloud Shell** and **Cloud Workstations**. For local environments, use one of the following methods.

### npm (recommended)

```bash
npm install -g @google/gemini-cli
```

### Homebrew (macOS/Linux)

```bash
brew install gemini-cli
```

### MacPorts (macOS)

```bash
sudo port install gemini-cli
```

### Anaconda

Install via the conda package manager as documented in the Anaconda channel.

---

## Running Gemini CLI

### Standard usage

```bash
gemini
```

For a full list of options and commands, see the CLI cheatsheet.

### npx (no installation required)

Run Gemini CLI instantly without a permanent installation:

```bash
npx @google/gemini-cli
```

### Run directly from GitHub (for testing unreleased features)

```bash
npx https://github.com/google-gemini/gemini-cli
```

### Docker / Podman Sandbox

Run in an isolated container environment — see the project's Docker documentation for details.

### Build from source

Clone the repository and follow the build instructions in the contributing guide.

---

## Release Channels

| Channel | Cadence | Tag | Notes |
|---------|---------|-----|-------|
| **Stable** | Weekly | `latest` | Default; recommended for most users |
| **Preview** | Continuous | `preview` | Stable releases are cut from the previous week's preview |
| **Nightly** | Daily | `nightly` | Bleeding-edge; may be unstable |

### Installing a specific channel

```bash
# Stable (default)
npm install -g @google/gemini-cli
npm install -g @google/gemini-cli@latest

# Preview
npm install -g @google/gemini-cli@preview

# Nightly
npm install -g @google/gemini-cli@nightly
```

---

*Last updated: Apr 17, 2026*
