# OpenClaw Workflow

> **Unified AI-Native Development Workflow**
>
> From idea to production: BMAD PRD → AO Orchestration → FORGE Implementation → Desloppify Quality

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Overview

OpenClaw Workflow is a **meta-framework** that combines four specialized AI-native tools into a single cohesive development pipeline. Rather than replacing existing tools, OpenClaw orchestrates them to work together seamlessly.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OPENC LAW WORKFLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│   │    BMAD     │───▶│     AO      │───▶│    FORGE    │───▶│ Desloppify  │ │
│   │    (PRD)    │    │(Orchestrate)│    │(Implement)  │    │  (Quality)  │ │
│   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │
│                                                                             │
│   Structured PRD      Multi-agent          10-phase          Continuous    │
│   creation via        orchestration        development        quality       │
│   human-AI            with CI/CD           with debate        improvement   │
│   dialogue            integration          gates                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

**IMPORTANT: OpenClaw Workflow must be installed and run as a non-root user.** Claude Code (which FORGE uses) refuses to run as root for security reasons.

```bash
# Check if you're running as root (should return empty or non-zero)
whoami  # should NOT be 'root'

# If you are root, create a user first:
# Ubuntu/Debian
useradd -m -s /bin/bash openclaw
usermod -aG sudo openclaw
su - openclaw

# Or use your existing user
```

**Required:**
- Node.js 20+ (non-root installation recommended via nvm)
- Python 3.11+
- Git
- pnpm (will be auto-installed if missing)

```bash
# Install Node.js via nvm (recommended - non-root)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc  # or ~/.zshrc
nvm install 22
nvm use 22

# Verify versions
node -v  # v22.x.x
python3 --version  # 3.11+
git --version
```

### CRITICAL: Claude Code First-Run Setup

**For OpenClaw Agents/Automation:** Claude Code prompts for theme selection on first run, which blocks automated workflows. You must pre-configure Claude Code before AO can spawn sessions.

**Option 1: Interactive Setup (Recommended for first install)**
```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Run once to select theme (Dark/Light), then exit
claude
# Select theme with arrow keys, press Enter
# Exit with Ctrl+D or type 'exit'

# Now automation will work
```

**Option 2: Automated Setup (For VPS/Agents without TTY)**
```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Create expect script to automate theme selection
cat > /tmp/setup-claude.sh << 'EOF'
#!/usr/bin/env expect -f
spawn claude
expect "Choose your theme"
send "\r"  # Select default (Dark)
expect {
  "Claude Code" { send "\004" }  ;# Exit with Ctrl+D
  timeout { send "\004" }
}
EOF
chmod +x /tmp/setup-claude.sh

# Run expect script (install expect first: apt-get install expect)
/tmp/setup-claude.sh || true

# Alternative: Use tmux to send keystrokes
tmux new-session -d -s claude-setup "claude"
sleep 2
tmux send-keys -t claude-setup Enter  # Select theme
tmux send-keys -t claude-setup C-d    # Exit
```

**Option 3: Docker with Pre-configured Claude Code**
```dockerfile
# Use image with Claude Code already initialized
FROM openclaw/claude-code-base:latest

# Claude settings are pre-configured in the image
# Theme is already selected, API key can be passed at runtime
```

### One-Command Installation

```bash
# Clone with all submodules (as non-root user)
git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
cd openclaw-workflow

# Install everything
./install.sh

# Add to PATH if needed (add this to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
workflow doctor
```

### Agent/VPS Deployment (Non-Interactive Mode)

For automated/agent deployments where no human is present:

```bash
# 1. Set up non-root user first (CRITICAL)
useradd -m -s /bin/bash openclaw
su - openclaw

# 2. Install with nvm (non-root Node.js)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install 22

# 3. Clone and install
git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
cd openclaw-workflow
./install.sh --non-interactive

# 4. Full automated workflow
export OPENCLAW_PRD_CONTENT="Build a React todo app with local storage"

workflow init todo-app --json -y
cd todo-app
workflow prd --json --non-interactive
workflow ao init --auto
workflow forge init-from-prd docs/prd.md todo-app --json
```

