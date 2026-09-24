# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-component workspace for indexing and navigating development projects. A SvelteKit backend scans directories and exposes a JSON API consumed by a Raycast extension and a Rust TUI.

<vocabulary>
Canonical names — use these exact terms across all three consumers; they are this project's ubiquitous language.

- **Project** — one scanned development folder. The core record (`name`, `slug`, `path`, `type`, `framework`, `runner`, `git`, `scripts`, `deploy`, `beads`, `domains`, `umami`, …).
- **slug** — kebab-case DNS label derived from a project's folder name (`.atlas` `slug` overrides it). Used to build its dev hostnames.
- **dev hostname** — a project's stable `<slug>.atlas.local.jurrejan.com` (LAN) / `<slug>.atlas.remote.jurrejan.com` (password-gated, WAN) address, brokered by the NAS Caddy (`caddy-porkbun`) that atlas pushes site blocks to via `atlas-api/src/lib/caddyDev.ts`. Registered on first `POST /api/run`, listed at `GET /api/hostnames`.
- **host** — one catalogued machine, identified by a `shared/hosts.json` id: `m2` (this Mac, the **primary**), `fractal` (Windows **satellite**, `C:/dev`), `ubuntu` (**deploy** target, `/home/jurrejan/development`). Every `Project` carries `host`. Not to be confused with `<slug>.dev.remote…`, which is the WAN half of a dev hostname *on this same Mac* — `host` is the machine axis, `remote` is the reachability axis.
- **isLocal** — present (and `true`) only on the primary host's projects. Its *absence* is what hides every action that touches a filesystem or a GUI, and `/api/*` write routes reject a non-local path with 400 regardless.
- **alsoOn** — the same project catalogued on another machine, derived at merge time by exact name match. Skipped when the name is ambiguous on the primary, so a link is never a guess.
- **host registry** — `shared/hosts.json`: the machines atlas catalogs, their roots and SSH aliases. The third registry, alongside actions and daemons.
- **service** — a permanent local web UI (atlas console, Active Ports, deckhand) that gets a dev hostname without being a project. Routed by `atlas-api/src/lib/services.ts` at daemon start and every 60s: `direct` to a wildcard bind, `bridge` for a loopback-only one — a forwarder on the LAN IP that accepts only the NAS — or `down`. Services share the project slug namespace in `.atlas-hostnames.json`; a collision is refused. `atlas.remote` is off unless the entry sets `remote: true` (atlas-api carries shell-exec routes).
- **service registry** — `shared/services.json`: `slug`, `name`, `port`, optional `daemon` label and `remote`. Hand-curated; the fourth registry. Discovery of candidates is planned, not built (`.orchestrate/services-discovery.md`).
- **scan agent** — a bundled copy of the scanner (`bun run agent:build`) shipped to each remote host by `atlas hosts sync` and run over SSH. Its `--json` mode prints a `ProjectAtlas` on stdout and writes nothing.
- **domains** — the production domains a project publishes on, detected from its own files (CNAME, vercel/wrangler config, `package.json` homepage, `og:url`, robots.txt, env). Never fetched from a provider.
- **umami** — the Umami analytics link: `websiteIds` found in the project's tracking snippets plus the `instance` base URL. Dashboard URL is `{instance}/websites/{websiteId}`.
- **claudeSetup** — a project's Claude Code situation: the MCP servers scoped to it (its `.mcp.json` plus any added with `claude mcp add`, and which of them are switched off) and what `.claude/` carries (agents, commands, skills, rules, hook events, which settings files exist). Counts and names, never file contents — `agentFiles` holds the CLAUDE.md/AGENTS.md token estimates, and claude-tree is where the files themselves are read. MCP on/off state comes from `~/.claude.json`, which is why only an explicit "off" is reported: approval for a project that has never been opened is written nowhere.
- **ProjectAtlas** — the full scan result: projects + folders + detected frameworks. The `/api/projects` payload shape.
- **Scanner** — the atlas-api module (`scanner.ts`) that walks `~/dev` and produces a ProjectAtlas. The source of truth for the Project shape.
- **cache** — `.atlas-cache.json`, the persisted ProjectAtlas (60s TTL, stale-while-revalidate). atlas-picker reads it directly.
- **scan config** — `.atlas-config.json` at the scan root: `maxDepth` (how deep the walk goes, default 3), `depth` (per-subtree limit, keyed by `relativePath` — also the only way to catalog a project that sits *inside* another project) `force` (`true` catalogs a folder the detectors ignored, `false` demotes one they got wrong and keeps walking through it) and `ignore` (glob patterns — a bare name matches at any depth and takes its subtree with it, a leading `/` anchors to the root; the walk skips those folders whole). Edited by hand or from the web console; per-project `.atlas` stays the place for everything about a project itself.
- **Framework / Runner / GitStatus / DeployInfo** — the typed enums/structs on a Project. Names must match byte-for-byte across consumers (see `.claude/rules/shared-types.md`).
- **flow** — a project's branch flow: `feature/*` → **integration** (`develop`) → **trunk** (`main`) → an annotated tag + GitHub release. No release branches. `Project.flow` carries the policy (`gitflow` opted in · `trunk` ours, not opted in yet · `external` someone else's repo · `local` no remote), the trunk and integration branch names, the owner of the **main repository** (origin), and a `drift` line when the current branch breaks the flow. Detected per repo; `.atlas` `flow` overrides it.
- **disk** — `atlas disk`, the disk-space manager (spec: `.orchestrate/disk-spec.md`, ported from `~/dev/_management/disk`). Local-only. The web console's `/disk` shells out to it and never reimplements an operation. Three levers: **archive** idle projects into one verified `.tar.zst` each (default iCloud Drive `Dev Archive/`), **clean** rebuildable folders found by a home-folder **scan** (risk `rebuildable` · `reinstallable` · `review`), **trim** tool caches with each tool's own clean-up. State lives in `~/Library/Application Support/atlas-disk/` (`ATLAS_DISK_HOME` overrides): settings, the last analysis/scan, and `operations.jsonl` — the **operation log**, append-only, a `start` fsync'd before every file change; a start with no end is an **interrupted operation** that only `atlas disk recover` may touch. **Version id** = `<category>/<project>@<YYYYMMDD-HHMMSS>`. Exit codes: 0 ok · 1 error · 2 nothing to do · 3 partly failed · 4 refused.
- **board** — `atlas board`, the agents' message board: one global append-only JSONL (`~/Library/Application Support/atlas-board/board.jsonl`) shared across every project and session. For thoughts, not programming — talk about code or the task is frowned upon there. Not the **agent journal** (`agent-log`), which is per repo and about the work.
- **action registry** — `shared/actions.json`: what project actions exist and when. Not "commands", not "buttons".
- **daemon registry** — `shared/daemons.json`: the launchd daemons atlas displays/manages.
- **consumer** — one of the three UIs reading the shared shapes: atlas-api, atlas-browser, atlas-picker.
- **web console** — atlas-api's own UI, one shell over six routes — every route sits under the same nav band (`Nav.svelte`), which also carries the single theme toggle: `/` (projects, with host badges, `alsoOn` twins and the per-project settings dialog), `/ports` (every listener on the Mac grouped by owner — project, service, docker, system — with select-and-kill; the Active Ports dashboard, folded in), `/system` (hosts, scanner config, daemons, services, port audit), `/templates`, `/claude-tree`, `/disk` (every `atlas disk` operation — reads through `--json`, changes as jobs the page follows; writes only from this Mac or `atlas.atlas.local`).
</vocabulary>

