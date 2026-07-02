# Mandor UI

A responsive Flutter web **client for Mandor** — the AI coding agent task dispatcher. This is the thin-client interface for dispatching tasks to your always-on Mandor host and monitoring agent execution in real-time.

## Overview

**Mandor UI** lets you:
- 📱 Dispatch coding tasks from any device (phone, tablet, laptop)
- 👀 Watch AI agents work in real-time with live SSE streaming
- 📊 Browse projects and review task history
- 💬 Reply to running tasks with follow-up instructions
- 🔗 Open PRs directly from the app

**Mobile-first responsive design** adapts seamlessly:
- **Mobile** (< 600px): Single column, touch-friendly
- **Tablet** (600-1024px): Two-column adaptive layout
- **Desktop** (≥ 1024px): Full dashboard layout

## What is Mandor?

Mandor is a self-hosted server that runs AI coding agents on your behalf. It manages:
- **Isolated worktrees** for safe parallel agent execution
- **Git workflows** (commit, push, PR automation)
- **Multiple agents** (Claude Code, OpenCode, Aider, etc.)
- **Session persistence** (resume interrupted tasks)

This app is the **client** that sends tasks to Mandor and watches them execute.

See the [Mandor server](https://github.com/yanmii-inc/Mandor) for the backend.

## Technical Stack

- **Flutter**: 3.44.0 (pinned via Puro)
- **Dart**: 3.12.0+
- **Package Manager**: Puro (Flutter version manager)
- **Design**: Material Design 3
- **State Management**: Riverpod
- **HTTP**: http package with SSE streaming

## Project Structure

```
mandor-ui/
├── lib/
│   ├── main.dart                  # App entry point with Riverpod
│   ├── models/
│   │   └── models.dart            # Mandor API data models (Project, Task, etc.)
│   ├── services/
│   │   └── mandor_api_client.dart # HTTP client for Mandor API + SSE
│   ├── providers/
│   │   └── mandor_providers.dart  # Riverpod providers for state management
│   ├── screens/
│   │   └── mandor_screens.dart    # ProjectsScreen, ProjectDetailScreen, TaskDetailScreen
│   └── widgets/
│       └── mandor_widgets.dart    # Reusable widgets (cards, status, logs, etc.)
├── web/
│   ├── index.html                 # Responsive HTML entry point
│   ├── manifest.json              # PWA manifest
│   └── icons/                     # App icons
├── test/
│   └── widget_test.dart           # Unit tests
├── pubspec.yaml                   # Dependencies
├── .puro.json                     # Puro configuration (Flutter 3.44.0)
└── README.md                      # This file
```

## Getting Started

### Prerequisites

- [Puro](https://github.com/pingbird/puro) installed
- A running Mandor server (see [Mandor Getting Started](../docs/GETTING_STARTED.md))
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Installation

```bash
cd mandor-ui
puro use default    # Use Flutter 3.44.0
puro flutter pub get
```

### Running the Application

```bash
# Development (hot reload enabled)
puro flutter run -d web

# Build for production
puro flutter build web --release
```

### Connecting to Mandor Server

1. Open the app in your browser
2. Click the **Settings** icon (⚙️) in the Projects screen
3. Enter your Mandor server URL (e.g., `http://localhost:3000` or `http://<host>:3000`)
4. Click **Save**

The app will now fetch projects from your Mandor server.

## Screens

### Projects Screen
Browse all projects registered with your Mandor server. Click to view tasks for a project or create a new task.

### Project Detail Screen
View task history for a specific project. Create new tasks here by clicking **New Task**.

### Task Detail Screen
Monitor a running task in real-time:
- Status indicator (Pending, Running, PR Ready, Merged, Failed)
- Live task logs via Server-Sent Events (SSE)
- Task metadata (complexity, token usage, PR link)
- Reply interface for follow-ups (if task supports resumption)

## Key Features

- ✨ **Responsive Design**: Mobile-first, works on any screen size
- 🎨 **Material Design 3**: Modern, accessible UI
- ⚡ **Real-time Streaming**: Live task logs via SSE
- 🔄 **Hot Reload**: Instant development feedback
- 🏠 **Project Browser**: Browse all Mandor projects
- 📝 **Task Creator**: Dispatch tasks with custom descriptions
- 👀 **Task Monitor**: Watch agent execution live
- 🔗 **PR Integration**: View and open PRs directly

## API Integration

Mandor UI communicates with the Mandor server via HTTP:

- **Base URL**: Configurable (default: `http://localhost:3000`)
- **Endpoints Used**:
  - `GET /projects` — List all projects
  - `GET /projects/:id` — Get single project
  - `GET /tasks` — List tasks (optionally filtered by project)
  - `GET /tasks/:id` — Get single task
  - `POST /tasks` — Create new task
  - `GET /tasks/:id/logs` — Stream task logs (SSE)
  - `POST /tasks/:id/reply` — Send message to running task
  - `POST /tasks/:id/confirm` — Confirm complex task
  - `DELETE /tasks/:id` — Cancel task

See [Mandor API Reference](../docs/API.md) for details.

## Development

### Hot Reload

Save changes and they're instantly reflected in the browser. Perfect for UI iteration.

### Adding Features

1. **Models**: Add data classes in `lib/models/models.dart` with `@JsonSerializable()`
2. **API Calls**: Add methods to `MandorApiClient` in `lib/services/mandor_api_client.dart`
3. **State**: Create Riverpod providers in `lib/providers/mandor_providers.dart`
4. **UI**: Build screens/widgets in `lib/screens/` and `lib/widgets/`

### Testing

```bash
puro flutter test
```

## Configuration

### Puro (Flutter Version Management)

The `.puro.json` file pins Flutter to 3.44.0:

```json
{
  "env": "3.44.0"
}
```

To use a different version:

```bash
puro upgrade default <version>
```

### Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## Deployment

Build for production:

```bash
puro flutter build web --release
```

Deploy the `build/web/` directory to any static host (Vercel, Netlify, AWS S3, etc.).

For Tailscale access:
1. Run on your Mandor host's LAN
2. Access via Tailscale IP (e.g., `http://100.x.y.z:3001` if you serve the built web app on port 3001)

## Contributing

When contributing to this project:
1. Maintain mobile-first design principles
2. Test across mobile, tablet, and desktop viewports
3. Follow Flutter linting rules (`puro flutter analyze`)
4. Use Riverpod for state management
5. Keep API calls isolated in `mandor_api_client.dart`
6. Update this README for significant changes

## Roadmap

- [ ] Offline task queue (dispatch tasks while offline, sync when reconnected)
- [ ] Task filtering and search
- [ ] Custom themes (dark mode)
- [ ] PWA installation support
- [ ] Local storage for Mandor server URLs
- [ ] Multi-server support
- [ ] Task statistics dashboard
- [ ] Agent profile management

## License

[Add your license here]

## Support

For issues or questions:
- Check [Mandor Getting Started](../docs/GETTING_STARTED.md) for server setup
- See [Mandor API Reference](../docs/API.md) for API details
- File issues on GitHub