**Docker Deployment (Recommended for VPS):**

```dockerfile
FROM node:22-bookworm

# Install Python and git
RUN apt-get update && apt-get install -y python3.11 python3-pip git

# Create non-root user
RUN useradd -m -s /bin/bash openclaw
USER openclaw
WORKDIR /home/openclaw

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
ENV NVM_DIR=/home/openclaw/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install 22

# Clone and setup
RUN git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
WORKDIR /home/openclaw/openclaw-workflow
RUN export PATH="$HOME/.local/bin:$PATH" && ./install.sh

ENV PATH="/home/openclaw/.local/bin:/home/openclaw/.nvm/versions/node/v22.0.0/bin:$PATH"

ENTRYPOINT ["workflow"]
```

## OpenClaw Agent Usage

If you're using OpenClaw (the AI agent platform) to run this workflow, follow these specific instructions:

### Pre-flight Checklist for OpenClaw Agents

Before invoking OpenClaw Workflow, ensure:

1. **Non-root user is active** (Claude Code requirement)
2. **Claude Code theme is pre-selected** (blocks automation otherwise)
3. **API keys are configured** (Claude/OpenAI/etc.)

### OpenClaw-Optimized Setup Script

```bash
#!/bin/bash
# openclaw-agent-setup.sh - Run this first in your OpenClaw agent

set -e

# 1. Create and switch to non-root user (if running as root)
if [ "$(whoami)" = "root" ]; then
  useradd -m -s /bin/bash openclaw 2>/dev/null || true
  # Run remaining setup as openclaw user
  su - openclaw -c "bash $0"
  exit 0
fi

# 2. Install Node.js via nvm (non-root)
if ! command -v node &> /dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install 22
fi

# 3. Install Python
sudo apt-get update && sudo apt-get install -y python3.11 python3-pip git expect

# 4. Install and pre-configure Claude Code
if ! command -v claude &> /dev/null; then
  npm install -g @anthropic-ai/claude-code

  # Pre-select theme using expect
  cat > /tmp/claude-setup.exp << 'EOF'
spawn claude
expect "Choose your theme"
send "\r"
expect eof
EOF
  expect /tmp/claude-setup.exp || true
fi

# 5. Clone and install OpenClaw Workflow
if [ ! -d "openclaw-workflow" ]; then
  git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
fi
cd openclaw-workflow
./install.sh --non-interactive

# 6. Verify
echo "Verification:"
workflow doctor --json

echo "Setup complete!"
```

### Using OpenClaw Workflow from OpenClaw

**Method 1: Direct Shell Commands**
```javascript
// In your OpenClaw agent code
const result = await execTool({
  command: "cd ~/openclaw-workflow && workflow init my-project --json -y"
});
```

**Method 2: Via OpenClaw's Exec Tool**
```yaml
# OpenClaw agent configuration
actions:
  - name: "Initialize OpenClaw Workflow"
    tool: "Bash"
    command: |
      export PATH="$HOME/.local/bin:$PATH"
      workflow init ${{ project_name }} --json --non-interactive

  - name: "Create PRD"
    tool: "Bash"
    command: |
      export OPENCLAW_PRD_CONTENT="${{ prd_content }}"
      workflow prd --json --non-interactive

  - name: "Spawn Implementation Agent"
    tool: "Bash"
    command: |
      workflow ao spawn ${{ project_name }} ${{ issue_id }}
```

**Method 3: AO Spawn with Claude Code (Pre-configured)**
```bash
# The AO spawn command will use Claude Code
# Claude Code must be pre-configured (theme selected, API key set)
workflow ao init --auto
workflow ao spawn my-project 123
```

### OpenClaw-Specific Environment Variables

```bash
# Required for non-interactive operation
export OPENCLAW_PRD_CONTENT="Your PRD content here"
export ANTHROPIC_API_KEY="sk-ant-..."

# Optional
export OPENCLAW_JSON_OUTPUT=true
export OPENCLAW_NON_INTERACTIVE=true
```