## Components

| Component | Path | Stack | Purpose |
|-----------|------|-------|---------|
| **atlas-api** | `atlas-api/` | SvelteKit 2, Svelte 5, Bun | Backend API on port 47891 — scans `~/dev`, caches results, serves project metadata |
| **atlas-browser** | `atlas-browser/` | Raycast extension, React, TS | Raycast UI for browsing/filtering/acting on projects |
| **atlas-picker** | `atlas-picker/` | Rust, iocraft, Nucleo | TUI fuzzy picker that reads from the API cache file directly |
| **atlas-cli** | `atlas-cli/` | Bun, TS | Global **`atlas`** command — thin client to the API (`tree`/`info`/`init`/`new`/`scan`/`open`/`jump`/`pick`/`ports`/`flow`/`agent-log`/`board`/`prime`/`brief`/`disk`). Replaces per-project justfile recipes; `atlas new` is the scaffolding front door. `atlas prime` is the agent crash course (top of `atlas help`); `atlas brief` briefs a session (wired as a global SessionStart hook; `atlas agent-log session-end` as SessionEnd) |
| **atlas-disk** | `atlas-disk/` | Rust, iocraft | Terminal screen for `atlas disk` (`atlas disk tui`): archive-eligible projects ⇄ archive versions, log pane. Shells out to `atlas disk … --json` — never reimplements an operation |
| **atlas-watchdog** | `atlas-watchdog/` | Bash (Raycast script cmd) | Inline status monitor — polls `/api/health`, restarts via `launchctl kickstart com.jurrejan.atlas-api` (never `-k`) |
| **atlas-browser Daemons** | `atlas-browser/src/daemons.tsx` | Raycast command | View/restart launchd daemons via the `/api/daemons` endpoints; reads `shared/daemons.json` |

