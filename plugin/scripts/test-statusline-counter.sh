#!/bin/bash
# Test script for StatuslineCounter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Testing StatuslineCounter..."
echo "========================================"
echo

# Build if needed
echo "Building StatuslineCounter..."
cd "$PROJECT_ROOT"
swift build > /dev/null 2>&1
echo "✓ Build successful"
echo

# Test 1: With current project
echo "Test 1: Current project"
echo "Command: StatuslineCounter '$PROJECT_ROOT'"
OUTPUT=$("$PROJECT_ROOT/.build/debug/StatuslineCounter" "$PROJECT_ROOT")
echo "Output: $OUTPUT"
echo "✓ Test passed"
echo

# Test 2: With non-existent project
echo "Test 2: Non-existent project"
echo "Command: StatuslineCounter '/tmp/nonexistent'"
OUTPUT=$("$PROJECT_ROOT/.build/debug/StatuslineCounter" "/tmp/nonexistent")
echo "Output: $OUTPUT"
if [[ "$OUTPUT" == *'"sessions":0'* ]] && [[ "$OUTPUT" == *'"suggestions":0'* ]]; then
    echo "✓ Test passed (returns zeros gracefully)"
else
    echo "✗ Test failed"
    exit 1
fi
echo

# Test 3: No arguments
echo "Test 3: No arguments (should return empty project)"
echo "Command: StatuslineCounter"
OUTPUT=$("$PROJECT_ROOT/.build/debug/StatuslineCounter")
echo "Output: $OUTPUT"
if [[ "$OUTPUT" == *'"sessions":0'* ]] && [[ "$OUTPUT" == *'"suggestions":0'* ]]; then
    echo "✓ Test passed (returns zeros gracefully)"
else
    echo "✗ Test failed"
    exit 1
fi
echo

# Test 4: JSON validity
echo "Test 4: JSON validity"
OUTPUT=$("$PROJECT_ROOT/.build/debug/StatuslineCounter" "$PROJECT_ROOT")
echo "$OUTPUT" | python3 -m json.tool > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Test passed (valid JSON)"
else
    echo "✗ Test failed (invalid JSON)"
    exit 1
fi
echo

# Test 5: Using the wrapper script
echo "Test 5: Wrapper script"
echo "Command: ./plugin/scripts/statusline-counts.sh '$PROJECT_ROOT'"
OUTPUT=$("$SCRIPT_DIR/statusline-counts.sh" "$PROJECT_ROOT")
echo "Output: $OUTPUT"
echo "✓ Test passed"
echo

echo "========================================"
echo "All tests passed! ✓"
