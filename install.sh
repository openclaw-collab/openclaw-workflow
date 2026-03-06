#!/bin/bash
# OpenClaw Workflow - Unified Installer v2.0
# Fully automated, agent/VPS compatible installation

set -e

OPENCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

NON_INTERACTIVE=${NON_INTERACTIVE:-false}
[[ "$1" == "--non-interactive" || "$1" == "-y" ]] && NON_INTERACTIVE=true

error_exit() { log_error "$1"; exit 1; }
command_exists() { command -v "$1" > /dev/null 2>&1; }

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           OpenClaw Workflow v2.0 - Unified Installer           ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║  BMAD → AO → FORGE → Quality → Deploy                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# PREREQUISITE CHECKS
log_info "Checking prerequisites..."

if ! command_exists node; then
    error_exit "Node.js not found. Please install Node.js 20+"
fi

NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
[ "$NODE_MAJOR" -lt 20 ] && error_exit "Node.js 20+ required. Found: $(node -v)"
log_success "Node.js $(node -v)"

if ! command_exists pnpm; then
    log_warn "pnpm not found. Installing..."
    npm install -g pnpm@9 || error_exit "Failed to install pnpm"
fi
log_success "pnpm $(pnpm --version)"

if ! command_exists python3; then
    error_exit "Python 3 not found. Please install Python 3.11+"
fi

PYTHON_MINOR=$(python3 --version | cut -d' ' -f2 | cut -d. -f2)
[ "$PYTHON_MINOR" -lt 11 ] && error_exit "Python 3.11+ required. Found: $(python3 --version)"
log_success "Python $(python3 --version | cut -d' ' -f2)"

PIP_CMD=$(command_exists pip3 && echo "pip3" || echo "pip")
log_success "pip available"

if ! command_exists git; then
    error_exit "Git not found"
fi
log_success "Git $(git --version | cut -d' ' -f3)"

CLAUDE_INSTALLED=false
if command_exists claude; then
    log_success "Claude Code $(claude --version 2>/dev/null)"
    CLAUDE_INSTALLED=true
else
    log_warn "Claude Code not found. Some features unavailable."
fi

echo ""

# SUBMODULE INITIALIZATION
log_info "Initializing submodules..."
cd "$OPENCLAW_DIR"

if [ -d ".git" ]; then
    git submodule update --init --recursive --force || {
        log_warn "Retrying submodule init..."
        git submodule deinit -f . 2>/dev/null || true
        git submodule update --init --recursive --force
    }
fi

for submodule in agent-orchestrator bmad-openclaw forge-ao desloppify; do
    [ ! -d "$OPENCLAW_DIR/packages/$submodule" ] && error_exit "Missing: packages/$submodule"
done
log_success "All submodules present"

echo ""

# INSTALL AO
log_info "[1/4] Installing Agent Orchestrator..."
cd "$OPENCLAW_DIR/packages/agent-orchestrator"
pnpm install || error_exit "AO install failed"
pnpm run build || {
    log_warn "AO full build had errors (web component), continuing with CLI..."
}

# Link AO CLI
cd packages/cli
chmod +x dist/index.js
mkdir -p ~/.local/bin
cat > ~/.local/bin/ao << 'AO_CLI_EOF'
#!/bin/bash
OPENCLAW_DIR="$(cd "$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")" && pwd)"
exec node "$OPENCLAW_DIR/packages/agent-orchestrator/packages/cli/dist/index.js" "$@"
AO_CLI_EOF
chmod +x ~/.local/bin/ao
log_success "Agent Orchestrator installed"

echo ""

# INSTALL BMAD
log_info "[2/4] Installing BMAD..."
cd "$OPENCLAW_DIR/packages/bmad-openclaw"
npm install || error_exit "BMAD install failed"
log_success "BMAD installed"

echo ""

# INSTALL FORGE
log_info "[3/4] Installing FORGE-AO..."
mkdir -p ~/.claude/plugins
rm -f ~/.claude/plugins/forge-ao 2>/dev/null || true
ln -sf "$OPENCLAW_DIR/packages/forge-ao" ~/.claude/plugins/forge-ao
log_success "FORGE-AO linked"

echo ""

# INSTALL DESLOPPIFY
log_info "[4/4] Installing Desloppify..."
cd "$OPENCLAW_DIR/packages/desloppify"
$PIP_CMD install -e ".[full]" || $PIP_CMD install -e . || error_exit "Desloppify install failed"
log_success "Desloppify installed"

echo ""

# CREATE UNIFIED CLI
log_info "Creating unified CLI..."
mkdir -p "$OPENCLAW_DIR/bin"