Each component has its own `CLAUDE.md` with detailed architecture notes.

**Before editing these, read the local context:**
- `shared/` (the registries) → [`shared/CLAUDE.md`](shared/CLAUDE.md)
- the synced scanner types (`scanner.ts` × 2, `project.rs`) → [`.claude/rules/shared-types.md`](.claude/rules/shared-types.md) (loads automatically when you open those files)

## Commands

### Workspace

```bash
./bootstrap.sh                               # Interactive setup — select components to install/run
./bootstrap.sh --apps atlas-api --run         # Install and run the API only
./bootstrap.sh --list                         # List available components
```

### atlas-api (SvelteKit API)

```bash
cd atlas-api
bun install
bun run dev          # Vite dev server on :47891
bun run build        # Production build
bun run check        # svelte-check type checking
bun run scan         # Standalone CLI scan (no server)
```

### atlas-browser (Raycast extension)

```bash
cd atlas-browser
bun install
npm run dev          # ray develop (hot reload in Raycast)
npm run build        # ray build
npm run lint         # ray lint
npm run fix-lint     # ray lint --fix
```

### atlas-picker (Rust TUI)

```bash
cd atlas-picker
just reinstall       # Lint + format-check + release build + install to ~/.cargo/bin
just check           # Lint + format-check + debug build
just lint            # clippy -D warnings
just fmt             # cargo fmt
```

### atlas-cli (global `atlas` command)

```bash
cd atlas-cli
bun install          # deps
bun link             # install the `atlas` bin onto PATH (~/.bun/bin)
bunx tsc --noEmit    # typecheck
atlas help           # list commands (tree/init/new/scan/open/run/jump/pick)
atlas install-autocompletion   # zsh completion for `atlas` + `pj` (rerun after adding a command)
```

