# ⚠️ DANGEROUS MODE - Skip All Permission Checks

This guide explains how to disable safety checks and permission approvals for local development.

## ⚠️ WARNING

**Do NOT use in production.** These configurations:
- Skip git hooks (pre-commit validation)
- Disable file permission checks
- Skip command execution approvals
- Disable safety sandboxes
- Allow unrestricted code changes

**Use only for local development on your own machine.**

---

## 1. Skip Git Hooks (Pre-commit)

When committing, bypass git hooks:

```bash
# Skip all hooks for a single commit
git commit --no-verify -m "Your message"

# Or set globally (NOT RECOMMENDED)
git config --global core.hooksPath ""
```

---

## 2. Skip File Permission Checks

To allow direct file modifications without approval in scripts:

```bash
# Use Bash with dangerouslyDisableSandbox parameter
# In your code/scripts, you can now modify files without prompts
```

---

## 3. Enable Dangerous Development Mode

Create or modify `.env` for dangerous mode:

```bash
# .env (DO NOT COMMIT THIS FILE)
DANGEROUS_MODE=true
SKIP_GIT_HOOKS=true
SKIP_FILE_CHECKS=true
SKIP_PERMISSION_CHECKS=true
ANTHROPIC_API_KEY="sk-ant-..."
```

Load before running:

```bash
# Load dangerous mode
export DANGEROUS_MODE=true
export SKIP_GIT_HOOKS=true
export SKIP_FILE_CHECKS=true

# Run the app
swift run WritersAppCLI
```

---

## 4. Modify Git Configuration for Development

For your local repository only:

```bash
# Allow direct commits without hooks
git config core.hooksPath ""

# Or disable specific hooks
chmod -x .git/hooks/pre-commit
chmod -x .git/hooks/commit-msg
```

**Restore hooks later:**
```bash
git config core.hooksPath ".git/hooks"
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/commit-msg
```

---

## 5. Use Git Alias to Skip Verification

Create a shortcut for bypassing checks:

```bash
# Add to ~/.gitconfig or local git config
[alias]
    yolo = commit --no-verify
    force-push-yolo = push --force-with-lease

# Then use:
git yolo -m "My message"
git force-push-yolo
```

---

## 6. Quick Development Setup

For rapid iteration with no safety checks:

```bash
#!/bin/bash
# save as: dev-mode.sh

# Skip all verifications
export DANGEROUS_MODE=true
export SKIP_GIT_HOOKS=true
export SKIP_FILE_CHECKS=true
export SKIP_PERMISSION_CHECKS=true
export ANTHROPIC_API_KEY="sk-ant-..."

# Make git commands faster
git config core.hooksPath ""

# Run app
swift run WritersAppCLI
```

Run with:
```bash
bash dev-mode.sh
```

---

## 7. Jules with Adult Mode + Dangerous Mode

Maximum permissiveness setup:

```bash
#!/bin/bash
# Ultimate development mode

# Set dangerous flags
export DANGEROUS_MODE=true
export SKIP_ALL_CHECKS=true
export ANTHROPIC_API_KEY="sk-ant-..."

# Run app
swift run WritersAppCLI

# At menu:
# Option 18: Enable Jules Adult Mode
# Option 17: Chat with Jules (no content restrictions)
```

---

## 8. What Gets Skipped

| Item | Default | Dangerous | Effect |
|------|---------|-----------|--------|
| Git hooks | Active | Skipped | Can commit without linting/validation |
| File approval | Required | Skipped | Can modify files without prompt |
| Command approval | Required | Skipped | Bash commands run immediately |
| Permission checks | Enforced | Skipped | No sandbox restrictions |
| Content filters | Active | Inactive | No content restrictions |
| Jules filter | Active | Inactive | Jules can use profanity/adult content |

---

## 9. Reverting Dangerous Mode

Return to safe defaults:

```bash
# Unset environment variables
unset DANGEROUS_MODE
unset SKIP_GIT_HOOKS
unset SKIP_FILE_CHECKS
unset SKIP_PERMISSION_CHECKS

# Restore git hooks
git config core.hooksPath ".git/hooks"

# Disable Jules adult mode (at menu option 18)
```

---

## 10. Quick Reference Commands

```bash
# Skip hooks on this commit only
git commit --no-verify -m "message"

# Skip hooks on this push
git push --no-verify

# Bypass all checks (dangerous!)
export DANGEROUS_MODE=true && swift run WritersAppCLI

# Check current git hook status
git config core.hooksPath

# List disabled hooks
ls -la .git/hooks | grep -v +x
```

---

## 11. Using with Claude Code

If you have Claude Code running locally:

```bash
# In Claude Code terminal, set:
export DANGEROUS_MODE=true
export SKIP_FILE_CHECKS=true

# Then all file operations won't ask for approval
```

---

## 12. Safety Checklist Before Committing

Even in dangerous mode, check before pushing:

- [ ] Did you mean to modify these files?
- [ ] Are secrets/API keys included? (Check with: `git diff HEAD`)
- [ ] Is this ready for the feature branch?
- [ ] Should you revert dangerous flags before committing?

Check what will be committed:
```bash
git diff --cached
```

---

## 13. Dangerous Mode with Adult Jules

Full setup for maximum flexibility:

```bash
# Set all permissions
export DANGEROUS_MODE=true
export SKIP_GIT_HOOKS=true
export SKIP_FILE_CHECKS=true
export SKIP_PERMISSION_CHECKS=true
export ANTHROPIC_API_KEY="sk-ant-..."

# Disable git hooks
git config core.hooksPath ""

# Run
swift run WritersAppCLI

# At menu:
# 18: Enable Jules Adult Mode
# 17: Chat with Jules (no restrictions on language/topics)

# Jules can now:
# ✓ Use curse words and profanity
# ✓ Discuss adult topics (sex, violence, crime, etc.)
# ✓ Write edgy, mature fiction
# ✓ Use colorful language authentically
# ✓ Handle complex moral situations
```

---

## Important Notes

### Git Safety
- `--no-verify` bypasses hooks **once**
- `--force-with-lease` is safer than `--force`
- Always review `git diff` before committing
- Never push to protected branches with `--force`

### File Safety
- Even in dangerous mode, files are still tracked
- You can't accidentally delete tracked files
- Untracked files still require explicit handling

### Jules Adult Mode
- Only affects conversation with Jules
- Doesn't change other app functionality
- Persists until you toggle option 18 again
- Can be toggled any time

### Environment Variables
- Set in shell session (temporary)
- Or in `.env` file (persistent for session)
- **Do not commit .env with sensitive data**

---

## Disabling Dangerous Mode

To completely remove dangerous overrides:

```bash
# 1. Kill current session
^C

# 2. Unset all variables
unset DANGEROUS_MODE
unset SKIP_GIT_HOOKS
unset SKIP_FILE_CHECKS
unset SKIP_PERMISSION_CHECKS

# 3. Restore git hooks
git config core.hooksPath ".git/hooks"

# 4. Disable Jules adult mode (option 18)

# 5. Run normally
swift run WritersAppCLI
```

---

**You now have maximum freedom for local development. Use responsibly! 🚀**

Remember: Dangerous mode is for YOUR development machine only. Never commit while in dangerous mode on shared branches.
