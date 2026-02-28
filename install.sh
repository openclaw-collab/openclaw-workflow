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

# Initialize submodules if not already done
if [ ! -f "$OPENCLAW_DIR/packages/forge-ao/.git" ]; then
    echo -e "${BLUE}Initializing submodules...${NC}"
    cd "$OPENCLAW_DIR"
    git submodule update --init --recursive
    echo -e "${GREEN}✓ Submodules initialized${NC}"
else
    echo -e "${GREEN}✓ Submodules already present${NC}"
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

OPENCLAW_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"

function show_help() {
    echo "OpenClaw Workflow - Unified CLI"
    echo ""
    echo "Usage: openclaw <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                    Initialize a new OpenClaw project"
    echo "  prd                     Start BMAD PRD creation workflow"
    echo "  ao <command>            Agent Orchestrator commands"
    echo "  forge <command>         FORGE workflow commands"
    echo "  desloppify <command>    Code quality commands"
    echo "  status                  Show workflow status"
    echo "  doctor                  Check installation health"
    echo ""
    echo "Examples:"
    echo "  openclaw init                      # Initialize project"
    echo "  openclaw prd                       # Create PRD"
    echo "  openclaw ao init --auto            # Initialize AO"
    echo "  openclaw forge init-from-prd ...   # Start FORGE"
    echo ""
}

function cmd_init() {
    echo "🔧 Initializing OpenClaw project..."

    # Check if already initialized
    if [ -f ".openclaw/config.yaml" ]; then
        echo "⚠️  OpenClaw already initialized in this directory"
        exit 1
    fi

    # Create project structure
    mkdir -p .openclaw
    mkdir -p docs/prd
    mkdir -p docs/forge
    mkdir -p src

    # Create config
    cat > .openclaw/config.yaml << EOL
# OpenClaw Workflow Configuration
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

    # Initialize git if not already
    if [ ! -d ".git" ]; then
        git init
        echo "✓ Git initialized"
    fi

    # Create .gitignore
    cat > .gitignore << EOL
# OpenClaw
.openclaw/sessions/
.claude/forge/snapshots/
.desloppify/

# Node
node_modules/
dist/

# Python
__pycache__/
*.pyc
.venv/

# IDE
.vscode/
.idea/
EOL

    echo "✓ Project initialized"
    echo ""
    echo "Next steps:"
    echo "  1. openclaw prd          # Create product requirements"
    echo "  2. openclaw ao init      # Initialize orchestration"
}

function cmd_prd() {
    echo "📋 Starting BMAD PRD workflow..."

    if [ ! -f ".openclaw/config.yaml" ]; then
        echo "⚠️  Not an OpenClaw project. Run: openclaw init"
        exit 1
    fi

    # Check if BMAD exists
    BMAD_DIR="$OPENCLAW_DIR/packages/bmad-openclaw"
    if [ -d "$BMAD_DIR" ]; then
        echo "BMAD workflow available at: $BMAD_DIR"
        echo ""
        echo "To create PRD:"
        echo "  1. Start Claude Code: claude"
        echo "  2. Load BMAD workflow: /load $BMAD_DIR/bmad-method/bmm/workflows/2-plan-workflows/create-prd/workflow-create-prd.md"
        echo ""
        echo "Or manually follow the workflow in:"
        echo "  $BMAD_DIR/bmad-method/bmm/workflows/2-plan-workflows/create-prd/steps-c/"
    else
        echo "⚠️  BMAD not found. Run: openclaw doctor"
    fi
}

function cmd_ao() {
    shift  # Remove 'ao' from args
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
    shift  # Remove 'forge' from args

    if [ "$1" == "init-from-prd" ]; then
        # Enhanced init-from-prd with auto-detection
        shift
        PRD_PATH="${1:-docs/prd.md}"
        PROJECT_ID="${2:-$(basename "$(pwd)")}"

        echo "🔥 FORGE: Creating debate from PRD..."
        echo "  PRD: $PRD_PATH"
        echo "  Project: $PROJECT_ID"

        cmd_ao ao forge init-from-prd "$PRD_PATH" "$PROJECT_ID"
    else
        # Pass through to AO forge
        cmd_ao ao forge "$@"
    fi
}

function cmd_desloppify() {
    if command -v desloppify &> /dev/null; then
        desloppify "$@"
    else
        echo "⚠️  Desloppify not installed"
        echo "Install with: pip install desloppify[full]"
        exit 1
    fi
}

