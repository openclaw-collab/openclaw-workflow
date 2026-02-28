# OpenClaw Workflow

**One repo to rule them all.**

Unified workflow combining BMAD PRD → AO Orchestration → FORGE Implementation → Desloppify Quality.

## Quick Start

```bash
# Clone with all submodules
git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
cd openclaw-workflow

# One-command install
./install.sh

# Create a new project
mkdir my-project && cd my-project
openclaw init

# Start the workflow
openclaw prd        # Create PRD with BMAD
openclaw ao init    # Initialize AO
openclaw forge ...  # Start FORGE
```

## What's Included

| Component | Purpose | Location |
|-----------|---------|----------|
| **BMAD Openclaw** | PRD creation workflow | `packages/bmad-openclaw/` |
| **Agent Orchestrator** | Multi-agent orchestration | `packages/agent-orchestrator/` |
| **FORGE-AO** | 10-phase development workflow | `packages/forge-ao/` |
| **Desloppify** | Code quality harness | `packages/desloppify/` |

## Unified CLI

The `openclaw` command provides a single entry point:

```bash
openclaw init                    # Initialize project
openclaw prd                     # Create PRD (BMAD)
openclaw ao init --auto          # Initialize AO
openclaw ao spawn my-project 123 # Spawn agent
openclaw forge init-from-prd ... # Start FORGE
openclaw desloppify scan         # Quality scan
openclaw status                  # Show status
openclaw doctor                  # Health check
```

## Workflow

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  BMAD   │────▶│   AO    │────▶│  FORGE  │────▶│Desloppify│
│  (PRD)  │     │(Spawn)  │     │(Implement)│    │(Quality) │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
```

1. **BMAD**: Create comprehensive PRD through structured dialogue
2. **AO**: Orchestrate parallel agents, manage CI/review loops
3. **FORGE**: Execute 10-phase development with debate gates
4. **Desloppify**: Continuous quality improvement

## Architecture

This is a **meta-repo** using git submodules:

```
openclaw-workflow/
├── install.sh              # One-command installer
├── bin/openclaw           # Unified CLI
├── packages/
│   ├── bmad-openclaw/     # git submodule
│   ├── agent-orchestrator/ # git submodule
│   ├── forge-ao/          # git submodule
│   └── desloppify/        # git submodule
└── README.md
```

Each submodule points to the official openclaw-collab repositories.

## Installation Requirements

- Node.js 18+
- Python 3.11+
- Git
- Claude Code (optional but recommended)

## Development

Update submodules:

```bash
git submodule update --remote
```

Add new submodule:

```bash
git submodule add https://github.com/openclaw-collab/new-repo.git packages/new-repo
```

## License

MIT - See individual submodule licenses.
