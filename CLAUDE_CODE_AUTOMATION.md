# Claude Code Automation Setup Guide

Automate development workflows, testing, and AI features.

## 1. Automated Testing Loop

Run tests every 5 minutes during development:

```bash
/loop 5m swift test
```

Or set up in `.claude/settings.json`:
```json
{
  "hooks": {
    "post-edit": "swift test"
  }
}
```

## 2. Scheduled Test Suite (Daily)

Run comprehensive tests on a schedule:

```bash
/schedule "0 2 * * *" swift test --verbose
```

This runs daily at 2 AM.

## 3. Automated Build & Deploy

Set up CI/CD-like automation:

```json
{
  "hooks": {
    "pre-push": "swift build -c release && swift test"
  }
}
```

## 4. AI Feature Development Workflow

Use subagents for parallel work:

```bash
# Start a feature build
/loop 10m "swift-code-reviewer _on_ Sources/WritersApp/Services/AIService.swift"

# Continuous integration
/schedule "*/30 * * * *" "swift-debugger _on_ recent_errors"
```

## 5. GitHub PR Monitoring

Watch PR activity and auto-respond:

```swift
// In your subagent or Claude Code session:
mcp__github__subscribe_pr_activity(
    owner: "paulthanson082-glitch",
    repo: "friendly-outlaw",
    pullNumber: 123
)
```

## 6. Automated Knowledge Checks

Before each commit, check standards:

```json
{
  "hooks": {
    "pre-commit": "knowledge-advisor _check_ Sources/WritersApp"
  }
}
```

## 7. Scheduled AI Feature Testing

Test AI integrations on schedule:

```bash
/schedule "0 8 * * MON" "
  export ANTHROPIC_API_KEY=\$ANTHROPIC_API_KEY
  swift test WritersAppTests.AIServiceTests
"
```

## 8. Database Migration Automation

Auto-run migrations:

```json
{
  "hooks": {
    "post-checkout": "swift run WritersAppCLI --migrate"
  }
}
```

## 9. Plugin Health Check

Verify plugins are working:

```bash
/loop 1h "swift run WritersAppCLI --check-plugins"
```

## 10. Analytics Reporting

Generate reports on schedule:

```bash
/schedule "0 9 * * FRI" "
  swift run WritersAppCLI --export-analytics > /tmp/weekly_report.json
"
```

---

## Advanced: Multi-Step Automation

### Weekly Workflow Example
```bash
# Every Monday at 8 AM:
/schedule "0 8 * * MON" '
  echo "📊 Starting weekly automation..."

  # 1. Run all tests
  swift test

  # 2. Check code quality
  /simplify Sources/WritersApp

  # 3. Update dependencies
  swift package update

  # 4. Build release
  swift build -c release

  # 5. Run integrations
  ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY swift test WritersAppTests.AIServiceTests

  # 6. Report status
  echo "✅ Weekly automation complete"
'
```

---

## Live Monitoring Setups

### Option A: Poll Status Every 10 Minutes
```bash
/loop 10m "gh run view <workflow_id>"
```

### Option B: Watch PR for Changes
```bash
# Subscribe to PR activity (auto-monitors)
mcp__github__subscribe_pr_activity(
    owner: "paulthanson082-glitch",
    repo: "friendly-outlaw",
    pullNumber: 123
)

# Claude Code will notify when comments/CI changes occur
```

### Option C: Monitor Build Failures
```bash
/loop 5m '
  LATEST_RUN=$(gh run list --limit 1 --json databaseId)
  gh run view $LATEST_RUN --json status
'
```

---

## Development Automation Examples

### 1. Auto-Test on File Change
```json
{
  "hooks": {
    "post-edit": "swift test --filter Tests/WritersAppTests"
  }
}
```

### 2. Auto-Format Before Commit
```json
{
  "hooks": {
    "pre-commit": "swift-code-reviewer /check && /simplify"
  }
}
```

### 3. Auto-Document New Functions
```json
{
  "hooks": {
    "post-edit": "knowledge-advisor _comment_ Sources/WritersApp"
  }
}
```

### 4. Continuous Security Checks
```bash
/loop 1h "mcp__github__run_secret_scanning"
```

---

## Pro Tips for Automation

### Use Environment Variables
```bash
export WRITERS_APP_DB_PATH=":memory:"      # Test with in-memory DB
export ANTHROPIC_API_KEY="sk-ant-..."      # Auto-load API key
export RUST_LOG="debug"                     # Debug logging
```

### Combine Tools
```bash
# Test + Review + Commit
/loop 30m "
  swift test && \
  swift-code-reviewer && \
  git add -A && \
  git commit -m 'Auto-commit: passing tests'
"
```

### Set Up Alerts
```bash
/loop 5m '
  if ! swift test; then
    echo "⚠️  TESTS FAILED" | mail -s "Build Alert" you@example.com
  fi
'
```

### Monitor AI Features
```bash
/schedule "0 9 * * *" '
  # Daily AI feature health check
  ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  swift run WritersAppCLI --health-check
'
```

---

## Keyboard Shortcuts for Quick Automation

Add to `~/.claude/keybindings.json`:
```json
{
  "ctrl+shift+t": "/loop 5m swift test",
  "ctrl+shift+b": "swift build -c release",
  "ctrl+shift+l": "/loop 1h gh run list",
  "ctrl+shift+r": "knowledge-advisor _check_"
}
```

---

## Real-World Workflow

### Example: "Deploy-Ready" Automation
```bash
# Run this before deploying to production
/loop 1m '
  echo "🔍 Running pre-deploy checks..."

  # 1. Tests must pass
  swift test || exit 1

  # 2. No security issues
  mcp__github__run_secret_scanning || exit 1

  # 3. Code quality checks
  /simplify Sources/ || exit 1

  # 4. Build release binary
  swift build -c release || exit 1

  # 5. Run integration tests
  ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY swift test WritersAppTests.AIServiceTests || exit 1

  echo "✅ Ready for deployment!"
'
```

---

## Troubleshooting Automation

### Issue: Loop runs but doesn't update
**Solution:** Add explicit output flush
```bash
/loop 5m "swift test 2>&1"
```

### Issue: Environment variables not available
**Solution:** Export them explicitly
```bash
/loop 5m "export ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY && swift test"
```

### Issue: Too many notifications
**Solution:** Reduce loop frequency
```bash
/loop 30m "swift test"  # Instead of /loop 5m
```

---

## Next Steps

1. **Enable the SessionStart hook** — Auto-setup on session start
2. **Set up /loop for your workflow** — Real-time feedback
3. **Use /schedule for background tasks** — Non-blocking automation
4. **Monitor with PR subscriptions** — Auto-respond to reviews

👉 **Ready to set up? Run:**
```bash
/update-config  # Interactive config setup
```