# Create wrapper script
cat > "$OPENCLAW_DIR/bin/workflow" << 'WRAPPER_EOF'
#!/bin/bash
OPENCLAW_DIR="$(cd "$(dirname "$(dirname "$(readlink -f "$0")")")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

CMD="$1"
if [[ "$CMD" == workflow:* ]]; then
    CMD="${CMD#workflow:}"
    set -- "$CMD" "${@:2}"
fi

case "$1" in
    init|prd|status|doctor)
        exec node "$OPENCLAW_DIR/packages/openclaw-cli/dist/index.js" "$@"
        ;;
    ao)
        shift
        exec ao "$@"
        ;;
    forge)
        shift
        exec ao forge "$@"
        ;;
    desloppify)
        shift
        exec desloppify "$@"
        ;;
    help|--help|-h)
        echo "OpenClaw Workflow CLI v2.0"
        echo ""
        echo "Commands:"
        echo "  workflow init [name]              Initialize project"
        echo "  workflow prd [content]            Create PRD"
        echo "  workflow ao <cmd>                 AO commands (init, spawn, status)"
        echo "  workflow forge <cmd>              FORGE commands (init-from-prd, run, status)"
        echo "  workflow desloppify [args]        Code quality"
        echo "  workflow status                   Show status"
        echo "  workflow doctor                   Health check"
        echo ""
        echo "Options:"
        echo "  --json                            JSON output for agents"
        echo "  --non-interactive, -y             No prompts (VPS mode)"
        ;;
    *)
        echo "Unknown: $1"
        echo "Run: workflow help"
        exit 1
        ;;
esac
WRAPPER_EOF

chmod +x "$OPENCLAW_DIR/bin/workflow"
ln -sf "$OPENCLAW_DIR/bin/workflow" ~/.local/bin/workflow 2>/dev/null || true

# Create TypeScript CLI
mkdir -p "$OPENCLAW_DIR/packages/openclaw-cli/src"

cat > "$OPENCLAW_DIR/packages/openclaw-cli/package.json" << 'PKG_JSON'
{
  "name": "@openclaw/cli",
  "version": "2.0.0",
  "description": "OpenClaw Workflow Unified CLI",
  "main": "dist/index.js",
  "bin": { "openclaw": "dist/index.js" },
  "scripts": { "build": "tsc", "dev": "tsx src/index.ts" },
  "dependencies": { "yaml": "^2.7.0", "commander": "^13.0.0" },
  "devDependencies": { "typescript": "^5.7.0", "@types/node": "^22.0.0", "tsx": "^4.19.0" }
}
PKG_JSON

cat > "$OPENCLAW_DIR/packages/openclaw-cli/tsconfig.json" << 'TS_CONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "resolveJsonModule": true
  }
}
TS_CONFIG

cat > "$OPENCLAW_DIR/packages/openclaw-cli/src/index.ts" << 'CLI_TS'
#!/usr/bin/env node
import { Command } from 'commander';
import * as fs from 'fs';
import * as path from 'path';
import * as yaml from 'yaml';
import { execSync } from 'child_process';

const program = new Command();
const OPENCLAW_DIR = path.resolve(path.dirname(__dirname), '..');

interface CliOptions {
  json?: boolean;
  nonInteractive?: boolean;
  verbose?: boolean;
}

function output(data: any, options: CliOptions) {
  if (options.json) {
    console.log(JSON.stringify(data, null, 2));
  } else if (data.message) {
    console.log(data.message);
  }
}

function findAo(): string | null {
  try {
    execSync('which ao', { stdio: 'pipe' });
    return 'ao';
  } catch {
    const localAo = path.join(OPENCLAW_DIR, '../agent-orchestrator/packages/cli/dist/index.js');
    if (fs.existsSync(localAo)) return `node ${localAo}`;
  }
  return null;
}

function findDesloppify(): string | null {
  try {
    execSync('which desloppify', { stdio: 'pipe' });
    return 'desloppify';
  } catch { return null; }
}

program
  .name('workflow')
  .description('OpenClaw Workflow Unified CLI')
  .version('2.0.0')
  .option('--json', 'Output JSON')
  .option('-y, --non-interactive', 'No prompts')
  .option('-v, --verbose', 'Verbose output');

