# OpenClaw Workflow - Agent-First Architecture

## Overview

This document describes the agent-first architecture for OpenClaw Workflow, designed for fully autonomous operation by AI agents like OpenClaw.

## Goals

1. **BMAD Plugin**: Generate PRD through natural conversation with agent
2. **Auto-Feed PRD → AO**: PRD automatically spawns AO sessions
3. **Background Desloppify**: Continuous quality improvement running autonomously
4. **FORGE Integration**: Claude Code sessions run through FORGE plugin
5. **Headless Operation**: No human interaction required

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AGENT-FIRST WORKFLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌───────────┐ │
│  │   Agent     │────▶│ BMAD Plugin │────▶│  PRD File   │────▶│   Auto    │ │
│  │  (OpenClaw) │     │  (Dialog)   │     │  (docs/)    │     │  Trigger  │ │
│  └─────────────┘     └─────────────┘     └─────────────┘     └─────┬─────┘ │
│                                                                     │       │
│                          ┌──────────────────────────────────────────┘       │
│                          │                                                   │
│                          ▼                                                   │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌───────────┐  │
│  │  AO Spawn   │◀────│ Auto-Spawn  │────▶│   FORGE     │────▶│  Claude   │  │
│  │  Sessions   │     │   Handler   │     │  Workflow   │     │   Code    │  │
│  └──────┬──────┘     └─────────────┘     └─────────────┘     └───────────┘  │
│         │                                                                    │
│         │         ┌─────────────┐     ┌─────────────┐                        │
│         └────────▶│   Code      │◀────│ Desloppify  │                        │
│                   │   Output    │     │  (Daemon)   │                        │
│                   └─────────────┘     └─────────────┘                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Modifications Required

### 1. BMAD Plugin (Agent Mode)

**File**: `packages/bmad-openclaw/src/index.ts`

**New Feature**: Agent conversation mode

```typescript
// New tool for agent-first PRD creation
export const bmadAgentCreatePRD = {
  name: "bmad-agent-create-prd",
  description: "Interactive PRD creation through agent dialogue",
  parameters: {
    type: "object",
    properties: {
      stage: {
        type: "string",
        enum: ["vision", "users", "requirements", "complete"],
        description: "Current stage of PRD creation"
      },
      userInput: { type: "string", description: "User/agent response" },
      accumulated: { type: "object", description: "Accumulated PRD data" }
    }
  },
  execute: async (id, params, context) => {
    // Stage-based PRD building through conversation
    // Returns next question or complete PRD
  }
};
```

**Environment Variable Support**:
```bash
export OPENCLAW_BMAD_MODE=agent  # agent | interactive | batch
export OPENCLAW_PRD_AUTOSAVE=true
export OPENCLAW_PRD_PATH=docs/prd.md
```

### 2. AO Auto-Spawn Integration

**File**: `packages/agent-orchestrator/packages/cli/src/commands/forge.ts`

**New Feature**: Automatic debate creation from PRD

```typescript
// Watch mode for PRD files
export function registerAutoSpawn(program: Command): void {
  program
    .command("watch-prd")
    .description("Watch PRD file and auto-spawn FORGE workflow")
    .argument("<prd-path>", "Path to PRD file")
    .argument("<project>", "Project ID")
    .option("--auto-run", "Automatically run debate after creation")
    .action(async (prdPath, projectId, options) => {
      // Watch PRD file for changes
      // Auto-create debate when PRD is updated
      // Auto-spawn roles if --auto-run
    });
}
```

**Configuration** (`agent-orchestrator.yaml`):
```yaml
projects:
  my-project:
    repo: owner/repo
    path: ~/projects/my-project
    autoSpawn:
      enabled: true
      prdPath: docs/prd.md
      onPrdChange:
        action: create-forge-debate
        autoRun: true
        roles: [advocate, skeptic, operator, synthesizer]
```

### 3. Desloppify Daemon Mode

**New Feature**: Continuous background quality monitoring

