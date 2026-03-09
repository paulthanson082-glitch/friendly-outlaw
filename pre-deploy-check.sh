#!/bin/bash
set -e

# Pre-deployment checklist script
# Verifies everything is ready for production deployment

COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

print_header() {
    echo -e "\n${COLOR_BLUE}===================================${NC}"
    echo -e "${COLOR_BLUE}$1${NC}"
    echo -e "${COLOR_BLUE}===================================${NC}\n"
}

check_pass() {
    echo -e "${COLOR_GREEN}✓ $1${NC}"
    ((PASSED++))
}

check_fail() {
    echo -e "${COLOR_RED}✗ $1${NC}"
    ((FAILED++))
}

check_warn() {
    echo -e "${COLOR_YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

# Start checks
print_header "PRE-DEPLOYMENT VERIFICATION"

# 1. Git Status
print_header "GIT REPOSITORY"

if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    check_pass "Git repository initialized"
else
    check_fail "Not a git repository"
fi

if [ -z "$(git status --porcelain)" ]; then
    check_pass "All changes committed"
else
    check_warn "Uncommitted changes exist"
    git status --short
fi

if git rev-parse origin main > /dev/null 2>&1; then
    if [ "$(git rev-parse main)" = "$(git rev-parse origin/main)" ]; then
        check_pass "Local main branch in sync with remote"
    else
        check_warn "Local main branch is behind remote"
    fi
else
    check_warn "No remote 'origin' configured"
fi

# 2. Dependencies
print_header "DEPENDENCIES"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    if [[ $NODE_VERSION =~ v([0-9]+) ]] && [ "${BASH_REMATCH[1]}" -ge 18 ]; then
        check_pass "Node.js $NODE_VERSION installed (18+)"
    else
        check_fail "Node.js version too old: $NODE_VERSION (need 18+)"
    fi
else
    check_fail "Node.js not installed"
fi

if command -v npm &> /dev/null; then
    check_pass "npm $(npm --version) installed"
else
    check_fail "npm not installed"
fi

if command -v docker &> /dev/null; then
    check_pass "Docker $(docker --version | cut -d' ' -f3) installed"
else
    check_warn "Docker not installed (needed for production)"
fi

# 3. Backend
print_header "BACKEND"

if [ -f "backend/package.json" ]; then
    check_pass "backend/package.json exists"

    if [ -d "backend/node_modules" ]; then
        check_pass "Backend dependencies installed"
    else
        check_warn "Backend dependencies not installed (run: cd backend && npm install)"
    fi

    if grep -q "\"build\":" backend/package.json; then
        check_pass "Build script configured"
    else
        check_fail "No build script in backend/package.json"
    fi
else
    check_fail "backend/package.json not found"
fi

if [ -f "backend/.env" ]; then
    check_pass "backend/.env file exists"

    if grep -q "ANTHROPIC_API_KEY" backend/.env; then
        check_warn "ANTHROPIC_API_KEY set (verify it's not a default/test key)"
    else
        check_warn "ANTHROPIC_API_KEY not configured (AI features will be disabled)"
    fi

    if grep -q "JWT_SECRET" backend/.env; then
        JWT_SECRET=$(grep "JWT_SECRET" backend/.env | cut -d'=' -f2)
        if [ ${#JWT_SECRET} -lt 32 ]; then
            check_fail "JWT_SECRET too short (should be 32+ characters)"
        else
            check_pass "JWT_SECRET configured (32+ chars)"
        fi
    else
        check_fail "JWT_SECRET not configured"
    fi
else
    check_fail "backend/.env not found (copy from .env.example)"
fi

# 4. Frontend
print_header "FRONTEND"

if [ -f "frontend/package.json" ]; then
    check_pass "frontend/package.json exists"

    if [ -d "frontend/node_modules" ]; then
        check_pass "Frontend dependencies installed"
    else
        check_warn "Frontend dependencies not installed (run: cd frontend && npm install)"
    fi

    if grep -q "\"build\":" frontend/package.json; then
        check_pass "Build script configured"
    else
        check_fail "No build script in frontend/package.json"
    fi
else
    check_fail "frontend/package.json not found"
fi

if [ -d "frontend/dist" ]; then
    check_pass "Frontend dist directory exists"
else
    check_warn "Frontend dist not built (run: cd frontend && npm run build)"
fi

# 5. Mobile
print_header "MOBILE APP"

if [ -f "mobile/app.json" ]; then
    check_pass "mobile/app.json exists"

    if [ -d "mobile/node_modules" ]; then
        check_pass "Mobile dependencies installed"
    else
        check_warn "Mobile dependencies not installed (run: cd mobile && npm install)"
    fi

    if grep -q "version" mobile/app.json; then
        VERSION=$(grep '"version"' mobile/app.json | head -1 | cut -d'"' -f4)
        check_pass "Mobile app version: $VERSION"
    else
        check_fail "No version in mobile/app.json"
    fi
else
    check_warn "mobile/app.json not found (mobile not configured)"
fi

# 6. Docker
print_header "DOCKER"

if [ -f "Dockerfile" ]; then
    check_pass "Dockerfile exists"

    if grep -q "FROM node" Dockerfile; then
        check_pass "Dockerfile configured for Node.js"
    else
        check_fail "Dockerfile doesn't seem to use Node.js"
    fi
else
    check_fail "Dockerfile not found"
fi

if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml exists"

    if docker-compose config > /dev/null 2>&1; then
        check_pass "docker-compose.yml is valid"
    else
        check_fail "docker-compose.yml has syntax errors"
    fi
else
    check_fail "docker-compose.yml not found"
fi

# 7. Configuration
print_header "CONFIGURATION"

if [ -f "CLAUDE.md" ]; then
    check_pass "CLAUDE.md (project standards) exists"
else
    check_warn "CLAUDE.md not found"
fi

if [ -f "README.md" ]; then
    check_pass "README.md exists"
else
    check_fail "README.md not found"
fi

if [ -f "DEPLOYMENT.md" ]; then
    check_pass "DEPLOYMENT.md (deployment guide) exists"
else
    check_warn "DEPLOYMENT.md not found"
fi

if [ -f ".github/workflows/ci.yml" ]; then
    check_pass "GitHub Actions CI/CD configured"
else
    check_warn "GitHub Actions CI/CD not configured"
fi

# 8. Security
print_header "SECURITY"

if [ -f ".gitignore" ]; then
    check_pass ".gitignore exists"

    if grep -q ".env" .gitignore; then
        check_pass ".env files are gitignored"
    else
        check_fail ".env files are NOT gitignored (security risk!)"
    fi
else
    check_fail ".gitignore not found"
fi

if grep -r "sk-ant-" . --exclude-dir=node_modules --exclude-dir=dist > /dev/null 2>&1; then
    check_fail "Anthropic API key found in code (remove immediately!)"
else
    check_pass "No hardcoded API keys found"
fi

# 9. Database
print_header "DATABASE"

if [ -f "backend/data/app.db" ]; then
    check_pass "SQLite database exists"
    SIZE=$(du -h backend/data/app.db | cut -f1)
    check_pass "Database size: $SIZE"
else
    check_warn "Database not created yet (will be created on first run)"
fi

# 10. Tests
print_header "TESTS"

if [ -f "backend/src/__tests__" ] || [ -f "backend/tests" ]; then
    check_pass "Backend tests directory exists"
else
    check_warn "No backend tests found"
fi

if [ -f "frontend/src/__tests__" ] || [ -f "frontend/tests" ]; then
    check_pass "Frontend tests directory exists"
else
    check_warn "No frontend tests found"
fi

# Summary
print_header "SUMMARY"

TOTAL=$((PASSED + FAILED + WARNINGS))
echo "Total checks: $TOTAL"
echo -e "${COLOR_GREEN}Passed: $PASSED${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${COLOR_YELLOW}Warnings: $WARNINGS${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${COLOR_RED}Failed: $FAILED${NC}"
fi

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${COLOR_GREEN}✓ Ready for deployment!${NC}"
    exit 0
else
    echo -e "${COLOR_RED}✗ Fix $FAILED issue(s) before deploying${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Fix failed checks above"
    echo "2. Run this script again: ./pre-deploy-check.sh"
    echo "3. Deploy: ./deploy.sh"
    exit 1
fi
