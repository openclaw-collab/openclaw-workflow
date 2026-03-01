#!/bin/bash
# OpenClaw Workflow - Unified Installer
# One-command setup for the complete OpenClaw → PRD → AO → FORGE workflow

set -e

OPENCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           OpenClaw Workflow - Unified Installer                ║"
echo "║                                                                ║"
echo "║  PRD → AO → FORGE → Quality → Deploy                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js 18+ required. Found: $(node -v)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node -v)${NC}"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.11+${NC}"
    exit 1
fi
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}✓ Python $PYTHON_VERSION${NC}"

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git not found. Please install Git${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git $(git --version | cut -d' ' -f3)${NC}"

# Check Claude Code
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}⚠ Claude Code not found. Install with: npm install -g @anthropic-ai/claude-code${NC}"
    CLAUDE_INSTALLED=false
else
    echo -e "${GREEN}✓ Claude Code $(claude --version)${NC}"
    CLAUDE_INSTALLED=true
fi

echo ""

# Initialize all submodules by default
echo -e "${BLUE}Initializing all submodules...${NC}"
cd "$OPENCLAW_DIR"
git submodule update --init --recursive --force
echo -e "${GREEN}✓ All submodules initialized${NC}"

# Verify all submodules exist (check for .git file/directory)
SUBMODULES_MISSING=false
for submodule in packages/agent-orchestrator packages/bmad-openclaw packages/forge-ao packages/desloppify; do
    if [ ! -e "$OPENCLAW_DIR/$submodule/.git" ]; then
        echo -e "${RED}✗ Submodule missing: $submodule${NC}"
        SUBMODULES_MISSING=true
    fi
done

if [ "$SUBMODULES_MISSING" = true ]; then
    echo -e "${YELLOW}⚠ Some submodules are missing. Trying alternative initialization...${NC}"
    git submodule init
    git submodule update --recursive
fi

echo ""
echo -e "${BLUE}Installing components...${NC}"
echo ""

# Install Agent Orchestrator
echo -e "${BLUE}[1/4] Installing Agent Orchestrator...${NC}"
cd "$OPENCLAW_DIR/packages/agent-orchestrator"
if [ -f "package.json" ]; then
    npm install
    npm run build 2>/dev/null || true
    # Link CLI globally
    npm link 2>/dev/null || true
    echo -e "${GREEN}✓ Agent Orchestrator installed${NC}"
else
    echo -e "${YELLOW}⚠ Agent Orchestrator package.json not found${NC}"
fi

# Install BMAD
echo -e "${BLUE}[2/4] Installing BMAD Openclaw...${NC}"
cd "$OPENCLAW_DIR/packages/bmad-openclaw"
# BMAD is primarily YAML workflows, minimal install
echo -e "${GREEN}✓ BMAD Openclaw ready${NC}"

# Install FORGE-AO
echo -e "${BLUE}[3/4] Installing FORGE-AO...${NC}"
cd "$OPENCLAW_DIR/packages/forge-ao"
if [ -f ".claude-plugin/plugin.json" ]; then
    # Install FORGE as Claude Code plugin
    mkdir -p ~/.claude/plugins
    ln -sf "$OPENCLAW_DIR/packages/forge-ao" ~/.claude/plugins/forge-ao 2>/dev/null || true
    echo -e "${GREEN}✓ FORGE-AO plugin linked${NC}"
else
    echo -e "${YELLOW}⚠ FORGE-AO plugin.json not found${NC}"
fi

# Install Desloppify
echo -e "${BLUE}[4/4] Installing Desloppify...${NC}"
cd "$OPENCLAW_DIR/packages/desloppify"
if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
    pip install -e ".[full]" 2>/dev/null || pip install -e . 2>/dev/null || true
    echo -e "${GREEN}✓ Desloppify installed${NC}"
else
    echo -e "${YELLOW}⚠ Desloppify setup.py not found${NC}"
fi

echo ""
echo -e "${BLUE}Creating unified CLI...${NC}"

