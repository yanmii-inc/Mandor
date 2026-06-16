# Multi-Provider LLM Support

AgentFlow now supports three LLM providers: **Anthropic (Claude)**, **Google Gemini**, and **Alibaba GLM**.

## Models & Switching

A **provider** (`agent_type`) is distinct from a **model**. Each provider exposes several
models, and you can switch between them in two ways:

1. **Per-profile default** — set the `model` field on an agent profile. Used whenever a task
   doesn't specify its own.
2. **Per-task override** — set the `model` field when creating a task. Takes precedence over the
   profile default for that one task.

Resolution order: `task.model` → `profile.model` → provider's catalog default.

### Discover available models

```bash
curl http://localhost:3000/models
# => { "claude": [{id,label}...], "gemini": [...], "glm": [...] }
```

Only models in this catalog are accepted; an invalid `model` returns a 400 with the allowed list.
The catalog lives in `src/agents/models.ts` (single source of truth).

## Configuration

Each provider requires:
1. An API key (stored in the agent profile as `credentials_encrypted`)
2. A model (optional — falls back to the provider default from the catalog)

### Creating Agent Profiles

```bash
# Claude (Anthropic) — uses Claude Agent SDK
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-claude",
    "agent_type": "claude",
    "credentials_encrypted": "sk-ant-v0...",
    "model": "claude-sonnet-4-5-20250929"
  }'

# Gemini (Google)
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-gemini",
    "agent_type": "gemini",
    "credentials_encrypted": "AIzaSy...",
    "model": "gemini-2.0-flash"
  }'

# GLM (Alibaba)
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-glm",
    "agent_type": "glm",
    "credentials_encrypted": "sk-...",
    "model": "glm-4-air"
  }'
```

### Switching a profile's default model

```bash
curl -X PATCH http://localhost:3000/agent-profiles/<id> \
  -H "Content-Type: application/json" \
  -d '{ "model": "gemini-1.5-pro" }'
```

### Overriding the model for a single task

```bash
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "<id>",
    "description": "Fix the failing test",
    "model": "claude-opus-4-20250514"
  }'
```

> Note: `model` is now a first-class field. (It used to be crammed into `cli_path`; that hack
> is gone — `cli_path` is reserved for an agent's CLI binary path.)

## Environment Variables

Set defaults if not storing credentials in profiles:

```bash
ANTHROPIC_API_KEY=sk-ant-v0...
GEMINI_API_KEY=AIzaSy...
GLM_API_KEY=sk-...
```

## Implementation Details

### Shared Tool System (`src/agents/llm-coding-tools.ts`)

All providers implement the same three tools:
- **read_file** — Read file contents
- **write_file** — Write/create files with auto-mkdir
- **bash** — Execute shell commands for git, tests, builds, etc.

This ensures consistent behavior across providers.

### Provider Adapters

**Claude** (`src/agents/claude.ts`)
- Uses native `@anthropic-ai/claude-agent-sdk`
- Supports session resumption via `session_id`
- Direct message streaming

**Gemini** (`src/agents/gemini.ts`)
- REST API: `generativelanguage.googleapis.com/v1beta/models`
- Function calling for tool use
- Default model: `gemini-2.0-flash`

**GLM** (`src/agents/glm.ts`)
- OpenAI-compatible format
- REST API: `open.bigmodel.cn/api/paas/v4/chat/completions`
- Function calling for tool use
- Default model: `glm-4-air`

### Task Complexity Preflight

The preflight analysis now supports all providers:
- Uses the same system prompt for complexity classification
- Automatically detects provider from agent profile
- Falls back to default models for estimation

## Database Schema

Agent profiles now include two new types in the CHECK constraint:
- `'gemini'`
- `'glm'`

Migration 2 (auto-applied on first run) handles this upgrade for existing databases.

## Usage

1. Create an agent profile with your provider and API key
2. Create a project and link it to the agent profile
3. Create a task — the system will auto-detect the provider and route accordingly
4. The agent will use the shared tool system (read/write/bash) regardless of provider

All providers follow the same autonomous workflow: explore, implement, test, commit, push, and open a PR.
