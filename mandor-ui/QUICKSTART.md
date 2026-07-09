# Mandor UI - Quick Start Guide

## Installation (60 seconds)

```bash
cd mandor-ui
puro flutter pub get
```

## Running (One Command)

```bash
puro flutter run -d web
```

Opens automatically at `http://localhost:54321`

## Connect to Mandor Server

1. Open the app in browser
2. Click **Settings** icon (⚙️) top-right
3. Enter Mandor server URL:
   - Local: `http://localhost:3000`
   - Network: `http://<your-host>:3000`
   - Tailscale: `http://100.x.y.z:3000`
4. Click **Save**

## Create Your First Task

1. Click on any **Project**
2. Click **New Task** button
3. Type task description (e.g., "Add JWT authentication to user service")
4. Click **Create**
5. Watch the task execute in real-time! 👀

## Features at a Glance

| Feature | Usage |
|---------|-------|
| Browse Projects | Projects screen shows all repos |
| Create Task | Click "New Task" in project detail |
| Watch Agent | Click task → see live logs |
| Reply to Task | (bottom of task detail) |
| View PR | Task card shows "View PR" button |
| Change Server | Settings ⚙️ → enter URL |

## Development

### Hot Reload
Save any file → instantly see changes in browser

### Rebuild
```bash
puro flutter pub get  # Update dependencies
puro flutter analyze  # Check for issues
puro flutter test     # Run tests
```

### Production Build
```bash
puro flutter build web --release
# Deploy build/web/ to any static host
```

## Troubleshooting

### "Can't connect to Mandor server"
- Ensure Mandor is running: `mandor` on the host
- Check URL is correct (click Settings again)
- Verify firewall allows port 3000
- For Tailscale: ensure both devices are connected

### "No projects found"
- Mandor server has no projects yet
- Create a project: `cd /repo && mandor init && mandor scan`

### "Task status stuck"
- Refresh: Click Projects → refresh icon
- Check Mandor server logs: `journalctl -u mandor -f`

## Architecture

```
Your Phone/Laptop ──HTTP──> Mandor Server ──> GitHub
  (Flutter App)              (Always-on)
    (this UI)
```

## Quick Links

- 📖 Full Docs: See `README.md`
- 🏗️ Architecture: See `MANDOR_CLIENT.md`
- 🌐 API Reference: See `docs/API.md` in Mandor repo
- 🎯 Getting Started: See `docs/GETTING_STARTED.md` in Mandor repo

---

**Happy coding! 🚀**
