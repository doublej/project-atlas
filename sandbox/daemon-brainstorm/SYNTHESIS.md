# Atlas daemon management — synthesis

## TL;DR

Ship a **read-mostly daemon viewer** in v1: a hand-edited `shared/daemons.json` registry, a thin `launchctl` wrapper in atlas-api, and a Raycast "Daemons" command. **Write actions (start/stop/restart) ship behind an env flag** (`ATLAS_DAEMON_WRITE=1`) — the devil's circular-supervisor objection is real and we route around it by keeping atlas-api out of its own managed set and never auto-restarting anything. We adopt the pragmatist's "wrap launchctl, don't replicate" floor and one piece of dreamer scaffolding (the `shared/daemons.ts` pattern). Plist generation, dependency DAGs, SSE dashboards, NAS promotion, and project-side `.atlas/daemon.toml` manifests are deferred or rejected outright.

## The strongest objection — and how we route around it

The devil is right: **atlas-api cannot supervise the daemon that supervises atlas-api**. Three concrete mitigations:

1. **atlas-api is explicitly excluded from the managed set.** It stays watched only by `atlas-watchdog`. `shared/daemons.json` lists it for *visibility*, but the daemons API refuses lifecycle actions against `com.jurrejan.atlas-api` (hardcoded deny). Documented in `atlas-api/CLAUDE.md`.
2. **No auto-restart logic in atlas-api.** launchd's `KeepAlive` is the supervisor. atlas-api is a *viewer* with manual write actions. The watchdog stays as-is. We do not generalize it to N daemons (rejecting dreamer idea #3's "watchdog becomes SSE subscriber") — that's exactly the circular dep the devil warned about.
3. **Read-only by default.** Lifecycle endpoints (`POST /api/daemons/:label`) return 403 unless `ATLAS_DAEMON_WRITE=1` is set in the launchd plist's `EnvironmentVariables`. Ship display, live with it 30 days, then flip the flag.

On the bigger "is atlas the right home" question: the devil's alternatives (a Raycast script, pm2, launchcontrol) all skip the one thing atlas already has — **a project-aware index that the Raycast UI and TUI both consume**. Joining a daemon to its owning project is genuinely useful (stale-path detection, "open in iTerm", beads ticket on crash). That justifies a thin layer. It does *not* justify a supervisor.

## Ranked ideas

### Tier 1 — v1 (ship this)

1. **Flat `shared/daemons.json` registry** [pragmatist] — hand-edited, seeded with the 4 existing plists, mirrors the proven `shared/actions.json` pattern.
   - **Why it makes the cut**: Zero codegen, zero schema drift, zero plist parsing. Dreamer's `.atlas/daemon.toml` co-location loses here because launchd loads from `~/Library/LaunchAgents`, not from project folders — a second discovery path is overhead without payoff at this scale (4 daemons).
   - **Concrete shape**: see v1 spec below.

