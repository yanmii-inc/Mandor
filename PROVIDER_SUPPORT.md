# Multi-Provider LLM Support

AgentFlow now supports three LLM providers: **Anthropic (Claude)**, **Google Gemini**, and **Alibaba GLM**.

## Configuration

Each provider requires:
1. An API key (stored in the agent profile)
2. A model name (optional, uses defaults if not specified)

### Creating Agent Profiles

```bash
# Claude (Anthropic) — uses Claude Agent SDK
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-claude",
    "agent_type": "claude",
    "credentials_encrypted": "sk-ant-v0..."
  }'

# Gemini (Google)
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-gemini",
    "agent_type": "gemini",
    "credentials_encrypted": "AIzaSy...",
    "cli_path": "gemini-2.0-flash"
  }'

# GLM (Alibaba)
curl -X POST http://localhost:3000/agent-profiles \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-glm",
    "agent_type": "glm",
    "credentials_encrypted": "sk-...",
    "cli_path": "glm-4-air"
  }'
```

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