### Troubleshooting OpenClaw Integration

**Issue: "Claude Code cannot run as root"**
```bash
# OpenClaw may run as root by default
# Create and switch to user:
useradd -m -s /bin/bash openclaw
su - openclaw
```

**Issue: AO spawn hangs indefinitely**
```bash
# Likely Claude Code theme selection blocking
# Check if theme is configured:
claude --version  # Should not show theme prompt

# If stuck, pre-configure:
expect -c 'spawn claude; expect "Choose your theme"; send "\r"; expect eof' || true
```

**Issue: "command not found: workflow"**
```bash
# Add to PATH in OpenClaw environment
export PATH="$HOME/.local/bin:$PATH"
# Or use full path:
~/openclaw-workflow/bin/workflow ...
```

### Start a New Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Initialize OpenClaw workflow
workflow init

# Create Product Requirements Document
workflow prd
# ... follow the BMAD agent dialogue ...

# Initialize orchestration
workflow ao init --auto

# Create FORGE debate from PRD
workflow forge init-from-prd docs/prd.md my-project

# Start implementation
workflow forge run <debate-id>
```

**Alternative syntax (both work):**
```bash
workflow:init my-project    # Colon syntax
workflow init my-project    # Space syntax (standard)
```

## Architecture

OpenClaw Workflow uses **git submodules** to compose four best-in-class tools:

```
openclaw-workflow/
├── packages/
│   ├── bmad-openclaw/      # Product Requirements Document creation
│   ├── agent-orchestrator/  # Multi-agent orchestration platform
│   ├── forge-ao/            # 10-phase development workflow
│   └── desloppify/          # Code quality harness
├── bin/openclaw            # Unified CLI
├── install.sh              # One-command installer
└── README.md
```

Each submodule points to the official `openclaw-collab` repository and can be updated independently.

### Component Details

| Component | Purpose | Repository |
|-----------|---------|------------|
| **BMAD** | Structured PRD creation through human-AI dialogue | `openclaw-collab/BMAD_Openclaw` |
| **Agent Orchestrator** | Spawn parallel agents, handle CI/CD reactions | `openclaw-collab/agent-orchestrator` |
| **FORGE-AO** | 10-phase development with mandatory debate gates | `openclaw-collab/forge-ao` |
| **Desloppify** | Continuous code quality improvement | `openclaw-collab/desloppify` |

## Unified CLI

The `workflow` command provides a unified interface to all OpenClaw tools:

```
workflow <command> [options]

Commands:
  init [name]              Initialize a new OpenClaw project
  prd [content...]         Create PRD (uses OPENCLAW_PRD_CONTENT env var)
  ao <command>             Agent Orchestrator commands
  forge <command>          FORGE workflow commands
  desloppify [args]        Code quality commands
  status                   Show workflow status
  doctor                   Check installation health

Options:
  --json                   Output JSON (for agents)
  -y, --non-interactive    No prompts (VPS/agent mode)
  -v, --verbose            Verbose output
  -p, --project <name>     Project name
```

**Environment Variables for Agent Mode:**
```bash
export OPENCLAW_PRD_CONTENT="Build a task management app with..."
workflow prd --json --non-interactive
```

### Examples

```bash
# Initialize workflow in current directory
workflow init

# Create PRD through BMAD dialogue
workflow prd

# Initialize AO project
workflow ao init --auto

# Spawn an agent for issue #123
workflow ao spawn my-project 123

# Create FORGE debate from PRD
workflow forge init-from-prd docs/prd.md my-project

# Start debate (spawns advocate, skeptic, operator, synthesizer)
workflow forge run forge-1234567890-abc

# Check debate status
workflow forge status forge-1234567890-abc

# Spawn quality agent
workflow forge desloppify my-project --target 95

# Run security gate (mandatory before review phase)
workflow forge security forge-1234567890-abc

# Check overall workflow status
workflow status
```

## Complete Workflow Tutorial

### Phase 1: Product Requirements (BMAD)

```bash
# Initialize project
mkdir task-app && cd task-app
workflow init