2. **`launchctl` wrapper in atlas-api** [pragmatist] — shell out to `launchctl print/bootstrap/bootout/kickstart`, parse output.
   - **Why**: Wrap, don't replicate. Apple owns the runtime; we own the JSON list.
   - **Hard rules**: 5s timeout on every call (devil landmine #2). atlas-api's own label is blocklisted from write actions.

3. **Raycast "Daemons" command** [pragmatist] — list view, status pill, port check, start/stop/restart actions.
   - **Why**: User lives in Raycast. Ship one UI first, measure, then port to picker.

4. **Joined-with-project view** [dreamer, scoped down] — each daemon row links to its owning project (existing scanner data); "Open in iTerm", "Open in Finder", "File beads ticket" reuse existing actions.
   - **Why**: This is the actual atlas-shaped value-add over `launchctl list | grep`. Cheap because all three actions already exist.

5. **Stale-path detection** [devil's landmine #5, turned into a feature] — if `daemon.project` path doesn't exist on disk, surface a `stale` flag and offer `bootout`. Never auto-clean.

### Tier 2 — v2 (after v1 proves out)

1. **Picker integration** [pragmatist deferred] — Rust TUI reads `shared/daemons.json` via `include_str!`, calls API for live state. Ship after browser usage data justifies it.
2. **Log tail endpoint** [pragmatist] — `GET /api/daemons/:label/logs?lines=200`, `tail -n` on registered paths. Deferred only because every plist uses different log conventions (devil landmine #4) — solve once we've audited the 4 existing logs.
3. **Port conflict surfacing** [both] — `lsof -i :PORT` check joined into the list view. Already in pragmatist's plan; trivially added in v1 if cheap, otherwise v2.

### Tier 3 — parking lot (idea is good, timing isn't)

1. **In-repo plist symlinks** [devil's "if you do it anyway" #2 + dreamer's spirit] — versioned plists in `_management/daemons/` symlinked from `~/Library/LaunchAgents`. Good idea, but it's a separate refactor of *how plists live*, not a feature of atlas. Do it standalone, then atlas reads from the canonical location either way.
2. **SSE event stream** [dreamer #3] — useful eventually; premature before there's a second consumer beyond Raycast polling.
3. **MCP server interface** [dreamer wildcard] — "atlas as MCP" is genuinely interesting for Claude Code daemon management, but only after the HTTP API stabilizes.

### Tier 4 — rejected

- **Plist generation / XML serialization** [dreamer #1 implied, pragmatist out-of-scope, devil landmine #3] — round-trip mutation will rewrite every existing file on first save. Hard no.
- **Dependency DAG / topological boot** [dreamer #2] — launchd doesn't do this; faking it in atlas means shadowing `KeepAlive` semantics. Pragmatist correctly killed this. Tribal knowledge wins over a graph nobody asked for.
- **Memory-trend prediction + SQLite history** [dreamer #4] — supervisor territory. Exactly what the devil warned against. Out.
- **NAS promotion via nas-deploy** [dreamer #5] — different problem (deployment), different tool. Don't conflate.
- **`.atlas/daemon.toml` co-located manifests** [dreamer #1] — adds a second scanner path; project move/rename benefit doesn't materialize until 10+ daemons. Centralize for now.
- **Generalizing atlas-watchdog into an N-daemon supervisor** [dreamer #3 implication] — circular dep. The devil is right.
- **Voice control** [dreamer wildcard] — fun, premature.

## Concrete v1 spec

**Files to add**:
- `shared/daemons.json` — registry, 4 seeded entries
- `shared/daemons.ts` — types + `getDaemons()` helper (mirrors `shared/actions.ts`)
- `atlas-api/src/lib/launchctl.ts` — thin `spawn('launchctl', ...)` wrapper with 5s timeouts
- `atlas-api/src/routes/api/daemons/+server.ts` — `GET` list + joined state
- `atlas-api/src/routes/api/daemons/[label]/+server.ts` — `POST` action (gated by `ATLAS_DAEMON_WRITE`)
- `atlas-browser/src/daemons.tsx` — Raycast command
- `atlas-browser/package.json` — register `daemons` command
- `atlas-api/CLAUDE.md` — document the self-management exclusion
- `CLAUDE.md` (project root) — add "Daemons" section pointing at `shared/daemons.json`

**Schema** (final, not a sketch):

```json
{
  "version": 1,
  "daemons": [
    {
      "label": "com.jurrejan.atlas-api",
      "name": "Atlas API",
      "port": 47891,
      "project": "/Users/jurrejan/Documents/development/multi-stack/project-atlas/atlas-api",
      "logs": { "stdout": "/tmp/atlas-api.log", "stderr": "/tmp/atlas-api.error.log" },
      "selfManaged": true
    },
    {
      "label": "com.jurrejan.beads-bridge",
      "name": "Beads Bridge",
      "project": null,
      "logs": { "stdout": "~/Library/Logs/beads-bridge.log" }
    },
    {
      "label": "com.jurrejan.dlwatcher",
      "name": "Download Watcher",
      "project": "/Users/jurrejan/Documents/development/dl-watcher",
      "logs": { "stderr": "~/Library/Logs/dl-watcher.stderr.log" }
    },
    {
      "label": "com.jurrejan.vpn-subnet-fix",
      "name": "VPN Subnet Fix",
      "project": null
    }
  ]
}
```

Required: `label`, `name`. Optional: `port`, `project`, `logs`, `selfManaged`. `selfManaged: true` means write actions are blocked (only atlas-api itself for now).

**Endpoints**:
- `GET /api/daemons` — registry × `launchctl print gui/<uid>/<label>` × `lsof -i :PORT` × scanner stale-path check
- `POST /api/daemons/:label` — body `{ action: "start" | "stop" | "restart" }`; 403 unless `ATLAS_DAEMON_WRITE=1`; 403 if `selfManaged`; 5s timeout, returns post-call state
- `GET /api/daemons/:label/logs?lines=200` — *v2, not v1*

**Migration for existing 4 plists**:
- `com.jurrejan.atlas-api` — stays exactly as-is. Added to JSON with `selfManaged: true`. Watchdog untouched.
- `com.jurrejan.beads-bridge` — added to JSON. Currently no symlink; leave it in `~/Library/LaunchAgents`. Tier 3 work later moves it into an in-repo symlinked location.
- `com.jurrejan.dlwatcher` — added to JSON with project path. Stale-detection will flag it if `dl-watcher/` ever disappears.
- `com.jurrejan.vpn-subnet-fix` — already symlinked from its repo; reference its repo path as `project`.

No plist edits in v1. No `apps.manifest` changes. No watchdog changes.

## Open questions for the user to decide

1. **Should `selfManaged: true` block read-of-logs too, or only write?** (Recommend: only write — viewing atlas-api logs is useful.)
2. **`ATLAS_DAEMON_WRITE` default**: ship off (devil-safe, 30-day soak) or on (pragmatist-fast)? Synthesis recommends **off** — flip after one month.
3. **Should beads tickets auto-file when a daemon is detected as crashed?** Dreamer wanted this; devil would call it noise. Probably manual-trigger button in v1.
4. **Tier 3 #1 (in-repo plist symlinks) — do it now or later?** It's orthogonal to v1 but would clean up the inconsistency between `vpn-subnet-fix` (symlinked) and the other three (not). Recommend a separate small PR before v1 lands.
5. **TUI picker integration timing**: ship in v1 (pragmatist deferred but it's cheap) or strictly v2? Synthesis says v2 — browser-only first, prove the shape.