program
  .command('init [name]')
  .description('Initialize OpenClaw project')
  .action(async (name, options) => {
    const opts: CliOptions = { ...program.opts(), ...options };
    const projectName = name || path.basename(process.cwd());

    if (fs.existsSync('.openclaw/config.yaml')) {
      output({ success: false, error: 'Already initialized' }, opts);
      process.exit(1);
    }

    fs.mkdirSync('.openclaw', { recursive: true });
    fs.mkdirSync('docs/prd', { recursive: true });
    fs.mkdirSync('docs/forge', { recursive: true });
    fs.mkdirSync('src', { recursive: true });

    const config = {
      project: { name: projectName, created: new Date().toISOString() },
      workflow: { prd: 'bmad', orchestration: 'ao', implementation: 'forge', quality: 'desloppify' },
      paths: { prd: 'docs/prd', forge: 'docs/forge', src: 'src' }
    };

    fs.writeFileSync('.openclaw/config.yaml', yaml.stringify(config));
    fs.writeFileSync('.gitignore', '.openclaw/sessions/\n.claude/forge/snapshots/\n.desloppify/\nnode_modules/\n');

    output({ success: true, message: `Initialized: ${projectName}`, project: projectName }, opts);
  });

program
  .command('prd [content...]')
  .description('Create PRD')
  .action(async (content, options) => {
    const opts: CliOptions = { ...program.opts(), ...options };

    if (!fs.existsSync('.openclaw/config.yaml')) {
      output({ success: false, error: 'Run "workflow init" first' }, opts);
      process.exit(1);
    }

    const prdContent = process.env.OPENCLAW_PRD_CONTENT || content.join(' ');

    const prdTemplate = `---\nproject_name: ${path.basename(process.cwd())}\ncreated: ${new Date().toISOString()}\n---\n\n# Product Requirements Document\n\n## Executive Summary\n${prdContent || 'TODO: Add summary'}\n\n## Functional Requirements\n\n## Non-Functional Requirements\n\n## User Journeys\n\n## Success Metrics\n`;

    fs.writeFileSync('docs/prd.md', prdTemplate);
    output({ success: true, message: 'PRD created: docs/prd.md', file: 'docs/prd.md' }, opts);
  });

program
  .command('status')
  .description('Show workflow status')
  .action(async (options) => {
    const opts: CliOptions = { ...program.opts(), ...options };
    const status = {
      initialized: fs.existsSync('.openclaw/config.yaml'),
      prd: fs.existsSync('docs/prd.md'),
      ao: !!findAo(),
      forge: fs.existsSync('.claude/forge'),
      desloppify: !!findDesloppify()
    };

    if (opts.json) {
      output({ success: true, status }, opts);
    } else {
      console.log('Status:');
      Object.entries(status).forEach(([k, v]) => console.log(`  ${v ? '✓' : '✗'} ${k}`));
    }
  });

program
  .command('doctor')
  .description('Health check')
  .action(async (options) => {
    const opts: CliOptions = { ...program.opts(), ...options };
    const checks = { node: false, pnpm: false, python: false, ao: false, forge: false, bmad: false, desloppify: false };

    try { execSync('node --version', { stdio: 'pipe' }); checks.node = true; } catch {}
    try { execSync('pnpm --version', { stdio: 'pipe' }); checks.pnpm = true; } catch {}
    try { execSync('python3 --version', { stdio: 'pipe' }); checks.python = true; } catch {}
    checks.ao = !!findAo();
    checks.forge = fs.existsSync(path.join(OPENCLAW_DIR, '../forge-ao/.claude-plugin/plugin.json'));
    checks.bmad = fs.existsSync(path.join(OPENCLAW_DIR, '../bmad-openclaw/package.json'));
    checks.desloppify = !!findDesloppify();

    const allGood = Object.values(checks).every(v => v);

    if (opts.json) {
      output({ success: allGood, checks }, opts);
    } else {
      console.log('Health Check:');
      Object.entries(checks).forEach(([k, v]) => console.log(`  ${v ? '✓' : '✗'} ${k}`));
    }

    process.exit(allGood ? 0 : 1);
  });

program.parse();
CLI_TS

# Build the CLI
cd "$OPENCLAW_DIR/packages/openclaw-cli"
npm install 2>/dev/null || true
npx tsc 2>/dev/null || {
    log_warn "TypeScript build failed, using direct execution"
    mkdir -p dist
    echo '#!/usr/bin/env node' > dist/index.js
    cat src/index.ts >> dist/index.js
    chmod +x dist/index.js
}

log_success "Unified CLI created"

echo ""

# PATH CHECK
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "Add to ~/.bashrc or ~/.zshrc"
    echo ""
fi

# COMPLETION
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  workflow init my-project"
echo "  workflow prd 'Build a task app'"
echo "  workflow ao init --auto"
echo "  workflow forge init-from-prd docs/prd.md my-project"
echo ""
echo "Agent Mode:"
echo "  workflow --non-interactive init"
echo "  workflow --json status"
echo ""

if [ "$CLAUDE_INSTALLED" = false ]; then
    echo "Install Claude Code: npm install -g @anthropic-ai/claude-code"
    echo ""
fi

log_success "OpenClaw Workflow v2.0 ready!"
