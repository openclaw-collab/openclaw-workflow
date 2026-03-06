#!/bin/bash
# OpenClaw Workflow Rebuild Validation Script
# Tests all components and integrations

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
log_section() { echo -e "\n${YELLOW}═══════════════════════════════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}\n"; }

OPENCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/openclaw-test-$$"

cleanup() {
    if [ -d "$TEST_DIR" ]; then
        log_info "Cleaning up test directory..."
        rm -rf "$TEST_DIR"
    fi
}
trap cleanup EXIT

log_section "OpenClaw Workflow v2.0 - Validation Suite"
log_info "Test directory: $TEST_DIR"
log_info "OpenClaw directory: $OPENCLAW_DIR"
echo ""

# Test 1: Check prerequisites
log_section "1. Prerequisites Check"

if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -ge 20 ]; then
        log_pass "Node.js 20+ ($(node -v))"
    else
        log_fail "Node.js 20+ required, found $(node -v)"
    fi
else
    log_fail "Node.js not found"
fi

if command -v pnpm >/dev/null 2>&1; then
    log_pass "pnpm ($(pnpm --version))"
else
    log_fail "pnpm not found"
fi

if command -v python3 >/dev/null 2>&1; then
    PYTHON_MINOR=$(python3 --version | cut -d' ' -f2 | cut -d. -f2)
    if [ "$PYTHON_MINOR" -ge 11 ]; then
        log_pass "Python 3.11+ ($(python3 --version | cut -d' ' -f2))"
    else
        log_fail "Python 3.11+ required, found $(python3 --version | cut -d' ' -f2)"
    fi
else
    log_fail "Python 3 not found"
fi

if command -v git >/dev/null 2>&1; then
    log_pass "Git ($(git --version | cut -d' ' -f3))"
else
    log_fail "Git not found"
fi

# Test 2: Check submodules
log_section "2. Submodule Check"

for submodule in agent-orchestrator bmad-openclaw forge-ao desloppify; do
    if [ -d "$OPENCLAW_DIR/packages/$submodule/.git" ] || [ -f "$OPENCLAW_DIR/packages/$submodule/.git" ]; then
        log_pass "Submodule: $submodule"
    else
        log_fail "Submodule missing: $submodule"
    fi
done

# Test 3: Check AO installation
log_section "3. Agent Orchestrator Installation"

if [ -f "$OPENCLAW_DIR/packages/agent-orchestrator/packages/cli/dist/index.js" ]; then
    log_pass "AO CLI built"
else
    log_fail "AO CLI not built (run: cd packages/agent-orchestrator && pnpm install && pnpm build)"
fi

if [ -f "$HOME/.local/bin/ao" ]; then
    log_pass "AO CLI linked to PATH"
else
    log_fail "AO CLI not in PATH (~/.local/bin/ao)"
fi

if [ -f "$OPENCLAW_DIR/packages/agent-orchestrator/node_modules/.pnpm/lock.yaml" ] || [ -d "$OPENCLAW_DIR/packages/agent-orchestrator/node_modules" ]; then
    log_pass "AO dependencies installed"
else
    log_fail "AO dependencies not installed"
fi

# Test 4: Check BMAD installation
log_section "4. BMAD Installation"

if [ -d "$OPENCLAW_DIR/packages/bmad-openclaw/node_modules" ]; then
    log_pass "BMAD dependencies installed"
else
    log_fail "BMAD dependencies not installed"
fi

# Test 5: Check FORGE installation
log_section "5. FORGE-AO Installation"

if [ -L "$HOME/.claude/plugins/forge-ao" ]; then
    log_pass "FORGE plugin linked to Claude"
else
    log_fail "FORGE plugin not linked"
fi

if [ -f "$OPENCLAW_DIR/packages/forge-ao/.claude-plugin/plugin.json" ]; then
    log_pass "FORGE plugin.json exists"
else
    log_fail "FORGE plugin.json missing"
fi

# Test 6: Check Desloppify installation
log_section "6. Desloppify Installation"

if command -v desloppify >/dev/null 2>&1; then
    log_pass "Desloppify in PATH"
else
    log_fail "Desloppify not in PATH (may need: export PATH=\"\$HOME/.local/bin:\$PATH\")"
fi

if pip3 show desloppify >/dev/null 2>&1 || pip show desloppify >/dev/null 2>&1; then
    log_pass "Desloppify pip package installed"
else
    log_fail "Desloppify pip package not installed"
fi

# Test 7: Check unified CLI
log_section "7. Unified CLI Installation"

if [ -f "$OPENCLAW_DIR/bin/workflow" ]; then
    log_pass "workflow binary exists"
else
    log_fail "workflow binary missing"
fi

if [ -f "$OPENCLAW_DIR/packages/openclaw-cli/dist/index.js" ] || [ -f "$OPENCLAW_DIR/packages/openclaw-cli/src/index.ts" ]; then
    log_pass "openclaw-cli exists"
else
    log_fail "openclaw-cli missing"
fi

# Test 8: Integration test
log_section "8. Integration Test"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

export PATH="$HOME/.local/bin:$PATH"

# Test init
log_info "Testing: workflow init test-project"
if "$OPENCLAW_DIR/bin/workflow" --non-interactive init test-project >/dev/null 2>&1; then
    log_pass "workflow init executed"
else
    log_fail "workflow init failed"
fi

if [ -f "$TEST_DIR/.openclaw/config.yaml" ]; then
    log_pass "Project config created"
else
    log_fail "Project config not created"
fi

# Test PRD
log_info "Testing: workflow prd"
export OPENCLAW_PRD_CONTENT="Test project for validation"
if "$OPENCLAW_DIR/bin/workflow" --non-interactive prd >/dev/null 2>&1; then
    log_pass "workflow prd executed"
else
    log_fail "workflow prd failed"
fi

if [ -f "$TEST_DIR/docs/prd.md" ]; then
    log_pass "PRD file created"
else
    log_fail "PRD file not created"
fi

# Test status (JSON)
log_info "Testing: workflow --json status"
if "$OPENCLAW_DIR/bin/workflow" --json status >/dev/null 2>&1; then
    log_pass "workflow status --json executed"
else
    log_fail "workflow status --json failed"
fi

# Test doctor
log_info "Testing: workflow --json doctor"
if "$OPENCLAW_DIR/bin/workflow" --json doctor >/dev/null 2>&1; then
    log_pass "workflow doctor executed"
else
    log_fail "workflow doctor failed"
fi

# Test 9: Component availability
log_section "9. Component Availability"

if command -v ao >/dev/null 2>&1; then
    log_pass "ao command available"
else
    log_fail "ao command not available"
fi

if command -v desloppify >/dev/null 2>&1; then
    log_pass "desloppify command available"
else
    log_fail "desloppify command not available"
fi

# Summary
log_section "Test Summary"

echo ""
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  All tests passed! OpenClaw Workflow v2.0 is ready.${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  Some tests failed. Check output above.${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