# Start PRD creation
workflow prd
```

The BMAD PM agent guides you through a structured 12-step dialogue:

1. **Vision** - What makes this product unique?
2. **Users** - Who are we building for?
3. **Success** - How do we measure success?
4. **Journeys** - User journey mapping
5. **Domain** - Domain requirements
6. **Innovation** - Competitive differentiation
7. **Scope** - MVP/Growth/Vision scoping
8. **Functional** - Detailed requirements
9. **Non-Functional** - Performance, security
10. **Polish** - Document refinement
11. **Complete** - PRD finalized

Output: `docs/prd.md` with YAML frontmatter and comprehensive requirements.

### Phase 2: Orchestration Setup (AO)

```bash
# Initialize AO project
workflow ao init --auto

# This creates agent-orchestrator.yaml with:
# - Project configuration
# - Plugin settings
# - Reaction rules for CI/CD
```

### Phase 3: FORGE Implementation

```bash
# Create debate from PRD
workflow:forge init-from-prd docs/prd.md task-app

# Output: Created debate forge-1709123456789-abc123

# Run debate (spawns all role sessions)
workflow:forge run forge-1709123456789-abc123
```

**What happens:**
1. FORGE workspace bootstrapped (`.claude/forge/knowledge/`)
2. PRD copied to `brief.md`
3. Sessions spawned with FORGE system prompt
4. Debate roles execute in parallel:
   - **Advocate**: Champions primary approach
   - **Skeptic**: Probes weaknesses
   - **Operator**: Assesses feasibility
   - **Synthesizer**: Produces decision
5. When `synthesis.md` is written, phase auto-advances

**Continue workflow:**
```bash
# Inside FORGE session
/forge:brainstorm  # Explore approaches (with debate)
/forge:research    # Validate with Context7
/forge:design      # System design → UI/UX
/forge:plan        # Surgical implementation
/forge:test        # Risk-based test strategy
/forge:build       # TDD with Ralph loop
/forge:validate    # Evidence-based verification
/forge:review      # Karpathy compliance
/forge:learn       # Pattern extraction
```

### Phase 4: Security Gate (Mandatory)

```bash
# Spawn security reviewer agent
workflow:forge security <debate-id>

# Or with strict mode (fail on high severity)
workflow:forge security <debate-id> --strict

# Security checks performed:
# - Secret scanning (API keys, passwords, tokens)
# - Injection vulnerabilities (SQL, XSS, command)
# - Authentication issues (weak JWT, session fixation)
# - Authorization issues (IDOR, missing access control)
# - Dependency vulnerabilities (npm audit, CVEs)
# - Configuration issues (debug mode, insecure CORS)
```

**Blocking Behavior:**
- Critical issues → **BLOCKS** workflow advancement
- High issues → Warning (blocks with `--strict`)
- Medium/Low → Non-blocking, documented

Security review output: `docs/forge/phases/security.md`

### Phase 5: Quality Assurance (Desloppify)

```bash
# Spawn autonomous quality agent
workflow:forge desloppify task-app --target 95

# Agent continuously improves code:
# - Runs desloppify scan
# - Fixes T1/T2 issues automatically
# - Guides you through T3/T4 improvements
# - Generates scorecard badge
```

### Phase 5: CI/CD Loop (AO Reactions)

```yaml
# agent-orchestrator.yaml
reactions:
  ci-failed:
    auto: true
    action: send-to-agent
    retries: 2
  changes-requested:
    auto: true
    action: send-to-agent
    retries: 1