```bash
# Start desloppify daemon
desloppify daemon start \
  --watch ./src \
  --auto-fix \
  --notify-on-change \
  --config .desloppify-daemon.yaml

# Configuration file
```yaml
# .desloppify-daemon.yaml
daemon:
  enabled: true
  watch_paths:
    - ./src
    - ./lib
  auto_fix:
    enabled: true
    severity: [t1, t2]  # Only auto-fix T1/T2 issues
  notify:
    on_fix: true
    on_failure: true
  interval: 30s  # Scan interval
  ignore:
    - "**/node_modules/**"
    - "**/*.test.ts"
```

**Integration with AO**:
```typescript
// AO spawns desloppify daemon as background session
await sm.spawn({
  projectId,
  agent: 'desloppify-daemon',
  runtime: 'background',
  env: {
    DESLOPPIFY_WATCH: './src',
    DESLOPPIFY_AUTO_FIX: 'true'
  }
});
```

### 4. FORGE Agent Mode

**File**: `packages/forge-ao/commands/agent-mode.md`

**New FORGE Command**: `/forge:agent-start`

Designed for headless agent operation:

```markdown
---
command: agent-start
name: agent-start
description: Start FORGE workflow in agent/autonomous mode
---

# FORGE Agent Mode

## Purpose
Run FORGE workflow without human interaction, designed for AI agents.

## Usage
```bash
/forge:agent-start --prd=docs/prd.md --project=my-project --output=./output
```

## Options
- `--prd <path>`: Path to PRD file
- `--project <name>`: Project identifier
- `--output <dir>`: Output directory for artifacts
- `--phases <list>`: Phases to run (default: all)
- `--parallel`: Run phases in parallel where possible
- `--notify <url>`: Webhook URL for completion notifications

## Agent Integration
When running in agent mode, FORGE:
1. Reads PRD automatically
2. Runs all phases without prompts
3. Outputs JSON progress to stdout
4. Writes artifacts to specified output dir
5. Calls webhook on completion/failure
```

## Implementation Details

### Headless Configuration

**Environment Variables**:
```bash
# Global headless mode
export OPENCLAW_HEADLESS=true
export OPENCLAW_JSON_OUTPUT=true
export OPENCLAW_AUTO_APPROVE=true

# BMAD
export BMAD_AGENT_MODE=true
export BMAD_NO_PROMPTS=true

# AO
export AO_AUTO_SPAWN=true
export AO_HEADLESS=true

# FORGE
export FORGE_AGENT_MODE=true
export FORGE_NO_INTERACTION=true

# Desloppify
export DESLOPPIFY_DAEMON=true
export DESLOPPIFY_AUTO_FIX=true
```

### Unified Agent CLI

**New Command**: `workflow agent`

```bash
# Full agent workflow
workflow agent start \
  --project my-project \
  --from-prd docs/prd.md \
  --auto-fix \
  --background-quality

# Options:
#   --project <name>          Project identifier
#   --from-prd <path>         Start from existing PRD
#   --create-prd              Create PRD through agent dialogue
#   --auto-fix                Enable automatic issue fixing
#   --background-quality      Run desloppify in background
#   --parallel                Run phases in parallel
#   --notify <webhook>        Completion webhook
#   --output <dir>            Output directory
```

### Agent Communication Protocol

**JSON Lines Protocol** for agent communication:

```json
{"type": "stage.start", "stage": "prd.creation", "message": "Starting PRD creation"}
{"type": "stage.question", "stage": "prd.creation", "question": "What problem does this solve?"}
{"type": "stage.complete", "stage": "prd.creation", "output": "docs/prd.md"}
{"type": "stage.start", "stage": "ao.spawn", "message": "Spawning AO sessions"}
{"type": "progress", "phase": "brainstorm", "percent": 45}
{"type": "issue.found", "tool": "desloppify", "severity": "t1", "file": "src/index.ts"}
{"type": "issue.fixed", "tool": "desloppify", "file": "src/index.ts"}
{"type": "complete", "success": true, "outputs": ["docs/prd.md", "src/", "tests/"]}
```

## Integration Points

### 1. BMAD → AO Auto-Integration

**Trigger**: When PRD file is written
**Action**: Automatically call AO to create FORGE debate

```typescript
// In BMAD save artifact tool
if (process.env.OPENCLAW_AUTO_AO === 'true') {
  await spawn('ao', ['forge', 'init-from-prd', prdPath, projectId]);
  if (process.env.OPENCLAW_AUTO_RUN === 'true') {
    await spawn('ao', ['forge', 'run', debateId]);
  }
}
```

### 2. AO → Desloppify Auto-Integration

**Trigger**: When FORGE build phase completes
**Action**: Spawn desloppify daemon

```typescript
// In AO spawn handler
if (forgePhase === 'build-complete' && config.autoQuality !== false) {
  await sm.spawn({
    projectId,
    agent: 'desloppify-daemon',
    runtime: 'background'
  });
}
```

### 3. Desloppify → AO Feedback Loop

**Trigger**: When desloppify finds issues
**Action**: Notify AO to spawn fix session

```yaml
# desloppify-daemon.yaml
on_issue:
  severity_t1:
    action: auto_fix
  severity_t2:
    action: auto_fix
  severity_t3:
    action: notify_ao
    ao_action: spawn_fix_session
  severity_t4:
    action: log_only
