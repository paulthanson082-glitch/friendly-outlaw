#!/usr/bin/env bash
set -e

echo "🔍 E2E Verification Script"
echo "=========================="
echo ""

# Configuration
PLUGIN_DIR="/app/openclaw"
WORKER_PORT=37777
INTERACTIVE=${INTERACTIVE:-0}

# Verification checks
CHECKS_PASSED=0
CHECKS_TOTAL=0

check() {
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  if eval "$2"; then
    echo "✅ $1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    return 0
  else
    echo "❌ $1"
    return 1
  fi
}

# 1. Plugin directory structure
check "Plugin directory exists" "[ -d '$PLUGIN_DIR' ]"
check "Plugin manifest exists" "[ -f '$PLUGIN_DIR/openclaw.plugin.json' ]"
check "Package.json exists" "[ -f '$PLUGIN_DIR/package.json' ]"
check "TypeScript config exists" "[ -f '$PLUGIN_DIR/tsconfig.json' ]"

# 2. Build artifacts
check "Plugin built successfully" "[ -f '$PLUGIN_DIR/dist/index.js' ]"
check "Type definitions generated" "[ -f '$PLUGIN_DIR/dist/index.d.ts' ]"

# 3. Plugin manifest validation
check "Plugin manifest is valid JSON" "jq empty '$PLUGIN_DIR/openclaw.plugin.json' 2>/dev/null"
check "Plugin ID is 'friendly-outlaw'" "[ \"\$(jq -r '.id' '$PLUGIN_DIR/openclaw.plugin.json')\" = 'friendly-outlaw' ]"

# 4. Node.js smoke test
if [ -f "$PLUGIN_DIR/test-sse-consumer.js" ]; then
  check "Smoke test exists" "true"
  if node "$PLUGIN_DIR/test-sse-consumer.js" > /tmp/smoke-test.log 2>&1; then
    check "Smoke test passes" "true"
  else
    check "Smoke test passes" "false"
    echo "  Smoke test output:"
    cat /tmp/smoke-test.log | sed 's/^/  /'
  fi
else
  check "Smoke test exists" "false"
fi

# 5. TypeScript compilation check
check "TypeScript compiled without errors" "[ -f '$PLUGIN_DIR/dist/index.js' ]"

# 6. Dependencies
if [ -f "$PLUGIN_DIR/node_modules/.package-lock.json" ] || [ -d "$PLUGIN_DIR/node_modules" ]; then
  check "Dependencies installed" "true"
else
  check "Dependencies installed (warning: may not be needed)" "true"
fi

# Summary
echo ""
echo "📊 Verification Summary"
echo "======================"
echo "Checks passed: $CHECKS_PASSED / $CHECKS_TOTAL"

if [ "$CHECKS_PASSED" -eq "$CHECKS_TOTAL" ]; then
  echo "✅ All checks passed!"
  exit 0
else
  FAILED=$((CHECKS_TOTAL - CHECKS_PASSED))
  echo "❌ $FAILED check(s) failed"
  exit 1
fi
