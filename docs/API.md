# API Reference

## Base URL

All endpoints are served from `http://<host>:<port>`. Default: `http://0.0.0.0:3000`.

## Models

Models are **not** curated in a catalog — each agent reports what it supports at runtime. How the model list is sourced depends on the agent:

| Agent | Model list source | Picker behavior |
|---|---|---|
| `claude` | Live `GET /v1/models` on Anthropic (paginated) | dropdown |
| `gemini` | Live `GET /v1beta/models` on Google, filtered to `generateContent` | dropdown |
| `glm` | Live `GET /v4/models` on Zhipu (undocumented; falls back to free-form on failure) | dropdown or free-form |
| `opencode`, `aider` | Open universe — any `provider/model` string | free-form text |
| `cline`, `copilot` | No adapter yet (passthrough) | free-form text |

The `model` field on tasks/threads/profiles is therefore **free-form**: it is not validated against a fixed list. The provider/CLI is the real validator at runtime. Discovery is best-effort — a missing/invalid key or an unsupported list endpoint degrades gracefully to a free-form field rather than erroring.

### Discover Models for a Profile

```
GET /agent-profiles/:id/models
GET /agent-profiles/:id/models?refresh=true
```

Resolves the profile's agent and queries its model list (see table above). Results are cached per profile for ~10 minutes; `?refresh=true` bypasses the cache. The cache is also invalidated automatically when the profile's credentials change.

Returns `200`:

```json
{
  "models": [
    { "id": "glm-5.2", "label": "glm-5.2" },
    { "id": "glm-4.7", "label": "glm-4.7" }
  ],
  "freeForm": false
}
```

`freeForm` is `true` when the agent exposes no list (CLI agents, or API agents whose discovery failed) — the client should render a free-text model field.

Returns `404` if the profile doesn't exist. Discovery failures never return a 5xx; they return `{ "models": [], "freeForm": true }`.

### `GET /models` (deprecated)

Returns `{}`. The old hardcoded-per-provider catalog was removed in favor of per-profile discovery above.


## Projects

### Create a Project

```
POST /projects
```

```json
{
  "name": "my-app",
  "repo_url": "https://github.com/you/my-app.git",
  "local_path": "/home/ubuntu/my-app",
  "agent_profile_id": "optional-uuid",
  "targets": [
    {
      "name": "production",
      "path": "/var/www/app",
      "deploy_command": "npm run build && pm2 restart app"
    }
  ]
}
```

Returns `201` with the created project (including any targets).

### Scan Workspace Roots

```
POST /projects/scan
```

Scans directories for `.mandor.json` sign files. Upserts discovered projects (keyed by `local_path`) and deletes stale scan-sourced projects whose sign file was removed.

The roots to scan are resolved in this order:

1. `roots` field in the request body (optional)
2. `WORKSPACE_ROOTS` env var (JSON array or comma-separated)
3. `~/.mandor/config.json` → `workspaceRoots`
4. Server's current working directory (`process.cwd()`)

Request body (optional):

```json
{
  "roots": ["~/code", "~/work"]
}
```

Returns `200`:

```json
{
  "created": 2,
  "updated": 1,
  "deleted": 0,
  "projects": [
    {
      "id": "uuid",
      "name": "my-app",
      "repo_url": "https://github.com/you/my-app.git",
      "local_path": "/home/you/code/my-app",
      "agent_profile_id": null,
      "source": "scan",
      "created_at": "2026-06-21 10:11:16"
    }
  ]
}
```

### List Projects

```
GET /projects
```

Returns `200` with an array of projects. Each project now includes a `source` field:

| `source` | Meaning |
|---|---|
| `manual` | Created via `POST /projects` — never auto-deleted |
| `scan` | Discovered from a `.mandor.json` sign file — auto-deleted when the file is removed |

### Delete a Project

```
DELETE /projects/:id
```

Removes the `.mandor.json` sign file from disk and deletes the project and all associated records (tasks, deploy targets, threads). Returns `204`.

### Deploy Targets