```

When CI fails or review comments are posted, AO automatically spawns a fix session.

## File Structure

### Project-Level Files

```
my-project/
├── .openclaw/
│   └── config.yaml          # OpenClaw project config
├── .claude/
│   └── forge/
│       ├── active-workflow.md   # Current FORGE phase/status
│       ├── knowledge/
│       │   ├── brief.md         # Project context from PRD
│       │   ├── decisions.md     # Immutable decision registry
│       │   ├── assumptions.md   # Validated assumptions
│       │   ├── constraints.md   # Hard/soft constraints
│       │   ├── risks.md         # Risk registry
│       │   └── glossary.md      # Domain terms
│       └── snapshots/           # Session snapshots
├── docs/
│   ├── prd.md                 # Product Requirements Document
│   └── forge/
│       ├── phases/
│       │   ├── brainstorm.md
│       │   ├── research.md
│       │   ├── design.md
│       │   ├── plan.md
│       │   ├── build.md
│       │   └── ...
│       ├── handoffs/
│       │   ├── brainstorm-to-research.md
│       │   ├── research-to-design.md
│       │   └── ...
│       └── debate/
│           └── forge-1234567890-abc123/
│               ├── debate-plan.md
│               ├── advocate.md
│               ├── skeptic.md
│               ├── operator.md
│               └── synthesis.md
├── src/                       # Implementation
├── agent-orchestrator.yaml    # AO configuration
└── .gitignore
```

## Configuration

### OpenClaw Config (`.openclaw/config.yaml`)

```yaml
project:
  name: my-project
  created: "2024-01-15T10:30:00Z"

workflow:
  prd: bmad
  orchestration: ao
  implementation: forge
  quality: desloppify

paths:
  prd: docs/prd
  forge: docs/forge
  src: src
```

### Agent Orchestrator Config (`agent-orchestrator.yaml`)

```yaml
port: 3000

defaults:
  runtime: tmux
  agent: claude-code
  workspace: worktree
  notifiers: [desktop]

projects:
  my-project:
    repo: owner/my-project
    path: ~/projects/my-project
    defaultBranch: main
    sessionPrefix: mp

reactions:
  ci-failed:
    auto: true
    action: send-to-agent
    retries: 2
  changes-requested:
    auto: true
    action: send-to-agent
    retries: 1
```

### FORGE Config (`.claude/forge/active-workflow.md`)

```yaml
---
workflow: forge
version: "2.0.0"
phase: "brainstorm"
phase_status: "in_progress"
debate_id: "brainstorm-20260115-143022"
debate_status: "pending"
started_at: "2026-01-15T10:30:00Z"
---
```

## Integration Points

### BMAD → AO

- **Trigger**: BMAD step-12 completion
- **Action**: `workflow:forge init-from-prd docs/prd.md <project>`
- **Data**: PRD frontmatter + content → debate plan

### AO → FORGE

- **Trigger**: `ao forge run <debate-id>`
- **Action**: Spawn sessions with:
  - `AO_FORGE_DEBATE_ID`: debate identifier
  - `AO_FORGE_ROLE`: advocate/skeptic/operator/synthesizer
  - `AO_FORGE_PHASE`: current phase
  - `CLAUDE_ENV=forge`: signal FORGE mode
  - `systemPromptFile`: FORGE system prompt

### FORGE ↔ AO State Sync

- **Direction**: Bidirectional
- **Mechanism**: File watchers
- **AO → FORGE**: Session metadata → file markers
- **FORGE → AO**: `active-workflow.md` → session metadata

### FORGE → Desloppify

- **Trigger**: Build phase completion
- **Action**: `workflow:forge desloppify <project>`
- **Data**: Codebase → quality score → fixes

### FORGE Security Gate

- **Trigger**: Before review phase or workflow completion
- **Action**: `workflow:forge security <debate-id>`
- **Blocking**: Critical issues block advancement
- **Output**: `docs/forge/phases/security.md`

## Advanced Usage

### Custom Debate Roles

Create a custom debate plan:

```yaml
# debate-plan.yaml
name: "API Architecture Review"
problem: "Design scalable REST API for user management"

roles:
  - name: architect
    description: "Senior system architect"
    systemPrompt: "You focus on scalability, reliability, maintainability"
    model: "claude-opus-4-6"

  - name: security
    description: "Security engineer"
    systemPrompt: "You identify security risks and best practices"

  - name: performance
    description: "Performance engineer"
    systemPrompt: "You optimize for latency and throughput"

phases:
  - name: design
    description: "Design API structure"
    roles: [architect, security]

  - name: optimize
    description: "Performance optimization"
    roles: [performance, architect]

