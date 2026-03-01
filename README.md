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

### One-Command Installation

```bash
# Clone with all submodules
git clone --recursive https://github.com/openclaw-collab/openclaw-workflow.git
cd openclaw-workflow

# Install everything
./install.sh

# Verify installation
openclaw doctor
```

### Start a New Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Initialize OpenClaw workflow
openclaw init

# Create Product Requirements Document
openclaw prd
# ... follow the BMAD agent dialogue ...

# Initialize orchestration
openclaw ao init --auto

# Create FORGE debate from PRD
openclaw forge init-from-prd docs/prd.md my-project

# Start implementation
openclaw forge run <debate-id>
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

The `openclaw` command provides a single entry point for all workflow operations:

```
openclaw <command> [options]

Commands:
  init                    Initialize a new OpenClaw project
  prd                     Start BMAD PRD creation workflow
  ao <command>            Agent Orchestrator commands
  forge <command>         FORGE workflow commands
  desloppify <command>    Code quality commands
  status                  Show workflow status
  doctor                  Check installation health
```

### Examples

```bash
# Initialize workflow in current directory
openclaw init

# Create PRD through BMAD dialogue
openclaw prd

# Initialize AO project
openclaw ao init --auto

# Spawn an agent for issue #123
openclaw ao spawn my-project 123

# Create FORGE debate from PRD
openclaw forge init-from-prd docs/prd.md my-project

# Start debate (spawns advocate, skeptic, operator, synthesizer)
openclaw forge run forge-1234567890-abc

# Check debate status
openclaw forge status forge-1234567890-abc

# Spawn quality agent
openclaw forge desloppify my-project --target 95

# Check overall workflow status
openclaw status
```

## Complete Workflow Tutorial

### Phase 1: Product Requirements (BMAD)

```bash
# Initialize project
mkdir task-app && cd task-app
openclaw init

# Start PRD creation
openclaw prd
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
openclaw ao init --auto

# This creates agent-orchestrator.yaml with:
# - Project configuration
# - Plugin settings
# - Reaction rules for CI/CD
```

### Phase 3: FORGE Implementation

```bash
# Create debate from PRD
openclaw forge init-from-prd docs/prd.md task-app

# Output: Created debate forge-1709123456789-abc123

# Run debate (spawns all role sessions)
openclaw forge run forge-1709123456789-abc123
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

### Phase 4: Quality Assurance (Desloppify)

```bash
# Spawn autonomous quality agent
openclaw forge desloppify task-app --target 95

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
- **Action**: `openclaw forge init-from-prd docs/prd.md <project>`
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
- **Action**: `openclaw forge desloppify <project>`
- **Data**: Codebase → quality score → fixes

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
openclaw forge init debate-plan.yaml my-project
openclaw forge run <debate-id>
```

### Continuous Quality

```bash
# Background quality agent
openclaw forge desloppify my-project --target 95 --continuous

# Check status anytime
openclaw status
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
          openclaw ao init --auto

      - name: Spawn implementation agent
        run: |
          openclaw ao spawn my-project ${{ github.event.issue.number }}
```

## Troubleshooting

### Installation Issues

```bash
# Verify all components
openclaw doctor

# Update submodules
git submodule update --remote

# Reinstall
./install.sh
```

### Connection Issues

```bash
# Check AO status
openclaw ao status

# View session logs
openclaw ao session logs <session-id>

# Kill stuck session
openclaw ao session kill <session-id>
```

### FORGE State Issues

```bash
# Check FORGE status
openclaw status

# View active workflow
cat .claude/forge/active-workflow.md

# Resume workflow
/forge:continue
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
