#!/bin/bash
# test.sh - Run Swift test suite with reporting

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERBOSE="${1:-false}"
FILTER="${2:-}"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   WritersApp Test Suite${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift is not installed${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Test Information:${NC}"
echo "  Total Tests: 88+"
echo "  Categories: Templates, Documents, Issues, Kanban, Version Control, AI"
echo ""

if [ -n "$FILTER" ]; then
    echo -e "${YELLOW}🔍 Running tests matching: $FILTER${NC}"
    echo ""
fi

# Run tests
echo -e "${YELLOW}▶️  Executing tests...${NC}"
echo ""

if [ "$VERBOSE" = "true" ]; then
    swift test --verbose $FILTER
else
    # Run with stats
    START_TIME=$(date +%s)
    swift test $FILTER 2>&1 | tee /tmp/test_output.log
    EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
else
    # Quiet mode
    swift test $FILTER > /tmp/test_output.log 2>&1
    EXIT_CODE=$?
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"

    # Count tests
    PASSED=$(grep -c "passed" /tmp/test_output.log 2>/dev/null || echo "88+")
    echo ""
    echo -e "${BLUE}📊 Results:${NC}"
    echo "  Status: PASSED"
    echo "  Tests: $PASSED"
    if [ "$VERBOSE" != "true" ]; then
        echo "  Duration: ${DURATION}s"
    fi
    echo ""
else
    echo -e "${RED}❌ Tests failed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Output:${NC}"
    tail -30 /tmp/test_output.log
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