maxRounds: 2
```

Run it:
```bash
workflow:forge init debate-plan.yaml my-project
workflow:forge run <debate-id>
```

### Continuous Quality

```bash
# Background quality agent
workflow:forge desloppify my-project --target 95 --continuous

# Check status anytime
workflow:status
# Shows: strict_score, T1/T2/T3/T4 counts, open issues
```

### CI/CD Integration

GitHub Actions example:

```yaml
name: OpenClaw Workflow

on:
  issues:
    types: [opened]

jobs:
  implement:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Setup OpenClaw
        run: |
          ./install.sh
          workflow ao init --auto

      - name: Spawn implementation agent
        run: |
          workflow ao spawn my-project ${{ github.event.issue.number }}
```

## Troubleshooting

### Critical: Root User Issues

**Problem:** Claude Code refuses to run as root with error:
```
Claude Code cannot run as root
Claude Code is designed to be run by humans, not root accounts.
```

**Solution - Create and use a non-root user:**

```bash
# Option 1: Create new user (Ubuntu/Debian)
sudo useradd -m -s /bin/bash openclaw
sudo usermod -aG sudo openclaw
sudo passwd openclaw  # set password
su - openclaw

# Option 2: Use existing user
# Just switch to your normal user
su - yourusername

# Option 3: Docker container (for isolated environments)
docker run -it --name openclaw \
  -v $(pwd):/workspace \
  -u 1000:1000 \
  node:22-bookworm bash

# Then inside container:
cd /workspace
git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
./install.sh
```

**VPS Setup Script:**
```bash
#!/bin/bash
# setup-openclaw-vps.sh - Run as root first

# Create openclaw user
useradd -m -s /bin/bash openclaw

# Install Node.js for the user
su - openclaw -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash"
su - openclaw -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\" && nvm install 22"

# Install Python
apt-get update && apt-get install -y python3.11 python3.11-pip git

# Clone and setup
su - openclaw -c "cd ~ && git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git"
su - openclaw -c "cd ~/openclaw-workflow && ./install.sh"

echo "Setup complete. Switch to openclaw user: su - openclaw"
```

### Critical: Claude Code Theme Selection Blocks Automation

**Problem:** AO spawns a session but Claude Code gets stuck on theme selection:
```
Choose your theme
> Dark
  Light
```

**Root Cause:** Claude Code requires interactive theme selection on first run. AO can't automate this.

**Solution 1: Pre-configure Claude Code (Recommended)**
```bash
# Before running AO, manually configure Claude Code once
npm install -g @anthropic-ai/claude-code
claude
# Select theme (Dark/Light), then exit with Ctrl+D

# Now AO can spawn sessions without blocking
workflow ao spawn my-project 123
```

**Solution 2: Use `expect` for Automated Setup**
```bash
# Install expect
sudo apt-get install -y expect  # Ubuntu/Debian
# or: brew install expect        # macOS

# Create automation script
cat > /tmp/claude-first-run.exp << 'EXPECT_EOF'
#!/usr/bin/expect -f
set timeout 10
spawn claude
expect "Choose your theme"
send "\r"  # Accept default (Dark)
expect {
  -re " Claude Code .*" {
    send "\004"  ;# Ctrl+D to exit
  }
  timeout {
    send "\004"  ;# Exit anyway
  }
}
EXPECT_EOF
chmod +x /tmp/claude-first-run.exp
/tmp/claude-first-run.exp
```

**Solution 3: Use tmux for Keystroke Injection**
```bash
# Start claude in detached tmux session
tmux new-session -d -s claude-setup "claude"

# Wait for theme prompt
sleep 3

# Send Enter to select default theme
tmux send-keys -t claude-setup Enter

# Wait for Claude to start
sleep 2

# Exit
tmux send-keys -t claude-setup C-d

# Kill tmux session
tmux kill-session -t claude-setup
```

**Solution 4: Docker with Pre-configured Settings**
```dockerfile
FROM node:22-bookworm

RUN apt-get update && apt-get install -y expect git python3.11