#### Create a Deploy Target

```
POST /projects/:id/targets
```

```json
{
  "name": "staging",
  "path": "/var/www/staging",
  "deploy_command": "docker compose up -d --build"
}
```

Returns `201`.

#### List Deploy Targets

```
GET /projects/:id/targets
```

Returns `200` with an array of deploy targets.

#### Update a Deploy Target

```
PUT /projects/:id/targets/:targetId
```

```json
{
  "deploy_command": "npm run build && pm2 restart app"
}
```

Returns `200`.

#### Delete a Deploy Target

```
DELETE /projects/:id/targets/:targetId
```

Returns `204`.

## Agent Profiles

### Create an Agent Profile

```
POST /agent-profiles
```

```json
{
  "name": "my-claude",
  "agent_type": "claude",
  "cli_path": "/usr/local/bin/claude",
  "credentials_encrypted": "sk-ant-v0...",
  "model": "claude-sonnet-4-5-20250929"
}
```

`agent_type` must be one of: `claude`, `gemini`, `glm`, `opencode`, `aider`, `cline`, `copilot`.

| Provider | API Key Source | Fallback model (when none chosen) |
|---|---|---|
| `claude` | `credentials_encrypted` or `ANTHROPIC_API_KEY` env | _(SDK default)_ |
| `gemini` | `credentials_encrypted` or `GEMINI_API_KEY` env | `gemini-2.0-flash` |
| `glm` | `credentials_encrypted` or `GLM_API_KEY` env | `glm-4.7` |
| `opencode`, `aider`, `cline`, `copilot` | _(managed by the CLI)_ | _(CLI default)_ |

