<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/agentflow-v0.1.0-6C5CE7?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxOCIgc3Ryb2tlPSIjNkM1Q0U3IiBzdHJva2Utd2lkdGg9IjIiLz48cGF0aCBkPSJNMTIgMjBsNiA2IDEwLTEwIiBzdHJva2U9IiM2QzVDRTciIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+PC9zdmc+">
  <img alt="agentflow" src="https://img.shields.io/badge/agentflow-v0.1.0-6C5CE7?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxOCIgc3Ryb2tlPSIjNkM1Q0U3IiBzdHJva2Utd2lkdGg9IjIiLz48cGF0aCBkPSJNMTIgMjBsNiA2IDEwLTEwIiBzdHJva2U9IiM2QzVDRTciIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+PC9zdmc+">
</picture>

<h1 align="center">agentflow</h1>

<p align="center">
  <em>Self-hosted remote AI coding agent orchestrator.</em><br>
  Dispatch tasks from any device → agents implement them on your VM → review as PRs.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/runtime-Bun-000?style=flat-square&logo=bun">
  <img src="https://img.shields.io/badge/lang-TypeScript-3178C6?style=flat-square&logo=typescript">
  <img src="https://img.shields.io/badge/db-SQLite-003B57?style=flat-square&logo=sqlite">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square">
</p>

---

## Overview

**agentflow** runs on a remote VM, accepts tasks via a REST API, spawns AI coding agents (Claude Code, OpenCode, Aider, Cline, Copilot CLI) in **isolated git worktrees**, and streams their output to any device via SSE.

You act as PM and tech lead — dispatching tasks from your phone, tablet, or laptop while agents do the implementation. Each task ends with a GitHub PR, ready for your review.

```
┌──────────────┐     POST /tasks     ┌──────────────────┐
│  Your Phone  │ ──────────────────► │                  │
│  Your Laptop │                     │   agentflow VM   │
│  Your Tablet │ ◄────────────────── │                  │
└──────────────┘   SSE event stream  │  ┌────────────┐  │
                                      │  │ Worktree 1 │──► PR #1
                                      │  ├────────────┤  │
                                      │  │ Worktree 2 │──► PR #2
                                      │  ├────────────┤  │
                                      │  │ Worktree 3 │──► PR #3
                                      │  └────────────┘  │
                                      └──────────────────┘
```

---

## Features

- **🔌 Agent-agnostic** — Claude Code (native SDK), OpenCode, Aider, Cline, Copilot CLI
- **🔒 Isolated execution** — every task runs in its own `git worktree`, never touches `main`
- **📡 Real-time streaming** — SSE `text/event-stream` per task, watch agents work from any browser
- **💬 Resumable conversations** — send follow-ups from any device; Claude sessions persist via `session_id`
- **🧠 Preflight checks** — Haiku classifies task complexity; complex tasks require explicit approval
- **🔄 Auto PRs** — agent commits, pushes, opens a GitHub PR when done
- **📊 Token tracking** — usage logged per task, aggregated summary endpoint
- **🔐 Credential safety** — API keys encrypted at rest in SQLite, never exposed via API
- **📦 Single binary** — `bun build --compile` produces a self-contained executable

---

## Quick Start

### Prerequisites

