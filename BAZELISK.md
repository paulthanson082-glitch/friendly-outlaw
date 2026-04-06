# Bazelisk - Alternative Build System for friendly-outlaw

This document describes how to use Bazelisk to build and run friendly-outlaw as an alternative to Swift Package Manager (SPM).

## What is Bazelisk?

[Bazelisk](https://github.com/bazelbuild/bazelisk) is a wrapper for [Bazel](https://bazel.build/) that automatically manages Bazel versions. It downloads the appropriate Bazel version specified in your project and transparently passes all commands to it. This ensures consistent builds across different machines and CI/CD environments.

### Why Use Bazelisk?

- **Version Management**: Automatically downloads and uses the exact Bazel version specified in `.bazelversion`
- **Consistency**: Ensures all developers and CI systems use the same Bazel version
- **Minimal Setup**: No need to manually manage Bazel versions
- **Easy Integration**: Works seamlessly with existing Bazel build files

## Installation

### On macOS

```bash
brew install bazelisk
```

### On Linux

Download the binary from the [Bazelisk releases page](https://github.com/bazelbuild/bazelisk/releases) and add it to your PATH:

```bash
wget https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-linux-x86_64
chmod +x bazelisk-linux-x86_64
sudo mv bazelisk-linux-x86_64 /usr/local/bin/bazel
```

### On Windows

```bash
winget install Bazel.Bazelisk
# or
choco install bazelisk
# or
scoop install bazelisk
```

### Using npm (for frontend developers)

```bash
npm install -g @bazel/bazelisk
```

## Quick Start

Once Bazelisk is installed, you can use it like regular Bazel:

```bash
# Build the project
bazel build //...

# Run tests
bazel test //...

# Run the CLI application
bazel run //Sources/WritersAppCLI:WritersAppCLI

# Build with AI features enabled
bazel run //Sources/WritersAppCLI:WritersAppCLI -- --help
```

Bazelisk will automatically:
1. Check the `.bazelversion` file
2. Download Bazel if needed
3. Run the command with the specified version

## Version Management

The `.bazelversion` file specifies which version of Bazel to use:

```
6.4.0
```

You can use several formats:

```bash
# Exact version
6.4.0

# Latest LTS version
latest

# Latest from a series
6.x

# Rolling release
rolling

# Last passing commit
last_green
```

## Project Structure

The Bazel build system for friendly-outlaw is organized as follows:

```
friendly-outlaw/
├── .bazelversion              # Specifies Bazel version
├── BUILD                      # Root BUILD file
├── WORKSPACE                  # Workspace configuration
├── Package.swift              # SPM configuration (kept for reference)
├── Sources/
│   ├── WritersApp/
│   │   ├── BUILD              # WritersApp library BUILD file
│   │   ├── Models/
│   │   │   └── BUILD
│   │   ├── Services/
│   │   │   └── BUILD
│   │   ├── Plugins/
│   │   │   └── BUILD
│   │   ├── Views/
│   │   │   └── BUILD
│   │   ├── Extensions/
│   │   │   └── BUILD
│   │   └── Previews/
│   │       └── BUILD
│   └── WritersAppCLI/
│       └── BUILD              # CLI executable BUILD file
└── Tests/
    └── WritersAppTests/
        └── BUILD              # Test targets
```

## Common Bazelisk Commands

### Building

```bash
# Build everything
bazel build //...

# Build a specific target
bazel build //Sources/WritersApp:WritersApp

# Build with release configuration
bazel build -c opt //...

# Build with all CPU flags
bazel build --config=fastbuild //...
```

### Running

```bash
# Run the CLI application
bazel run //Sources/WritersAppCLI:WritersAppCLI

# Run with arguments
bazel run //Sources/WritersAppCLI:WritersAppCLI -- --help

# Run with AI features
ANTHROPIC_API_KEY="sk-..." bazel run //Sources/WritersAppCLI:WritersAppCLI
```

### Testing

```bash
# Run all tests
bazel test //...

# Run tests with verbose output
bazel test //... -s

# Run specific test target
bazel test //Tests/WritersAppTests:WritersAppTests

# Run tests with AI features
ANTHROPIC_API_KEY="sk-..." bazel test //...
```

### Development

```bash
# Build and run in one command
bazel run //Sources/WritersAppCLI:WritersAppCLI -- --help

# Interactive debugging
bazel run //Sources/WritersAppCLI:WritersAppCLI --compilation_mode=dbg

# Clean build artifacts
bazel clean

# Clean everything including downloaded versions
bazel clean --expunge
```

## Bazelisk Features

### Version Detection

Bazelisk looks for the Bazel version in this order:

1. `USE_BAZEL_VERSION` environment variable
2. `.bazeliskrc` file in the workspace root
3. `.bazelversion` file in the current or parent directory
4. `USE_BAZEL_FALLBACK_VERSION` environment variable
5. Latest stable Bazel release

### Migration and Compatibility

Bazelisk provides utilities to help migrate between Bazel versions:

```bash
# Test with strict incompatibility flags
bazelisk --strict build //...

# Migrate to new version (test each flag separately)
bazelisk --migrate build //...

# Bisect to find which version introduced a build failure
bazelisk --bisect=6.0.0..HEAD build //...
```

### Configuration File

Create a `.bazeliskrc` file in your workspace root to set environment variables persistently:

```bash
# .bazeliskrc
USE_BAZEL_VERSION=6.4.0
BAZELISK_GITHUB_TOKEN=your_github_token
BAZELISK_CLEAN=true
BAZELISK_SHUTDOWN=true
```

## Integration with Swift Package Manager

friendly-outlaw supports both Bazel and SPM. The project maintains:

- **Package.swift** - Swift Package Manager configuration
- **WORKSPACE** and **BUILD** files - Bazel configuration

This allows you to choose your preferred build system:

```bash
# Using SPM (traditional)
swift build
swift test
swift run WritersAppCLI

# Using Bazel/Bazelisk (alternative)
bazel build //...
bazel test //...
bazel run //Sources/WritersAppCLI:WritersAppCLI
```

## Troubleshooting

### Bazelisk not found

Ensure Bazelisk is in your PATH:

```bash
which bazel
which bazelisk
```

If not installed, follow the Installation section above.

### Version download fails

Bazelisk caches downloaded versions. Try clearing the cache:

```bash
# Check cache location
bazel info output_base

# Clear cache on macOS
rm -rf ~/.bazelisk

# Clear cache on Linux
rm -rf ~/.cache/bazelisk
```

### Build failures with different versions

If you encounter version-specific issues:

1. Check the `.bazelversion` file matches your environment
2. Use `bazel clean` to remove stale build artifacts
3. Try the `--migrate` flag to identify incompatible features
4. Check the Bazel release notes for breaking changes

### Network issues

If Bazelisk cannot download Bazel:

1. Check your internet connection
2. Verify firewall/proxy settings
3. Set `BAZELISK_GITHUB_TOKEN` if on a shared network (prevents rate limiting)
4. Use a custom mirror with `BAZELISK_BASE_URL`

## Advanced Configuration

### Custom Download URL

```bash
export BAZELISK_BASE_URL="https://custom-mirror.example.com/bazel"
bazel build //...
```

### Verify Downloaded Binaries

```bash
export BAZELISK_VERIFY_SHA256="abc123..."
bazel build //...
```

### User Agent

```bash
export BAZELISK_USER_AGENT="MyCompany/1.0"
bazel build //...
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Build with Bazel

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Bazelisk
        run: |
          wget https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-linux-x86_64
          chmod +x bazelisk-linux-x86_64
          sudo mv bazelisk-linux-x86_64 /usr/local/bin/bazel
      - name: Build
        run: bazel build //...
      - name: Test
        run: bazel test //...
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Using mise (Polyglot Version Manager)

```bash
mise use -g bazelisk@latest
bazel build //...
```

## References

- [Bazelisk GitHub Repository](https://github.com/bazelbuild/bazelisk)
- [Bazel Official Documentation](https://bazel.build/start)
- [Bazel Rules for Swift](https://github.com/bazelbuild/rules_swift)
- [friendly-outlaw Swift Documentation](./CLAUDE.md)

## Questions?

For issues specific to Bazelisk, see the [Bazelisk FAQ](https://github.com/bazelbuild/bazelisk#faq).

For friendly-outlaw development questions, see [CLAUDE.md](./CLAUDE.md) and [DEVELOPMENT.md](./DEVELOPMENT.md).