function cmd_status() {
    echo "📊 OpenClaw Workflow Status"
    echo ""

    # Check project
    if [ -f ".openclaw/config.yaml" ]; then
        echo -e "${GREEN}✓${NC} OpenClaw project initialized"
        PROJECT_NAME=$(grep "name:" .openclaw/config.yaml | head -1 | cut -d':' -f2 | tr -d ' ')
        echo "  Project: $PROJECT_NAME"
    else
        echo -e "${YELLOW}⚠${NC} Not an OpenClaw project"
    fi

    # Check PRD
    if [ -f "docs/prd.md" ]; then
        echo -e "${GREEN}✓${NC} PRD exists"
    else
        echo -e "${YELLOW}⚠${NC} No PRD found"
    fi

    # Check AO
    if command -v ao &> /dev/null; then
        echo -e "${GREEN}✓${NC} Agent Orchestrator installed"
        # Try to get status
        ao status 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠${NC} Agent Orchestrator not available"
    fi

    # Check FORGE
    if [ -d ".claude/forge" ]; then
        echo -e "${GREEN}✓${NC} FORGE initialized"
        if [ -f ".claude/forge/active-workflow.md" ]; then
            PHASE=$(grep "^phase:" .claude/forge/active-workflow.md | cut -d':' -f2 | tr -d ' ')
            echo "  Current phase: $PHASE"
        fi
    else
        echo -e "${YELLOW}⚠${NC} FORGE not initialized"
    fi

    # Check desloppify
    if command -v desloppify &> /dev/null; then
        echo -e "${GREEN}✓${NC} Desloppify installed"
    else
        echo -e "${YELLOW}⚠${NC} Desloppify not available"
    fi
}

function cmd_doctor() {
    echo "🏥 OpenClaw Workflow Health Check"
    echo ""

    ALL_GOOD=true

    # Check Node
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node.js $(node -v)"
    else
        echo -e "${RED}✗${NC} Node.js not found"
        ALL_GOOD=false
    fi

    # Check Python
    if command -v python3 &> /dev/null; then
        echo -e "${GREEN}✓${NC} Python $(python3 --version | cut -d' ' -f2)"
    else
        echo -e "${RED}✗${NC} Python not found"
        ALL_GOOD=false
    fi

    # Check submodules
    if [ -d "$OPENCLAW_DIR/packages/agent-orchestrator/.git" ]; then
        echo -e "${GREEN}✓${NC} Agent Orchestrator submodule"
    else
        echo -e "${RED}✗${NC} Agent Orchestrator submodule missing"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/forge-ao/.git" ]; then
        echo -e "${GREEN}✓${NC} FORGE-AO submodule"
    else
        echo -e "${RED}✗${NC} FORGE-AO submodule missing"
        ALL_GOOD=false
    fi

    if [ -d "$OPENCLAW_DIR/packages/bmad-openclaw/.git" ]; then
        echo -e "${GREEN}✓${NC} BMAD Openclaw submodule"
    else
        echo -e "${RED}✗${NC} BMAD Openclaw submodule missing"
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
        echo -e "${YELLOW}Some issues found. Run: ./install.sh${NC}"
    fi
}

# Main command dispatch
case "${1:-}" in
    init)
        cmd_init "$@"
        ;;
    prd)
        cmd_prd "$@"
        ;;
    ao)
        cmd_ao "$@"
        ;;
    forge)
        cmd_forge "$@"
        ;;
    desloppify)
        shift
        cmd_desloppify "$@"
        ;;
    status)
        cmd_status
        ;;
    doctor)
        cmd_doctor
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
EOF

chmod +x "$OPENCLAW_DIR/bin/openclaw"

# Link to global bin
mkdir -p ~/.local/bin
ln -sf "$OPENCLAW_DIR/bin/openclaw" ~/.local/bin/openclaw 2>/dev/null || true

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠ Add ~/.local/bin to your PATH:${NC}"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

echo -e "${GREEN}✓ Unified CLI created at: $OPENCLAW_DIR/bin/openclaw${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  1. cd your-project"
echo "  2. openclaw init       # Initialize OpenClaw workflow"
echo "  3. openclaw prd        # Create product requirements"
echo "  4. openclaw ao init    # Initialize orchestration"
echo "  5. openclaw forge ...  # Start FORGE implementation"
echo ""
echo "Commands:"
echo "  openclaw doctor        # Check installation health"
echo "  openclaw status        # Show workflow status"
echo "  openclaw --help        # Show all commands"
echo ""

if [ "$CLAUDE_INSTALLED" = false ]; then
    echo -e "${YELLOW}Note: Claude Code not detected. Install with:${NC}"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""
fi

echo "For documentation, see: $OPENCLAW_DIR/README.md"