- [Bun](https://bun.sh) >= 1.2
- [Git](https://git-scm.com) >= 2.30
- [GitHub CLI](https://cli.github.com) `gh` (for automated PRs)

### Install & Run

```bash
# Clone and install
git clone <your-repo>/agentflow.git && cd agentflow
bun install

# Start the server
bun run src/index.ts

# Or build a single binary
bun build --compile
```

The server starts on `http://0.0.0.0:3000`.

### Configure

```bash
# Create a project
curl -X POST http://localhost:3000/projects \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "my-app",
    "repo_url": "https://github.com/you/my-app.git",
    "local_path": "/home/ubuntu/my-app"
  }'

# Create an agent profile
curl -X POST http://localhost:3000/agent-profiles \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "claude-dev",
    "agent_type": "claude"
  }'
```

### Dispatch Your First Task

```bash
curl -X POST http://localhost:3000/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "project_id": "<project-id>",
    "description": "Add user authentication with JWT tokens. Include login, register, and refresh endpoints."
  }'

# Watch it work in real-time
curl -N http://localhost:3000/tasks/<task-id>/logs
```

---

## API Reference

### Projects

```
POST /projects              Create a project
GET  /projects              List all projects
```

**`POST /projects`**
```json
{
  "name": "my-app",
  "repo_url": "https://github.com/you/my-app.git",
  "local_path": "/home/ubuntu/my-app",
  "agent_profile_id": "optional-uuid",
  "deploy_config": "optional-json-string"
}
```

### Agent Profiles

```
POST /agent-profiles        Create an agent profile
GET  /agent-profiles        List all profiles
```

**`POST /agent-profiles`**
```json
{
  "name": "claude-dev",
  "agent_type": "claude",
  "cli_path": "/usr/local/bin/claude",
  "credentials_encrypted": "optional-encrypted-api-key"
}
```

**`agent_type`** — one of: `claude`, `opencode`, `aider`, `cline`, `copilot`

### Tasks

```
POST /tasks                 Dispatch a new task
GET  /tasks                 List tasks (?project_id=...)
GET  /tasks/:id             Task detail
GET  /tasks/:id/logs        SSE event stream
POST /tasks/:id/confirm     Approve a complex task
POST /tasks/:id/reply       Send a follow-up message
DELETE /tasks/:id           Kill a running task
```

**`POST /tasks`**
```json
{
  "project_id": "uuid",
  "agent_profile_id": "optional-uuid",
  "description": "Natural language task description"
}
```

**`POST /tasks/:id/reply`**
```json
{
  "message": "Great start, but can you also add rate limiting?"
}
```

### Tokens

```
GET /tokens                 Token usage summary across all tasks
```

### Task Lifecycle

```
pending ──► running ──► pr_ready ──► merged
                  │                    │
                  └──► failed          └──► failed
```

- **pending** — task created, preflight running or waiting for confirmation
- **running** — agent actively working in an isolated worktree
- **pr_ready** — agent finished, changes committed, PR created
- **merged** — PR merged (manual, via GitHub)
- **failed** — agent errored or was killed

---

## How It Works

### The `AgentAdapter` Interface

Every agent CLI (Claude Code, OpenCode, Aider, etc.) is wrapped in a uniform interface:

```typescript
interface AgentAdapter {
  start(task: Task, worktreePath: string): Promise<void>
  resume(sessionId: string, message: string): Promise<void>
  stream(): AsyncIterable<AgentMessage>
  getTokenUsage(): TokenUsage
  kill(): Promise<void>
}
```

This means **adding a new agent** is just implementing 5 methods.

### Claude Code — Native SDK Integration

agentflow uses `@anthropic-ai/claude-agent-sdk` directly — not a subprocess. This enables:

- **Session persistence** — `session_id` is captured on first dispatch and stored in the database
- **Multi-device follow-ups** — `POST /tasks/:id/reply` resumes the exact agent session via `resume: sessionId`
- **Full context continuity** — the agent remembers files it read, changes it made, decisions it took

```typescript
// First dispatch — save session_id
for await (const msg of query({ prompt: description, options: { permissionMode: 'acceptEdits' } })) {
  if (msg.session_id) await db.updateTask(task.id, { session_id: msg.session_id })
}

// Follow-up from any device
for await (const msg of query({ prompt: followUp, options: { resume: savedSessionId } })) {
  // Stream continues with full context
}
```

### Git Worktree Isolation

```
main ────── agent/abc123-add-auth ────── worktree at ../.worktrees/abc123
     \────── agent/def456-fix-bug ────── worktree at ../.worktrees/def456
```

- Each task gets its own branch and worktree
- Agents can never touch `main`
- On success: agent commits → pushes → opens PR → worktree removed
- On failure: worktree removed, branch deleted

### Preflight Complexity Check

Before any agent runs, Claude Haiku analyzes the task:

```json
{
  "complexity": "simple | medium | complex",
  "estimated_tokens": { "min": 1000, "max": 5000 },
  "reasoning": "Clear requirements, ~3 files affected, low risk"
}
```

- **simple/medium** → dispatched immediately
- **complex** → stays `pending`, requires `POST /tasks/:id/confirm`

### SSE Streaming

`GET /tasks/:id/logs` returns a `text/event-stream`:

```
event: log
data: {"id":1,"task_id":"...","role":"agent","chunk":"Analyzing the codebase...","timestamp":"..."}

event: message
data: {"type":"text","content":"I found the relevant files...","timestamp":"..."}

event: done
data: {"taskId":"..."}
```

---

## Project Structure

```
agentflow/
├── src/
│   ├── api/
│   │   ├── routes/
│   │   │   ├── tasks.ts          ← Task CRUD + SSE + reply + confirm
│   │   │   ├── projects.ts       ← Project CRUD
│   │   │   ├── agents.ts         ← Agent profile CRUD
│   │   │   └── tokens.ts         ← Token usage summary
│   │   └── server.ts             ← Bun HTTP server, request routing
│   ├── agents/
│   │   ├── base.ts               ← AgentAdapter interface, shared types
│   │   ├── claude.ts             ← @anthropic-ai/claude-agent-sdk
│   │   ├── opencode.ts           ← execa subprocess adapter
│   │   ├── aider.ts              ← execa subprocess adapter
│   │   └── registry.ts           ← Profile → adapter resolver
│   ├── orchestrator/
│   │   ├── index.ts              ← Task lifecycle, SSE broadcast
│   │   ├── worktree.ts           ← git worktree create/commit/PR/cleanup
│   │   ├── preflight.ts          ← Haiku complexity classification
│   │   └── tokens.ts             ← Per-task token usage tracking
│   ├── db/
│   │   ├── schema.ts             ← SQLite DDL
│   │   └── index.ts              ← Database wrapper (CRUD)
│   └── index.ts                  ← Entry point
├── package.json
├── tsconfig.json
└── bunfig.toml
```

---

## Data Model

```sql
-- Agent CLI configurations with encrypted credentials
agent_profiles (id, name, agent_type, cli_path, credentials_encrypted, created_at)

-- Git repos the orchestrator manages
projects (id, name, repo_url, local_path, agent_profile_id, deploy_config, created_at)

-- Individual task dispatches
tasks (id, project_id, agent_profile_id, description, status, worktree_path,
       branch_name, pr_url, session_id, complexity, token_usage, confirmed,
       created_at, updated_at)

-- Streaming log of user messages + agent responses
task_logs (id, task_id, role, chunk, timestamp)
```

The `task_logs.role` field (`'user' | 'agent'`) means the full conversation thread — every message you send and every response the agent produces — is stored together, forming a persistent, resumable thread.

---

## Deployment

### As a System Service (Linux)

```ini
[Unit]
Description=agentflow
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/agentflow
ExecStart=/opt/agentflow/agentflow
Environment=PORT=3000
Environment=HOST=0.0.0.0
Environment=AGENTFLOW_DB_PATH=/opt/agentflow/data/agentflow.db
Restart=always

[Install]
WantedBy=multi-user.target
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP server port |
| `HOST` | `0.0.0.0` | HTTP server host |
| `AGENTFLOW_DB_PATH` | `agentflow.db` | SQLite database path |
| `ANTHROPIC_API_KEY` | — | API key for Claude (preflight + SDK) |

---

## Roadmap

- [ ] Dashboard UI (mobile-first web app)
- [ ] Slack / Discord webhook notifications
- [ ] Batch dispatch (one description → N agents, compare results)
- [ ] Approval workflows before PR merge
- [ ] Agent tool use limits and budget controls
- [ ] Auto preview deployments (Vercel, Netlify, Railway)
- [ ] kubernetes CRD operator

---

## Philosophy

> **agentflow is pure infrastructure.**

It knows nothing about what runs inside your projects. It doesn't care if you use Python, Go, Rust, or Node. It doesn't care about your framework choices. It just:
1. Takes a task description
2. Spawns an agent in an isolated worktree
3. Streams the output back
4. Opens a PR

You bring the projects, the agents, and the review process. agentflow brings the orchestration.

---

<p align="center">
  <sub>Built with ❤️ for solo engineers who want to ship faster.</sub>
</p>