`atlas tree` (no subcommand) prints tree help; `atlas tree view|search|compose` work in the
terminal (`view --up` = the chain towards the root only), and `atlas tree web [path]` opens
`/claude-tree?root=…` — the cookiecutter `claude-tree`
recipe is a thin `atlas tree web` alias. `atlas init` replaces the old `atlas-init` zsh function. `atlas info` prints what the scan
knows about the folder you're in (`--json` for the raw `Project`).
`atlas jump <query>` (aliased `pj`) cds the shell to the best match — local projects always
outrank remote twins, and a folder named exactly like the query (`pj framelink` → the workspace
holding `app`/`auth`/`broker`) wins when no project carries that name itself — no query opens the fuzzy
picker, and `--run <cmd>` runs a command there (`pj atlas --run bun test`); `atlas <query> --run
<cmd>` is the same thing. It needs `shell/atlas.zsh` sourced — that wrapper evals what the CLI
writes to `$ATLAS_SHELL_FILE`, since a child process can't cd its parent shell.
`atlas new` scaffolds a project — pick category → cookiecutter template → it appears in atlas
instantly (forces a rescan). Replaces the standalone `_management/cookiecutter-picker`. New
projects are born on the flow: `git init -b main`, a scaffold commit, and a `develop` branch.
`atlas hosts` lists the catalogued machines and their last scan; `atlas hosts sync [id]` rebuilds
the scan agent and ships it over SSH; `atlas hosts scan [id]` forces a refresh. `atlas jump`
refuses a project that lives on another machine rather than `cd`-ing to a path that is not here.
`atlas flow` shows the current project's branch flow, `atlas flow audit` lists which repos can
safely move onto it (clean tree, on trunk, our remote) and which can't and why, and `atlas flow
init [path]` opts one repo in — creates `develop`, renames `master` → `main`, writes the `.atlas`
`flow` block. Nothing is migrated in bulk; `--dry-run` prints the git commands first.

## Architecture

### Data flow

1. **atlas-api** scans `~/dev` recursively (3 levels max), detects project type/framework/runner/git/scripts/justfile/deploy
2. Results cached in `~/dev/.atlas-cache.json` (60s TTL, stale-while-revalidate)
3. **atlas-browser** fetches from `GET /api/projects` — Raycast UI with filters, search, and quick actions
4. **atlas-picker** reads the cache file directly for instant startup, refreshes via API on Ctrl+R
5. **atlas-watchdog** monitors port 47891 every 30s and restarts via launchd if down

### API (atlas-api, port 47891)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/projects` | GET | Main data endpoint (query: `?dir=`, `?includeArchived=true`) |
| `/api/refresh` | POST | Force rescan. `?host=<id>` refreshes one remote host and waits for it; `?force=true` ignores the 10-min fragment TTL |
| `/api/git` | POST | Batch git status (`{ paths: [] }`) |
| `/api/run` | POST/DELETE | Spawn/kill dev server — `POST` watches what the spawned process group actually binds, persists *that* port to `.atlas`, and points the Caddy dev hostnames at it. Returns `{ port, url, log, local, remote }`, plus `exited: true` when the server died on startup |
| `/api/hostnames` | GET | List registered dev hostnames (`{ slug, path, local, remote }[]`) from `.atlas-hostnames.json` |
| `/api/hostnames` | POST/DELETE | Hostname-only assignment without spawning a server (`{ path }`): POST allocates or reuses the `.atlas` port and calls `ensureRoute`, 404 when the path is not in the cached scan; DELETE removes the route. Also called by `/api/rename` and `/api/move` for the old path. CLI: `atlas hostnames [assign\|rm] [path]` |
| `/api/services` | GET/POST | Service hostname states (`{ slug, name, port, mode, bridged, local, error? }`); POST syncs now instead of waiting for the 60s tick. CLI: `atlas services [sync]` |
| `/api/projects` | GET | (see above) also returns `hosts[]` — per-machine `status` / `scannedAt` / `projectCount` |
| `/api/readme` | POST | Lazy README load |
| `/api/description` | PUT | Update project description |
| `/api/iterm` | POST | Open iTerm via AppleScript |
| `/api/finder` | POST | Open Finder |
| `/api/rename` | POST | Rename project folder |
| `/api/move` | POST | Move project folder |
| `/api/agent-files` | GET/POST/PUT | CLAUDE.md and AGENTS.md operations |
| `/api/atlas` | GET/PATCH | One project's `.atlas` overrides. `PATCH` merges; a `null` value clears a key |
| `/api/config` | GET/PUT | The scanner's `.atlas-config.json` — `maxDepth`, per-subtree `depth`, `force`, `ignore` |
| `/api/hosts` | GET/PUT | The host registry. A write reaches the file immediately and the running daemon only after `daemon:reload` (`restartRequired: true` says so) |
| `/api/archive` | POST | Archive/unarchive project (`{ path, archived }`) |
| `/api/beads` | POST | Create beads ticket via `bd create --silent` (`{ path, title, description?, priority?, issue_type?, labels? }`); 400 without a `.beads` db |
| `/api/agent-log` | GET | Project's agent journal (`?path=`): visible events, active intent count, latest handoff — readonly open of `agent-log.sqlite`, empty payload for non-git/missing db |
| `/api/daemons` | GET | List launchd daemons with live state, port check, stale-path detection |
| `/api/daemons/:label` | POST | Lifecycle action (`{ action: 'start'\|'stop'\|'restart' }`); gated by `ATLAS_DAEMON_WRITE=1`, blocked on `selfManaged` daemons |
| `/api/categories` | GET | Depth-1 dev categories from the cached scan (`{ name, projectCount, dominantType }`) — for `atlas new` |
| `/api/templates` | GET | Discover cookiecutter templates under `ATLAS_TEMPLATES_DIR` (`{ family, name, description, version, path, variables }`) |
| `/api/ports/allocate` | GET | Allocate an unused port from the atlas range (4100–4999) for a scaffolded project (`{ port }`) |
| `/api/ports/listeners` | GET | Every TCP listener on this Mac joined with its owner (`{ listeners, updatedAt }`); 10s cache, `?fresh=1` skips it |
| `/api/ports/kill` | POST | `{ pids }` → SIGKILL, restricted to pids the listener scan saw and never atlas-api itself |
| `/api/disk/read` | GET | `?cmd=<sub>&arg=…` → `atlas disk <sub> … --json`, side-effect-free commands only (cached reads, listings, status, dry-runs) |
| `/api/disk/jobs` | GET/POST | List recent jobs / start one (`{ command, args }`, allowlisted, run `--confirmed`) as a detached `atlas disk job` writing `<ATLAS_DISK_HOME>/jobs/<id>.log` |
| `/api/disk/jobs/:id` | GET/DELETE | Poll a job's log from `?offset=` (whole lines) and its exit / cancel it (SIGINT to its group) |
| `/api/disk/config` · `/api/disk/schedule` | PUT · POST | `config set` per changed key · `schedule enable\|disable\|set`. Every `/api/disk` write is 403 unless it comes from loopback or through the NAS proxy on `atlas.atlas.local` (`x-forwarded-host`), and from a matching Origin |
| `/api/ports/audit` | GET | Report-only port-collision check across daemons + scanned projects (`{ collisions, unmanaged }`) — never writes |