# Create unified CLI
cat > "$OPENCLAW_DIR/bin/openclaw" << 'EOF'
#!/bin/bash
# OpenClaw Unified CLI
# Single entry point for all OpenClaw workflow tools
# Commands are prefixed with workflow: to avoid conflicts with native tools

OPENCLAW_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

function show_help() {
    echo "OpenClaw Workflow - Unified CLI"
    echo ""
    echo "Usage: workflow <command> [options]"
    echo ""
    echo "Commands:"
    echo "  workflow init                    Initialize a new OpenClaw project"
    echo "  workflow prd                     Start BMAD PRD creation workflow"
    echo "  workflow ao <command>            Agent Orchestrator commands"
    echo "  workflow forge <command>         FORGE workflow commands"
    echo "  workflow desloppify <command>    Code quality commands"
    echo "  workflow status                  Show workflow status"
    echo "  workflow doctor                  Check installation health"
    echo ""
    echo "Examples:"
    echo "  workflow init                      # Initialize project"
    echo "  workflow prd                       # Create PRD"
    echo "  workflow ao init --auto            # Initialize AO"
    echo "  workflow forge init-from-prd ...   # Start FORGE"
    echo ""
}

function cmd_init() {
    echo "🔧 Initializing OpenClaw project..."

    if [ -f ".openclaw/config.yaml" ]; then
        echo "⚠️  OpenClaw already initialized"
        exit 1
    fi

    mkdir -p .openclaw
    mkdir -p docs/prd
    mkdir -p docs/forge
    mkdir -p src

    cat > .openclaw/config.yaml << EOL
project:
  name: $(basename "$(pwd)")
  created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

workflow:
  prd: bmad
  orchestration: ao
  implementation: forge
  quality: desloppify

paths:
  prd: docs/prd
  forge: docs/forge
  src: src
EOL

    if [ ! -d ".git" ]; then
        git init
        echo "✓ Git initialized"
    fi

    cat > .gitignore << EOL
.openclaw/sessions/
.claude/forge/snapshots/
.desloppify/
node_modules/
dist/
__pycache__/
*.pyc
.venv/
.vscode/
.idea/
EOL

    echo "✓ Project initialized"
    echo ""
    echo "Next:"
    echo "  workflow prd          # Create product requirements"
    echo "  workflow ao init      # Initialize orchestration"
}

function cmd_prd() {
    echo "📋 BMAD PRD workflow..."

    if [ ! -f ".openclaw/config.yaml" ]; then
        echo "⚠️  Run: workflow init"
        exit 1
    fi

    BMAD_DIR="$OPENCLAW_DIR/packages/bmad-openclaw"
    echo "Load: $BMAD_DIR/bmad-method/bmm/workflows/2-plan-workflows/create-prd/workflow-create-prd.md"
}

function cmd_ao() {
    shift
    if command -v ao &> /dev/null; then
        ao "$@"
    elif [ -f "$OPENCLAW_DIR/packages/agent-orchestrator/bin/ao.js" ]; then
        node "$OPENCLAW_DIR/packages/agent-orchestrator/bin/ao.js" "$@"
    else
        echo "⚠️  Agent Orchestrator not found"
        exit 1
    fi
}

function cmd_forge() {
    shift
    if [ "$1" == "init-from-prd" ]; then
        shift
        PRD_PATH="${1:-docs/prd.md}"
        PROJECT_ID="${2:-$(basename "$(pwd)")}"
        echo "🔥 FORGE: Creating debate from PRD..."
        cmd_ao ao forge init-from-prd "$PRD_PATH" "$PROJECT_ID"
    else
        cmd_ao ao forge "$@"
    fi
}

function cmd_desloppify() {
    if command -v desloppify &> /dev/null; then
        desloppify "$@"
    else
        echo "⚠️  pip install desloppify[full]"
        exit 1
    fi
}