# Create user
RUN useradd -m -s /bin/bash openclaw
USER openclaw
WORKDIR /home/openclaw

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
ENV NVM_DIR=/home/openclaw/.nvm
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install 22"

# Install Claude Code
RUN bash -c "source $NVM_DIR/nvm.sh && npm install -g @anthropic-ai/claude-code"

# Pre-configure with expect
RUN bash -c "source $NVM_DIR/nvm.sh && cat > /tmp/setup.exp << 'EOF'
spawn claude
expect \"Choose your theme\"
send \"\\r\"
expect eof
EOF
expect /tmp/setup.exp" || true

# Now Claude Code is ready for AO
```

**Verification:**
```bash
# Test if Claude Code is configured
claude --version  # Should show version without theme prompt

# Test spawning via AO
workflow ao spawn my-project test-issue
```

### Installation Issues

```bash
# Verify all components
workflow doctor

# Check what failed
workflow doctor --json

# Update submodules
git submodule update --remote --force

# Clean reinstall
rm -rf packages/*/node_modules
rm -rf packages/openclaw-cli/node_modules
./install.sh

# If AO fails to build (web component errors), this is normal
# The CLI will still work - check: which ao
```

### Permission Denied Errors

```bash
# Ensure PATH includes ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Check permissions
ls -la ~/.local/bin/workflow
ls -la ~/.local/bin/ao

# Fix if needed
chmod +x ~/.local/bin/workflow
chmod +x ~/.local/bin/ao

# Re-link if needed
./install.sh
```

### Claude Code Not Found

```bash
# Install Claude Code (requires non-root)
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# If npm global fails, use npx
npx @anthropic-ai/claude-code
```

### Connection Issues

```bash
# Check AO status
workflow ao status

# View session logs
workflow ao session logs <session-id>

# Kill stuck session
workflow ao session kill <session-id>

# Reset AO config
rm agent-orchestrator.yaml
workflow ao init --auto
```

### FORGE State Issues

```bash
# Check FORGE status
workflow status

# View active workflow
cat .claude/forge/active-workflow.md

# Resume workflow
/forge:continue

# If FORGE plugin not loaded in Claude Code:
# 1. Check symlink exists:
ls -la ~/.claude/plugins/forge-ao

# 2. If missing, recreate:
ln -sf /path/to/openclaw-workflow/packages/forge-ao ~/.claude/plugins/forge-ao

# 3. Restart Claude Code
```

### Agent/VPS Mode Issues

**Headless operation (no TTY):**
```bash
# Use --non-interactive or -y flag
workflow init my-project --non-interactive
workflow prd --json -y

# Set environment variable
export OPENCLAW_NON_INTERACTIVE=true
export OPENCLAW_JSON_OUTPUT=true
```

**PRD creation without interaction:**
```bash
# Method 1: Environment variable
export OPENCLAW_PRD_CONTENT="Build a task management app with React and Node.js"
workflow prd --json --non-interactive

# Method 2: Direct content
workflow prd "Build a task management app" --json -y
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes in the relevant submodule
4. Update this meta-repo with submodule changes
5. Submit PR

Each component has its own contribution guidelines:
- [BMAD Contributing](packages/bmad-openclaw/CONTRIBUTING.md)
- [AO Contributing](packages/agent-orchestrator/CONTRIBUTING.md)
- [FORGE Contributing](packages/forge-ao/CONTRIBUTING.md)
- [Desloppify Contributing](packages/desloppify/CONTRIBUTING.md)

## License

MIT License - See [LICENSE](LICENSE) for details.

## Support

- **Documentation**: This README + component READMEs
- **Issues**: [GitHub Issues](https://github.com/openclaw-collab/openclaw-workflow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/openclaw-collab/openclaw-workflow/discussions)

## Acknowledgments

OpenClaw Workflow stands on the shoulders of giants:

- **BMAD** for structured PRD creation
- **Agent Orchestrator** for multi-agent orchestration
- **FORGE** for 10-phase development discipline
- **Desloppify** for continuous quality improvement
