# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-component workspace for indexing and navigating development projects. A SvelteKit backend scans directories and exposes a JSON API consumed by a Raycast extension and a Rust TUI.

<vocabulary>
Canonical names — use these exact terms across all three consumers; they are this project's ubiquitous language.

- **Project** — one scanned development folder. The core record (`name`, `path`, `type`, `framework`, `runner`, `git`, `scripts`, `deploy`, `beads`, `domains`, `umami`, …).
- **domains** — the production domains a project publishes on, detected from its own files (CNAME, vercel/wrangler config, `package.json` homepage, `og:url`, robots.txt, env). Never fetched from a provider.
- **umami** — the Umami analytics link: `websiteIds` found in the project's tracking snippets plus the `instance` base URL. Dashboard URL is `{instance}/websites/{websiteId}`.
- **ProjectAtlas** — the full scan result: projects + folders + detected frameworks. The `/api/projects` payload shape.
- **Scanner** — the atlas-api module (`scanner.ts`) that walks `~/Documents/development` and produces a ProjectAtlas. The source of truth for the Project shape.
- **cache** — `.atlas-cache.json`, the persisted ProjectAtlas (60s TTL, stale-while-revalidate). atlas-picker reads it directly.
- **Framework / Runner / GitStatus / DeployInfo** — the typed enums/structs on a Project. Names must match byte-for-byte across consumers (see `.claude/rules/shared-types.md`).
- **action registry** — `shared/actions.json`: what project actions exist and when. Not "commands", not "buttons".
- **daemon registry** — `shared/daemons.json`: the launchd daemons atlas displays/manages.
- **consumer** — one of the three UIs reading the shared shapes: atlas-api, atlas-browser, atlas-picker.
</vocabulary>

## Components

| Component | Path | Stack | Purpose |
|-----------|------|-------|---------|
| **atlas-api** | `atlas-api/` | SvelteKit 2, Svelte 5, Bun | Backend API on port 47891 — scans `~/Documents/development`, caches results, serves project metadata |
| **atlas-browser** | `atlas-browser/` | Raycast extension, React, TS | Raycast UI for browsing/filtering/acting on projects |
| **atlas-picker** | `atlas-picker/` | Rust, iocraft, Nucleo | TUI fuzzy picker that reads from the API cache file directly |
| **atlas-cli** | `atlas-cli/` | Bun, TS | Global **`atlas`** command — thin client to the API (`tree`/`init`/`new`/`scan`/`open`/`jump`/`pick`/`ports`/`agent-log`/`prime`). Replaces per-project justfile recipes; `atlas new` is the scaffolding front door. `atlas prime` briefs a session (wired as a global SessionStart hook; `atlas agent-log session-end` as SessionEnd) |
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
recipe is a thin `atlas tree web` alias. `atlas init` replaces the old `atlas-init` zsh function.
`atlas jump <query>` (aliased `pj`) cds the shell to the best match — no query opens the fuzzy
picker, and `--run <cmd>` runs a command there (`pj atlas --run bun test`); `atlas <query> --run
<cmd>` is the same thing. It needs `shell/atlas.zsh` sourced — that wrapper evals what the CLI
writes to `$ATLAS_SHELL_FILE`, since a child process can't cd its parent shell.
`atlas new` scaffolds a project — pick category → cookiecutter template → it appears in atlas
instantly (forces a rescan). Replaces the standalone `_management/cookiecutter-picker`.

## Architecture

### Data flow

1. **atlas-api** scans `~/Documents/development` recursively (3 levels max), detects project type/framework/runner/git/scripts/justfile/deploy
2. Results cached in `~/Documents/development/.atlas-cache.json` (60s TTL, stale-while-revalidate)
3. **atlas-browser** fetches from `GET /api/projects` — Raycast UI with filters, search, and quick actions
4. **atlas-picker** reads the cache file directly for instant startup, refreshes via API on Ctrl+R
5. **atlas-watchdog** monitors port 47891 every 30s and restarts via launchd if down

### API (atlas-api, port 47891)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/projects` | GET | Main data endpoint (query: `?dir=`, `?includeArchived=true`) |
| `/api/refresh` | POST | Force rescan |
| `/api/git` | POST | Batch git status (`{ paths: [] }`) |
| `/api/run` | POST/DELETE | Spawn/kill dev server |
| `/api/readme` | POST | Lazy README load |
| `/api/description` | PUT | Update project description |
| `/api/iterm` | POST | Open iTerm via AppleScript |
| `/api/finder` | POST | Open Finder |
| `/api/rename` | POST | Rename project folder |
| `/api/move` | POST | Move project folder |
| `/api/agent-files` | GET/POST/PUT | CLAUDE.md and AGENTS.md operations |
| `/api/archive` | POST | Archive/unarchive project (`{ path, archived }`) |
| `/api/beads` | POST | Create beads ticket via `bd create --silent` (`{ path, title, description?, priority?, issue_type?, labels? }`); 400 without a `.beads` db |
| `/api/agent-log` | GET | Project's agent journal (`?path=`): visible events, active intent count, latest handoff — readonly open of `agent-log.sqlite`, empty payload for non-git/missing db |
| `/api/daemons` | GET | List launchd daemons with live state, port check, stale-path detection |
| `/api/daemons/:label` | POST | Lifecycle action (`{ action: 'start'\|'stop'\|'restart' }`); gated by `ATLAS_DAEMON_WRITE=1`, blocked on `selfManaged` daemons |
| `/api/categories` | GET | Depth-1 dev categories from the cached scan (`{ name, projectCount, dominantType }`) — for `atlas new` |
| `/api/templates` | GET | Discover cookiecutter templates under `ATLAS_TEMPLATES_DIR` (`{ family, name, description, version, path, variables }`) |
| `/api/ports/allocate` | GET | Allocate an unused port from the atlas range (4100–4999) for a scaffolded project (`{ port }`) |
| `/api/ports/audit` | GET | Report-only port-collision check across daemons + scanned projects (`{ collisions, unmanaged }`) — never writes |

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
- `~/Documents/development/python/reminders-bridge/launchd/com.jurrejan.reminders-bridge.plist`
- `~/Documents/development/dl-watcher/launchd/com.jurrejan.dlwatcher.plist`
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
- **Pollers use `launchctl kickstart` without `-k`** — `-k` SIGKILLs a live-but-slow job; plain `kickstart` no-ops on a running one, and `KeepAlive` handles real crashes. `-k` is only for deliberate restarts (`daemon:reload`)