### Multi-host catalog

atlas catalogs three machines. Only the Mac is ever written to.

| Host | Role | Root | How it is scanned |
|---|---|---|---|
| `m2` | primary | `~/dev` | in-process, every 60s (stale-while-revalidate) |
| `fractal` | satellite | `C:/dev` | SSH → scan agent, ~9s, git skipped |
| `ubuntu` | deploy | `/home/jurrejan/development` | SSH → scan agent, ~7s, git included |

- **Remote scans never block a request.** `GET /api/projects` answers from the merged cache in
  ~30ms and kicks a TTL-guarded (10 min) background sweep. A host that is powered off keeps its
  last projects and is reported `status: 'unreachable'` in `hosts[]` — the catalog degrades to
  "ubuntu down, scanned 3h ago" instead of silently losing 26 projects.
- **Fragments, then one merge.** Each remote host's projects live in
  `~/dev/.atlas-cache-<id>.json`. `finalizeAtlas()` folds them into the main
  cache. It is idempotent (it drops non-local projects before re-merging), which is what stops
  the 60s revalidation from overwriting the merged catalog with a local-only scan.
- **`git` runs only on local projects** during cache enrichment — a remote path has no repo here.
- **Ports are per host.** `/api/ports/audit` and `allocatePort` reason over this machine's `lsof`
  only. Ubuntu already has ~30 listeners (3110/3111/5180) and Fractal has Sunshine on 47984-48010.

### Shared types

All three consumers share the same `Project` / `ProjectAtlas` shape. When modifying the scanner types in `atlas-api/src/lib/scanner.ts`, update the corresponding types in:
- `atlas-browser/src/scanner.ts`
- `atlas-picker/src/project.rs`

### Shared action registry (`shared/`)

`shared/actions.json` is the single source of truth for project actions (open, run, copy, etc.). All three UI consumers read from this file:

- **atlas-browser** imports via `../../shared/actions.js` (TS types in `src/action-registry.ts`)
- **atlas-picker** embeds via `include_str!("../../shared/actions.json")` (Rust types in `src/actions.rs`)
- **atlas-api** imports via `$shared/actions` alias (configured in `svelte.config.js`)

`shared/actions.ts` provides TypeScript types and helpers (`getActions`, `getDynamicActions`, `getGroupsForActions`).

When adding/removing/changing actions, edit `shared/actions.json` first, then update consumer-specific rendering if needed. Each consumer keeps its own execution logic — the registry defines *what* and *when*, not *how*.

### Shared daemon registry (`shared/daemons.json`)

Single source of truth for launchd daemons that atlas displays/manages. Hand-edited; mirrors the `shared/actions.json` pattern. Each entry: `label`, `name`, optional `port`, `project`, `plist`, `logs`, `selfManaged`. The `selfManaged: true` flag (used by `com.jurrejan.atlas-api`) blocks lifecycle actions from the API — atlas-watchdog remains the sole supervisor for that one.

`shared/daemons.ts` exports `getDaemons()` / `getDaemonByLabel()` helpers, imported by atlas-api via the `$shared/daemons` alias.

### Plist storage convention

User launchd plists live in their owning repo under a `launchd/` subdirectory and are symlinked from `~/Library/LaunchAgents/`. The authoritative list is `shared/daemons.json` — every entry's `plist` field points at the source plist. Examples:
- `atlas-api/launchd/com.jurrejan.atlas-api.plist`
- `~/dev/python/reminders-bridge/launchd/com.jurrejan.reminders-bridge.plist`
- `~/dev/dl-watcher/launchd/com.jurrejan.dlwatcher.plist`
- `~/tools/vpn-subnet-fix/com.jurrejan.vpn-subnet-fix.plist`