The `model` field is optional and **free-form** — it is not validated against a catalog (see [Models](#models)). When omitted, the fallback above applies. The `cli_path` field is optional — if omitted, the agent binary is resolved from `PATH`.

Returns `201` with the created profile.

### List Agent Profiles

```
GET /agent-profiles
```

Returns `200` with an array of profiles.

### Get Agent Profile

```
GET /agent-profiles/:id
```

Returns `200` with the profile, or `404`.

### Update Agent Profile

```
PATCH /agent-profiles/:id
PUT   /agent-profiles/:id
```

```json
{
  "name": "renamed-profile",
  "cli_path": "/opt/bin/claude",
  "model": "claude-opus-4-20250514"
}
```

Only provided fields are updated. Set `model` to `null` to clear the profile default (reverts to the agent/provider fallback). Both `PATCH` and `PUT` are accepted.

Returns `200` with the updated profile.

## Tasks

### Model Resolution

When dispatching a task, the effective model is resolved in this order:

```
task.model → profile.model → agent/provider fallback
```

If the task or profile doesn't specify a model, the agent's fallback applies (an SDK default for `claude`; a fixed fallback for `gemini`/`glm`, which require an explicit model). The `model` value is free-form and not validated against a catalog — see [Models](#models).

### Dispatch a Task

```
POST /tasks
```

```json
{
  "project_id": "uuid",
  "description": "Fix the failing test",
  "agent_profile_id": "optional-uuid",
  "model": "claude-opus-4-20250514"
}
```

Triggers a preflight complexity check. Returns `201` with the task.

- `agent_profile_id` — overrides the project's default profile for this task
- `model` — overrides the profile's default model for this task (free-form; validated by the provider/CLI at runtime)

If the preflight returns `complex` and the task is not pre-confirmed, it stays `pending` until confirmed.

### List Tasks

```
GET /tasks
GET /tasks?project_id=<uuid>
```

Returns `200` with an array of tasks.

### Get Task Detail

```
GET /tasks/:id
```

Returns `200` with the task object, or `404`.

### Stream Task Logs (SSE)

```
GET /tasks/:id/logs
```

Returns a `text/event-stream` with these event types:

```
event: log
data: {"id":1,"task_id":"...","role":"agent","chunk":"Analyzing...","timestamp":"..."}

event: message
data: {"type":"text","content":"Found the relevant files","timestamp":"..."}

event: done
data: {"taskId":"..."}

event: error
data: {"message":"..."}
```

### Confirm a Complex Task

```
POST /tasks/:id/confirm
```

Marks a complex task as confirmed and dispatches it. Returns `200`.

### Reply to a Running Task

```
POST /tasks/:id/reply
```

```json
{
  "message": "Add rate limiting too"
}
```

Resumes the agent session via `session_id`. Returns `200`.

### Delete / Kill a Task

```
DELETE /tasks/:id
```

Kills the running agent, cleans up the worktree, marks as failed. Returns `204`.

## Threads

A **thread** is a non-PR agent conversation — brainstorming, codebase questions, "how does X work?". Unlike a task, a thread creates no worktree, runs no preflight, never commits/pushes/opens a PR, and never deploys. It runs **read-only** against the project's real repo and persists a `session_id` so the conversation resumes turn after turn.

Threads require an agent that supports resume:

| `agent_type` | Resume mechanism |
|---|---|
| `claude` | Native session resume |
| `gemini`, `glm` | Resume by rebuilding context from stored history |
| `opencode`, `aider`, `cline`, `copilot` | Not supported — rejected with `400` |

Read-only behavior:

- `claude` threads run in Claude's `plan` mode (read, search, reason — no edits).
- `gemini`/`glm` threads expose only `read_file` (no grep/glob/bash in this release).

### Model Resolution

Same as tasks:

```
thread.model → profile.model → agent/provider fallback
```

The `model` value is free-form and not validated against a catalog — see [Models](#models).

### Create a Thread

```
POST /threads
```

```json
{
  "project_id": "uuid",
  "message": "How does the orchestrator decide when a task is done?",
  "agent_profile_id": "optional-uuid",
  "title": "optional title",
  "model": "claude-sonnet-4-5-20250929"
}
```

- `message` — the first user turn (required)
- `agent_profile_id` — overrides the project's default profile; must be a resumable type (`claude`/`gemini`/`glm`)
- `title` — optional; defaults to the first 60 characters of `message`
- `model` — overrides the profile's default model (free-form; validated by the provider/CLI at runtime)

Returns `201` with the created thread. The first turn runs immediately; `session_id` is populated from the stream as the agent responds:

```json
{
  "id": "uuid",
  "project_id": "uuid",
  "agent_profile_id": "uuid",
  "title": "How does the orchestrator decide when a task is done?",
  "session_id": "dc44cfab-...",
  "model": null,
  "token_usage": null,
  "created_at": "2026-06-29 14:02:53",
  "updated_at": "2026-06-29 14:02:53"
}
```

A thread with no `session_id` cannot be replied to (its first turn didn't complete).

### List Threads

```
GET /threads
GET /threads?project_id=<uuid>
```

Returns `200` with an array of threads.

### Get Thread Detail

```
GET /threads/:id
```

Returns `200` with the thread object, or `404`.

### Reply to a Thread

```
POST /threads/:id/reply
```

```json
{
  "message": "Summarize that in one sentence."
}
```

Resumes the conversation via the thread's `session_id` (native for Claude; history-rebuild for gemini/glm). Returns `200`.

Returns `409` if a turn is already in progress for this thread, or `400` if the thread has no `session_id` yet.

### Stream Thread Logs (SSE)

```
GET /threads/:id/logs
```

Returns a `text/event-stream`. Existing messages are replayed first, then live turns are streamed. Unlike `/tasks/:id/logs`, a thread stream **stays open across turns** — it closes only when the client disconnects. A `message` with `type: "done"` signals that a single turn finished, not that the stream ended.

```
event: log
data: {"id":1,"thread_id":"...","role":"user","chunk":"How does...","timestamp":"..."}

event: message
data: {"type":"text","content":"The orchestrator polls GitHub...","timestamp":"..."}

event: error
data: {"message":"..."}
```

### Delete a Thread

```
DELETE /threads/:id
```

Aborts any in-flight turn and deletes the thread and its messages. Returns `204`.

## CLI

### Scan

```
mandor scan [dir...]
```

Runs a workspace scan from the CLI (no server needed). Uses the same `MANDOR_DB_PATH` and root resolution as the API endpoint.

| Args | Behavior |
|---|---|
| _(none)_ | Scans `process.cwd()` |
| `dir...` | Scans the given directories |

```bash
mandor scan
mandor scan ~/code ~/work
```

### Init

```
mandor init [name]
```

Creates a `.mandor.json` sign file in the current directory.

| Args | Behavior |
|---|---|
| _(none)_ | Uses the directory name as the project name |
| `name` | Overrides the project name |

Detects `git remote get-url origin` and writes it as `repo_url` if available.

## Tokens

### Usage Summary

```
GET /tokens
```

Returns `200`:

```json
{
  "total_input": 15000,
  "total_output": 32000,
  "total_tokens": 47000,
  "task_count": 3
}
```

## Task Lifecycle

```
pending ──► running ──► pr_ready ──► merged ──► deploying ──► deployed
                  │                    │              │
                  └──► failed          └──► failed    └──► deploy_failed
```

| Status | Description |
|---|---|
| `pending` | Created, preflight running or waiting for confirmation |
| `running` | Agent actively working in an isolated worktree |
| `pr_ready` | Agent finished, PR created |
| `merged` | PR merged (manual, via GitHub) |
| `deploying` | Deploying affected targets after merge |
| `deployed` | All affected targets deployed successfully |
| `deploy_failed` | One or more targets failed to deploy |
| `failed` | Agent errored or was killed |

## File Browser

Read-only filesystem access scoped to a project's `local_path`. Every endpoint requires the project ID in the URL; the resolved path is validated against the project root and rejected if it escapes via `../` or symlink traversal.

Authentication: if `AUTH_TOKEN` is set in the environment, all browse/file endpoints require `Authorization: Bearer <token>`.

### Browse Directory

```
GET /browse/:projectId?path=&offset=&limit=
```

Lists the contents of a directory within the project root. Uses `readdir` with `withFileTypes` — no per-entry `stat` calls. Entries are returned directories-first, then files, both alphabetical.

| Query | Default | Description |
|---|---|---|
| `path` | _(required)_ | Relative path from the project root |
| `offset` | `0` | Number of entries to skip |
| `limit` | _(all)_ | Max entries to return |

Returns `200`:

```json
[
  { "name": "src", "type": "directory" },
  { "name": "docs", "type": "directory" },
  { "name": "package.json", "type": "file" },
  { "name": "tsconfig.json", "type": "file" }
]
```

### File Metadata

```
GET /file/:projectId?path=
```

Returns metadata for a single file — no content. Line count is included for text files under 5 MB (streamed in chunks, no full-buffer read).

| Query | Default | Description |
|---|---|---|
| `path` | _(required)_ | Relative path from the project root |

Returns `200`:

```json
{
  "size": 1423,
  "mime": "text/javascript",
  "modifiedAt": "2026-06-30T14:22:10.000Z",
  "lineCount": 47
}
```

Returns `400` if the path points to a directory or a non-file.

### File Content

```
GET /file/:projectId/content?path=
```

Streams file content via `fs.createReadStream`. Supports HTTP `Range` headers for partial content (206 responses).

| Query | Default | Description |
|---|---|---|
| `path` | _(required)_ | Relative path from the project root |

**Small text files** (≤5 MB, non-binary extension) — streamed directly with a `200` response.

**Large or binary files** (>5 MB or binary extension like `.png`, `.zip`, `.pdf`) — require a `Range` header. Without one the server returns `416`:

```json
{
  "error": "File is too large for direct download. Use Range header to stream chunks.",
  "size": 52428800,
  "mime": "application/zip"
}
```

**Range request** — returns `206` with `Content-Range` and partial body:

```
Range: bytes=0-1023
```

```http
HTTP/1.1 206 Partial Content
Content-Type: text/javascript
Content-Range: bytes 0-1023/1423
Content-Length: 1024
```