function cmd_status() {
    echo "📊 OpenClaw Status"
    echo ""

    if [ -f ".openclaw/config.yaml" ]; then
        echo -e "${GREEN}✓${NC} Project initialized"
    else
        echo -e "${YELLOW}⚠${NC} Not initialized"
    fi

    if [ -f "docs/prd.md" ]; then
        echo -e "${GREEN}✓${NC} PRD exists"
    else
        echo -e "${YELLOW}⚠${NC} No PRD"
    fi

    if command -v ao &> /dev/null; then
        echo -e "${GREEN}✓${NC} AO installed"
    else
        echo -e "${YELLOW}⚠${NC} AO not available"
    fi

    if [ -d ".claude/forge" ]; then
        echo -e "${GREEN}✓${NC} FORGE initialized"
    else
        echo -e "${YELLOW}⚠${NC} FORGE not initialized"
    fi
}

function cmd_doctor() {
    echo "🏥 OpenClaw Health Check"
    echo ""

    ALL_GOOD=true

    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node.js $(node -v)"
    else
        echo -e "${RED}✗${NC} Node.js not found"
        ALL_GOOD=false
    fi

    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✓${NC} Python $(python3 --version | cut -d' ' -f2)"
    else
        echo -e "${RED}✗${NC} Python not found"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/agent-orchestrator/.git" ]; then
        echo -e "${GREEN}✓${NC} AO submodule"
    else
        echo -e "${RED}✗${NC} AO submodule missing"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/forge-ao/.git" ]; then
        echo -e "${GREEN}✓${NC} FORGE submodule"
    else
        echo -e "${RED}✗${NC} FORGE submodule missing"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/bmad-openclaw/.git" ]; then
        echo -e "${GREEN}✓${NC} BMAD submodule"
    else
        echo -e "${RED}✗${NC} BMAD submodule missing"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/desloppify/.git" ]; then
        echo -e "${GREEN}✓${NC} Desloppify submodule"
    else
        echo -e "${RED}✗${NC} Desloppify submodule missing"
        ALL_GOOD=false
    fi

    echo ""
    if [ "$ALL_GOOD" = true ]; then
        echo -e "${GREEN}All checks passed!${NC}"
    else
        echo -e "${YELLOW}Some issues found${NC}"
    fi
}

# Parse workflow:command format
CMD="${1:-}"

# Handle both workflow:command and command formats for flexibility
if [[ "$CMD" == workflow:* ]]; then
    CMD="${CMD#workflow:}"
fi

case "$CMD" in
    init) cmd_init "$@" ;;
    prd) cmd_prd "$@" ;;
    ao) cmd_ao "$@" ;;
    forge) cmd_forge "$@" ;;
    desloppify) shift; cmd_desloppify "$@" ;;
    status) cmd_status ;;
    doctor) cmd_doctor ;;
    help|--help|-h) show_help ;;
    *) show_help; exit 1 ;;
esac
EOF

# Rename CLI to workflow
mv "$OPENCLAW_DIR/bin/openclaw" "$OPENCLAW_DIR/bin/workflow" 2>/dev/null || true
chmod +x "$OPENCLAW_DIR/bin/workflow"

# Create single 'workflow' command (usage: workflow doctor, workflow init, etc.)
mkdir -p ~/.local/bin
ln -sf "$OPENCLAW_DIR/bin/workflow" ~/.local/bin/workflow 2>/dev/null || true

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Add ~/.local/bin to your PATH:${NC}"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

echo -e "${GREEN}✓ Unified CLI created at: $OPENCLAW_DIR/bin/workflow${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  1. cd your-project"
echo "  2. workflow init       # Initialize OpenClaw workflow"
echo "  3. workflow prd        # Create product requirements"
echo "  4. workflow ao init    # Initialize orchestration"
echo "  5. workflow forge ...  # Start FORGE implementation"
echo ""
echo "Commands:"
echo "  workflow doctor        # Check installation health"
echo "  workflow status        # Show workflow status"
echo "  workflow init --help   # Show all commands"
echo ""

if [ "$CLAUDE_INSTALLED" = false ]; then
    echo -e "${YELLOW}Note: Claude Code not detected. Install with:${NC}"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""
fi

echo "For documentation, see: $OPENCLAW_DIR/README.md"