```

## Files Modified

### Core Files
1. `packages/bmad-openclaw/src/index.ts` - Add agent mode tools
2. `packages/bmad-openclaw/src/tools/bmad-agent-prd.ts` - New file
3. `packages/agent-orchestrator/packages/cli/src/commands/forge.ts` - Add watch mode
4. `packages/agent-orchestrator/packages/cli/src/lib/auto-spawn.ts` - New file
5. `packages/forge-ao/commands/agent-mode.md` - New command
6. `packages/openclaw-cli/src/agent-commands.ts` - New file

### Configuration Files
1. `packages/bmad-openclaw/agent-config.yaml` - Agent mode config
2. `packages/agent-orchestrator/auto-spawn.yaml` - Auto-spawn rules
3. `packages/desloppify/daemon-config.yaml` - Daemon configuration

## Usage Examples

### Full Agent Workflow

```bash
# 1. Set environment
export OPENCLAW_HEADLESS=true
export OPENCLAW_PROJECT=my-app

# 2. Initialize
workflow agent init --project my-app

# 3. Create PRD through agent dialogue
workflow agent create-prd
# Agent asks: "What are we building?"
# Agent asks: "Who are the users?"
# ... continues until PRD complete

# 4. Auto-spawn AO + FORGE
workflow agent start --from-prd docs/prd.md --auto-fix

# 5. Monitor progress
workflow agent status --json
# Output: {"phase": "build", "progress": 65, "issues_found": 3, "issues_fixed": 2}

# 6. Get results
workflow agent output
# Returns: Path to generated code, tests, docs
```

### VPS/CI Usage

```bash
#!/bin/bash
# deploy.sh - Fully automated deployment

export OPENCLAW_HEADLESS=true
export OPENCLAW_JSON_OUTPUT=true
export OPENCLAW_WEBHOOK="https://myapp.com/webhook/openclaw"

workflow agent start \
  --project production-app \
  --from-prd docs/prd.md \
  --auto-fix \
  --background-quality \
  --output ./build
```

## Success Criteria

1. ✅ BMAD can generate PRD through agent conversation
2. ✅ PRD automatically triggers AO session spawning
3. ✅ Desloppify runs continuously fixing issues
4. ✅ FORGE operates in headless mode
5. ✅ All output is JSON-parseable for agents
6. ✅ No human prompts in headless mode
7. ✅ Complete workflow runs autonomously

## Migration Path

### From v2.0 to Agent-First

1. Add agent mode config
2. Enable auto-spawn in AO config
3. Start desloppify daemon
4. Use `workflow agent` commands instead of individual commands

### Backward Compatibility

All existing commands continue to work:
- `workflow init` - Interactive mode
- `workflow prd` - Interactive mode
- `workflow ao init` - Interactive mode

New agent commands are additive:
- `workflow agent init` - Headless mode
- `workflow agent create-prd` - Agent dialogue mode
- `workflow agent start` - Full autonomous workflow