Plists are edited by humans only. atlas-api never writes plists in v1.

## Bootstrap system

`apps.manifest` defines components in pipe-delimited format: `id|name|path|tools|install|run|os|deps`. The bootstrapper resolves dependencies, checks required tools, and runs install/run commands.

## Key conventions

- **Svelte 5 runes** in atlas-api UI: `$state`, `$props`, `$effect` — no stores/writable
- **Bun** is the package manager for both TS projects
- **Rust builds** always go through `just reinstall` (lint + fmt-check + install)
- atlas-picker renders to `/dev/tty` to keep stdout free for shell integration (`pj` shell function)
- **The atlas-api daemon serves the adapter-node build (`bun build/index.js`), never `vite dev`** — a dev server needs ~70s before its first response and gets killed mid-boot by health checks. Rebuild with `bun run daemon:reload` after changing API code. See [`atlas-api/CLAUDE.md`](atlas-api/CLAUDE.md#the-daemon-serves-the-build-not-vite-dev)
- **Liveness is `GET /api/health`, never `/`** — the root page is the heaviest route and a UI 500 must not read as "API dead"
- **A health-probe timeout means busy, not dead** — `isUp()` counts only a refused connection as down, and `/api/projects` refreshes a stale cache in the background instead of serving it forever. Both cost a night of chasing a daemon that was up the whole time
- **Pollers use `launchctl kickstart` without `-k`** — `-k` SIGKILLs a live-but-slow job; plain `kickstart` no-ops on a running one, and `KeepAlive` handles real crashes. `-k` is only for deliberate restarts (`daemon:reload`)
- **Dev hostnames each cost two ACME certificates** — the NAS wildcard is `*.jurrejan.com` and does not reach `<slug>.atlas.local/remote.jurrejan.com`, so every `ensureRoute` issues two per-hostname certs and reloads the whole Caddyfile. Bulk registration needs a `*.atlas.local` / `*.atlas.remote` DNS-01 wildcard first (see `.orchestrate/report.md`, 2026-09-03)
- **atlas follows the dev server's port, it never sets it** — an injected `--port/--host` reaches
  only a single-process script that forwards its argv; a wrapper (`concurrently`, `turbo`) swallows
  the flags silently and a config-pinned Vite ignores them, so the hostname pointed at a port
  nothing was listening on. `/api/run` now polls `lsof -g <pgid>` (the spawn is `detached`, so the
  whole tree shares the group), prefers a LAN-reachable bind — Caddy proxies from the NAS and can't
  reach a loopback one — and writes what it finds back to `.atlas`
- **A spawned dev server must never inherit the daemon's `PORT`/`HOST`** — the plist sets
  `PORT=47891`, and anything honouring it (wrangler, next, nuxt, express) then aims at atlas-api's
  own port: wrangler dies on the spot (`Unexpected server response: 101`) and `--kill-others` takes
  its siblings with it. `/api/run` strips both and logs the child to `~/dev/.atlas-logs/<slug>.log`,
  since `stdio: 'ignore'` made every such death invisible
- **`/api/run` derives a project's running server from the OS, never from memory** — listeners
  on the project's port whose cwd is the project are stopped and waited for before every spawn
  (`stopProjectListeners`); an in-memory pid map died with each daemon restart and left the old
  server squatting the port, so Vite shifted to port+1 behind a hostname routed to the old one.
  `--host 0.0.0.0` is injected on its own even when the script pins `--port`, or the bind is
  loopback-only and the hostname 502s. The CLI asks `wait: 60000` and trusts `bound`, not the 8s guess
- **Never store an IP for a host** — every machine on this LAN is DHCP with no reservation and the M2 already drifted `.145` → `.180` once, silently breaking a cross-machine sync. `hosts.json` holds SSH aliases only
- **Writes are confined to the primary host by the API, not by the UI** — `resolveLocal()` (`$lib/config`) runs every path through `resolveInCatalog`, which rejects a non-absolute candidate first. Without that check a Windows path like `C:\dev\web\foo` is *relative* on macOS and resolves under the daemon's own cwd, which sits inside the catalog — so it passed the guard. Action gating is the second layer, never the only one
- **Git worktrees of atlas-api need `.claude/worktrees/shared` symlinked to `../shared`** — the `$shared` alias resolves relative to the repo root, so a worktree at `.claude/worktrees/<name>` can't build without it
