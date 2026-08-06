# Dreamer's brainstorm

## North star vision

Atlas becomes the single mission-control surface for everything running on JJ's Mac (and eventually the QNAP NAS). Every long-lived process — atlas-api, wallgen, MCP servers, rvr-service, future cron-likes — declares itself once in a `.atlas/daemon.toml` next to its code, and atlas takes over the rest: plist generation, launchctl orchestration, dependency-aware boot order, log aggregation, health scoring, and one-click promote-to-NAS via nas-deploy. The Raycast browser, Rust TUI, and a new live web dashboard at `atlas-api:47891/dash` all read the same event stream, so "what's running on my mac" has exactly one answer. Watchdog stops being a port-pinger and becomes a self-healing supervisor with memory-trend prediction. launchd is still the runtime — atlas is the conductor.

## Top 5 ideas

### 1. Daemon manifests co-located with projects (`.atlas/daemon.toml`)
**What**: Each project declares its daemons in `.atlas/daemon.toml` (e.g. `multi-stack/pimpelmees/wallgen/.atlas/daemon.toml`); the scanner in `atlas-api/src/lib/scanner.ts` already walks 3 levels and is the perfect discovery point.
**Why it's exciting**: Source of truth lives with the code it describes. Move/rename/archive a project (existing `/api/move`, `/api/archive`, `/api/rename`) and its daemons travel with it automatically. No central registry to drift.
**Unlocks**: `GET /api/daemons` is just a fold over `ProjectAtlas`. `shared/daemons.ts` (mirrors `shared/actions.json` pattern) gives picker + browser typed access. Archiving a project auto-unloads its plists. Beads tickets can be auto-filed against the owning project when a daemon crashes.

### 2. Dependency DAG with topological boot/shutdown
**What**: `daemon.toml` declares `requires = ["wallgen", "consult-user-mcp"]` and `ports = [6500]`. Atlas computes a DAG, boots leaves first, tears down in reverse, and refuses to start a daemon whose port is already held by something it didn't spawn.
**Why it's exciting**: wallgen-webui (port 6512) genuinely needs wallgen (6500) up first; rvr-service has its own startup ordering; MCP servers have implicit Claude Code dependencies. Today this is tribal knowledge. Tomorrow it's a graph rendered in the dashboard.
**Unlocks**: "Start the pimpelmees stack" becomes one click. Cycle detection at config time. The TUI picker (`atlas-picker`) gets a Ctrl+G "graph mode" rendering the live DAG in iocraft with status colors per node. Port conflict detection answers open question #8 for free.

### 3. Live event stream + dashboard (`/dash` + SSE)
**What**: New SvelteKit route `atlas-api/src/routes/dash/+page.svelte` showing every managed daemon: status pill, memory sparkline, last-100-log-lines tail, restart count, dependency graph. Backed by `/api/daemons/stream` (SSE) so Raycast, TUI, and browser tab all see the same heartbeat.
**Why it's exciting**: Right now "is wallgen up?" means `lsof -i :6500` in a terminal. With a dashboard it's a glance. Svelte 5 runes + the existing port 47891 means zero new infra.
**Unlocks**: atlas-watchdog (currently a 23-line bash polling `lsof`) generalizes to a single subscriber on the SSE stream that fires `launchctl kickstart -k` for any daemon in `failed` state. One watchdog, N daemons — open question #4 answered. Replay last hour of events for crash forensics.

### 4. Self-healing supervisor with memory-trend prediction
**What**: atlas-api samples RSS/CPU per managed daemon every 15s (via `ps` or `proc_pidinfo`), stores 24h rolling window in SQLite at `~/Documents/development/.atlas-cache.db`, fits a simple linear trend. When predicted RSS will exceed `memory_limit` within 30 min, atlas pre-emptively `launchctl kickstart`s during an idle window.
**Why it's exciting**: Goes beyond launchd's reactive `KeepAlive`. Catches the slow blender-mcp leak before it OOMs your work. Trend graphs are a free side effect of the sampling.
**Unlocks**: Per-daemon health score (0–100) surfaced in the Raycast browser. Anomaly detection: "wallgen RSS is 3x its 7-day median" → notify via consult-user-mcp. Beads tickets auto-filed with the trend graph attached.

### 5. One-click promote-to-NAS via nas-deploy
**What**: Each daemon manifest can opt into `[remote.nas]` with target host. A "Promote to NAS" action (in `shared/actions.json`) generates a systemd unit or docker-compose service, ships it via the nas-deploy skill, and atlas now polls *both* local and remote status in the same dashboard. workremotely integration means logs stream back transparently.
**Why it's exciting**: The Mac is JJ's dev machine; the QNAP is production. Today that handoff is manual scp+ssh. Atlas closes the gap so a daemon's lifecycle ("local prototype → trusted local daemon → NAS production") is a property of the manifest, not a folklore migration.
**Unlocks**: True hybrid mission control. wallgen runs on NAS for the Shopify site but bursts to local Mac for heavy generation. atlas-picker gains a 🟢/🔵 host indicator per daemon. Cron-likes (future) deploy to NAS by default.

## Wildcards

- **Daemon time machine**: atlas snapshots each daemon's working directory git SHA + env vars + plist at every successful boot. `atlas rollback wallgen --to yesterday-16:00` reverts the plist, checks out the SHA in a worktree, and reboots. Combine with beads for "this regression started here."
- **Voice-controlled mission control**: pipe the SSE stream into the voice-assistant skill so JJ can say "atlas, restart the pimpelmees stack" or "what's eating memory right now" while hands-on-keyboard in another project. ElevenLabs TTS reads back the health summary.
- **Atlas as MCP server**: expose `daemon.start`, `daemon.logs`, `daemon.status` as MCP tools so Claude Code itself can manage daemons mid-conversation ("the MCP server stopped responding — restart it"). Closes the loop: the agent that wrote the daemon can now operate it.
