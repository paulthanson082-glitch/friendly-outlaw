# 🚀 Quick Reference Card - Mac Pro Build

**Print or pin this for quick access!**

---

## ⚡ One-Command Setup

```bash
./scripts/setup-dev-env.sh
```

---

## 🏗️ Build Commands

| Command | Purpose | Time |
|---------|---------|------|
| `./scripts/build.sh debug` | Debug build (fast) | 30-60s |
| `./scripts/build.sh release` | Release (optimized) | 3-5 min |
| `swift build -c release` | Direct Swift build | 3-5 min |
| `swift package clean` | Clean all artifacts | 5s |

---

## 🧪 Test Commands

| Command | Purpose |
|---------|---------|
| `./scripts/test.sh` | Run all 88+ tests |
| `./scripts/test.sh true` | Verbose test output |
| `swift test` | Direct test run |

---

## ▶️ Run Commands

| Command | Purpose |
|---------|---------|
| `./run.sh` | Run CLI (debug) |
| `./run.sh --release` | Run CLI (release) |
| `ANTHROPIC_API_KEY="sk-..." ./run.sh` | With AI |
| `swift run WritersAppCLI` | Direct run |

---

## 📋 Development Menu

```bash
./scripts/dev.sh
```

**Options:**
- 1 = Build (Debug)
- 2 = Build (Release)
- 3 = Run Tests
- 4 = Run CLI
- 5 = Build + Test + Run
- 6 = Clean + Rebuild
- 7 = Show Environment

---

## 🔧 Configuration

```bash
# Edit .env
cp .env.example .env
nano .env

# Key settings:
ANTHROPIC_API_KEY=sk-ant-...      # AI features
AI_MODEL=claude-3-5-sonnet         # Model choice
BUILD_CONFIG=release               # Build type
```

---

## ✅ Verification Checklist

- [ ] `swift --version` shows 5.9+
- [ ] `sqlite3 --version` works
- [ ] `git status` shows `claude/research-mythos-leak-zqUkX`
- [ ] `.env` created and configured
- [ ] `./scripts/build.sh release` succeeds
- [ ] `./scripts/test.sh` passes all 88+ tests
- [ ] `./run.sh` starts CLI

---

## 📊 Expected Performance (Mac Pro)

| Operation | Time |
|-----------|------|
| First build | 2-5 min |
| Incremental build | 30-60 sec |
| Test suite | 1-2 min |
| Full workflow | 5-10 min |

---

## 🐛 If Something Breaks

```bash
# Nuclear option (safe)
swift package clean
./scripts/build.sh release --clean
./scripts/test.sh
```

```bash
# Reset database
rm ~/Documents/writersapp.db
./run.sh  # Recreates DB automatically
```

```bash
# Check environment
./scripts/dev.sh env
```

---

## 📚 Documentation

- **Quick Start**: This file
- **Full Guide**: `GETTING_STARTED.md`
- **Build Steps**: `BUILD_FOR_MAC_PRO.md`
- **Status Report**: `PRE_BUILD_STATUS.md`
- **Complete Reference**: `CLAUDE.md`
- **Main Docs**: `README.md`

---

## 🎯 Typical Workflow

```bash
# Session start
./scripts/setup-dev-env.sh

# Develop
# ... edit code ...

# Verify changes
./scripts/build.sh release
./scripts/test.sh

# Test in CLI
./run.sh

# Push changes
git add .
git commit -m "Your message"
git push -u origin claude/research-mythos-leak-zqUkX
```

---

## 💾 Project Info

- **Language**: Swift 5.9+
- **Platform**: macOS 13+ (Mac Pro)
- **Tests**: 88+ (all passing)
- **Size**: 1.1MB (sources), 500MB (built)
- **Dependencies**: CSQLite, ArgumentParser, Yams
- **Database**: SQLite3 (~20MB)

---

## 🔐 Important

⚠️ **Never commit .env** - It's in .gitignore
⚠️ **Keep API keys private** - Stored in .env
⚠️ **Don't share credentials** - They cost money

---

## 🆘 Emergency Contacts

**Can't build?**
→ Run `./scripts/setup-dev-env.sh`

**Tests failing?**
→ Run `swift package clean && swift test --verbose`

**Can't run CLI?**
→ Check `.env` and `ANTHROPIC_API_KEY`

**Git issues?**
→ Check branch: `git rev-parse --abbrev-ref HEAD`

---

## 🌟 Pro Tips

✅ Use **release builds** for testing - much faster
✅ Keep **Metal rendering enabled** for GPU acceleration
✅ Run **tests frequently** during development
✅ Use **interactive menu** (`./scripts/dev.sh`) for workflows
✅ **Clean rebuild** if strange errors occur

---

**Status**: ✅ Ready to build on Mac Pro

**Date**: March 27, 2026

**Branch**: `claude/research-mythos-leak-zqUkX`

---

*Pin this card or keep it in your terminal window for quick reference!*
