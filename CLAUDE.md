# project-atlas

Multi-component workspace for indexing and navigating JJ's development projects. atlas-api scans
`~/dev` (plus two remote hosts), caches the result and serves a JSON API and a web console; a
Raycast extension, a Rust TUI and the global `atlas` CLI consume it. Each component is its own git
repo with its own `CLAUDE.md`.

<vocabulary>
Canonical terms, byte-for-byte across all consumers. Full definitions: docs/glossary.md.

- **Project** (one scanned folder) · **ProjectAtlas** (the scan result, `/api/projects` shape) · **Scanner** (`atlas-api/src/lib/scanner.ts`, source of truth for the shape) · **cache** (`~/dev/.atlas-cache.json`) · **scan config** (`.atlas-config.json`; per-project overrides live in `.atlas`).
- **slug** → **dev hostname** `<slug>.atlas.local|remote.jurrejan.com`, pushed to the NAS Caddy. **service** — a permanent web UI with a hostname but no project.
- **host** — a machine in `shared/hosts.json`: `m2` (primary, this Mac), `fractal`, `ubuntu`. **isLocal** — present only on primary-host projects. **alsoOn** — the same project on another host. **scan agent** — the scanner bundled for remote hosts.
- **action / daemon / host / service / template registry** — the JSON files in `shared/` ("action", never "command" or "button"). **consumer** — atlas-api, atlas-browser or atlas-picker.
- **web console** (atlas-api's UI) · **write guard** (`atlas-api/src/lib/guard.ts`) · **process snapshot** (this Mac only) · **disk** (`atlas disk`) · **board** (global agent message board) vs **agent journal** (`agent-log`, per repo).
</vocabulary>

## Components

| Component | Stack | Purpose |
|-----------|-------|---------|
| `atlas-api/` | SvelteKit 2, Svelte 5, Bun | Backend API + web console on `:47891`; scans, caches, serves project metadata |
| `atlas-browser/` | Raycast extension, React, TS | Browse/filter/act on projects; `src/daemons.tsx` views/restarts launchd daemons |
| `atlas-picker/` | Rust, iocraft, Nucleo | TUI fuzzy picker; reads the cache file directly, refreshes via the API on Ctrl+R |
| `atlas-cli/` | Bun, TS | Global `atlas` command, thin client to the API. `atlas prime` is the agent crash course; `atlas brief` is the global SessionStart hook |
| `atlas-disk/` | Rust, iocraft | Terminal screen for `atlas disk` (`atlas disk tui`); shells out to `atlas disk … --json` |
| `atlas-watchdog/` | Bash (Raycast script cmd) | Polls `/api/health` every 30s, restarts via `launchctl kickstart com.jurrejan.atlas-api` |
| `shared/` | JSON + TS | The registries, read by every consumer |

**Before editing these, read the local context:**
- `shared/` (the registries) → `shared/CLAUDE.md`
- the synced scanner types (`scanner.ts` × 2, `project.rs`) → `.claude/rules/shared-types.md` (loads
  automatically when you open those files)

See `atlas-api/docs/api.md` for the route table and `atlas-cli/docs/commands.md` for every `atlas`
subcommand.

## Commands

```bash
./bootstrap.sh [--apps atlas-api --run | --list]   # interactive install/run; components in apps.manifest
just all                                           # build + install every component
cd atlas-api     && bun run check && bun run daemon:reload
cd atlas-browser && npm run build                  # ray build; npm run dev = ray develop
cd atlas-picker  && just reinstall                 # lint + fmt-check + release install (also atlas-disk)
cd atlas-cli     && bunx tsc --noEmit && bun link
```

`apps.manifest` is pipe-delimited: `id|name|path|tools|install|run|os|deps`. `pj` (=`atlas jump`)
needs `atlas-cli/shell/atlas.zsh` sourced: a child process can't cd its parent shell.

## Data flow

1. atlas-api scans `~/dev` (depth from the scan config, default 3) and detects
   type/framework/runner/git/scripts/justfile/deploy.
2. Results land in `~/dev/.atlas-cache.json` (60s TTL, stale-while-revalidate).
3. atlas-browser and atlas-cli read `GET /api/projects`; atlas-picker reads the cache file.
4. atlas-watchdog keeps `:47891` up.

## Multi-host catalog

`m2` (`~/dev`, in-process every 60s), `fractal` (`C:/dev`, scan agent over SSH, git skipped) and
`ubuntu` (`/home/jurrejan/development`, scan agent over SSH). Only the Mac is ever written to.

- **Remote scans never block a request.** `GET /api/projects` answers from the merged cache and
  kicks a TTL-guarded (10 min) background sweep. A powered-off host keeps its last projects and
  reads `status: 'unreachable'` in `hosts[]`.
- **Fragments, then one merge.** Each remote host's projects live in `~/dev/.atlas-cache-<id>.json`;
  `finalizeAtlas()` folds them in idempotently (it drops non-local projects before re-merging),
  which stops the 60s revalidation from overwriting the catalog with a local-only scan.
- **`git` runs only on local projects** during cache enrichment.
- **Ports are per host.** `/api/ports/audit` and `allocatePort` see only this machine's listeners.

## Registries (`shared/`)

Each `.json` is the single source of truth; `shared/CLAUDE.md` has how each consumer imports it.

- **Edit the JSON first**, then consumer rendering only if needed. A registry defines *what* and
  *when*, never *how*: each consumer keeps its own execution logic.
- **`selfManaged: true`** (on `com.jurrejan.atlas-api`) blocks lifecycle actions from the API;
  atlas-watchdog is that daemon's sole supervisor.
- **Plists are edited by humans only**; atlas never writes one. `daemons.json` `plist` points at
  each source plist.

## Invariants

- **Svelte 5 runes** in atlas-api (`$state`, `$props`, `$effect`), no stores. **Bun** for every TS
  project. **Rust builds** always go through `just reinstall`.
- atlas-picker renders to `/dev/tty` to keep stdout free for the `pj` shell integration.
- **The atlas-api daemon serves the build (`bun build/index.js`), never `vite dev`** (health checks
  kill vite mid-boot). Source edits reach it only after `bun run daemon:reload`.
- **Liveness is `GET /api/health`, never `/`**: a UI 500 must not read as "API dead".
- **A health-probe timeout means busy, not dead.** `isUp()` counts only a refused connection as
  down.
- **Pollers use `launchctl kickstart` without `-k`.** `-k` SIGKILLs a live-but-slow job; plain
  `kickstart` no-ops on a running one and `KeepAlive` handles crashes. `-k` only in
  `daemon:reload`.
- **Dev hostnames ride one NAS wildcard cert** (`sites/atlas-wildcard.caddy`); without it every
  `ensureRoute` issues certs again (doctor: `wildcard-missing`). See `.orchestrate/findings/mechanism.md`.
- **Remote hostnames are gated by `forward_auth` → `/gate/<slug>`** (cookie or IP allowlist,
  `~/dev/.atlas-gate.json`), never by `basic_auth`. See `atlas-api/docs/api.md`.
- **Never store an IP for a host.** The LAN is DHCP without reservations; `hosts.json` holds SSH
  aliases only.
- **Writes are confined to the primary host by the API, not the UI** (`resolveLocal()`, see
  `atlas-api/CLAUDE.md`); action gating on `isLocal` is the second layer, never the only one.
- **Worktrees of atlas-api need `.claude/worktrees/shared` symlinked to `../shared`**: the
  `$shared` alias resolves relative to the repo root.
