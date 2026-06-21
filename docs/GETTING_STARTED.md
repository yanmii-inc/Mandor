# Getting Started

## Prerequisites

- Git >= 2.30
- [GitHub CLI](https://cli.github.com) `gh` (for automated PRs)
- An API key for your chosen agent (e.g. `ANTHROPIC_API_KEY` for Claude)

## Install

You have three options, depending on whether you want to build from source or just use the server binary.

### Option 1: Pre-built binary (easiest, no toolchain needed)

Download the latest release for your platform — no Bun, no Node, nothing else required.

```bash
# macOS Apple Silicon
curl -L https://github.com/<your-org>/consign/releases/latest/download/consign-darwin-arm64 -o /usr/local/bin/consign && chmod +x /usr/local/bin/consign

# macOS Intel
curl -L https://github.com/<your-org>/consign/releases/latest/download/consign-darwin-x64 -o /usr/local/bin/consign && chmod +x /usr/local/bin/consign

# Linux x64
curl -L https://github.com/<your-org>/consign/releases/latest/download/consign-linux-x64 -o /usr/local/bin/consign && chmod +x /usr/local/bin/consign
```

Then use it anywhere:

```bash
consign init            # stamp the current directory
consign                 # start the server (port 3000)
```

### Option 2: Build from source (requires Bun)

```bash
git clone <your-repo>/consign.git
cd consign
bun install
bun run build

# The standalone binary is now at ./consign — copy it anywhere:
cp consign /usr/local/bin/
consign init
```

### Option 3: Run from source (no global install)

```bash
git clone <your-repo>/consign.git
cd consign
bun install

# Use via bun run from anywhere:
bun run init                        # stamp the current directory
bun run start                       # start the server

# Or link globally for bare usage:
bun link && consign init
```

The server starts on `http://0.0.0.0:3000`.

## Configure

### Option A: Auto-discover with `.consign.json` (recommended)

Stamping a repo with a sign file lets the server auto-discover it. Run this inside any project you want consign to manage:

```bash
consign init
```

This creates a `.consign.json` file in the current directory:

```json
{
  "name": "my-app",
  "repo_url": "https://github.com/you/my-app.git"
}
```

| Field | Description |
|---|---|
| `name` | Project name (defaults to directory name; pass an arg to override) |
| `repo_url` | Detected from `git remote get-url origin` (omitted if no git remote) |
| `agent_profile_id` | Optional — can be added manually later |

You can stamp a directory explicitly:

```bash
consign init custom-name     # uses "custom-name" instead of the directory name
```

#### Workspace Roots

Tell the server where to look for `.consign.json` files via the `WORKSPACE_ROOTS` environment variable (JSON array or comma-separated paths):

```bash
export WORKSPACE_ROOTS='["~/code", "~/work"]'
```

Or create a config file at `~/.consign/config.json`:

```json
{
  "workspaceRoots": ["~/code", "~/work"]
}
```

Default: `~/consign-workspace`.

The server scans these roots on startup and on every `POST /projects/scan` call. Projects whose `.consign.json` is removed are automatically deleted from the database.

```bash
# Re-scan without restarting
curl -X POST http://localhost:3000/projects/scan
```

Returns the scan result with the full project list:

```json
{
  "created": 2,
  "updated": 1,
  "deleted": 0,
  "projects": [ ... ]
}
```

### Option B: Manual API (no sign file)

```bash
curl -X POST http://localhost:3000/projects \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "my-app",
    "repo_url": "https://github.com/you/my-app.git",
    "local_path": "/home/ubuntu/my-app"
  }'
```

| Field | Required | Description |
|---|---|---|
| `name` | yes | Human-readable project name |
| `repo_url` | yes | Git remote URL |
| `local_path` | yes | Path where the repo is cloned on the VM |
| `agent_profile_id` | no | Default agent profile for this project |
| `targets` | no | Array of deploy target objects |

Manually created projects have `source: "manual"` and are never auto-deleted by workspace scans.

### Create an Agent Profile

```bash
curl -X POST http://localhost:3000/agent-profiles \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "claude-dev",
    "agent_type": "claude"
  }'
```

Valid `agent_type` values: `claude`, `opencode`, `aider`, `cline`, `copilot`

## Dispatch Your First Task

```bash
curl -X POST http://localhost:3000/tasks \
  -H 'Content-Type: application/json' \
  -d '{
    "project_id": "<project-id>",
    "description": "Add user authentication with JWT tokens"
  }'
```

### Watch It Work

```bash
curl -N http://localhost:3000/tasks/<task-id>/logs
```

This opens an SSE stream — you'll see the agent's output in real-time.

### Send a Follow-Up

```bash
curl -X POST http://localhost:3000/tasks/<task-id>/reply \
  -H 'Content-Type: application/json' \
  -d '{"message": "Add rate limiting too"}'
```

### Approve a Complex Task

If preflight flags a task as `complex`, it stays `pending`. Approve it:

```bash
curl -X POST http://localhost:3000/tasks/<task-id>/confirm
```

### Kill a Running Task

```bash
curl -X DELETE http://localhost:3000/tasks/<task-id>
```
