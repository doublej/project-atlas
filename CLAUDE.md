# project-atlas

Multi-component workspace for indexing and navigating JJ's development projects. atlas-api scans
`~/dev` (plus two remote hosts), caches the result and serves a JSON API and a web console; a
Raycast extension, a Rust TUI and the global `atlas` CLI consume it. Each component is its own git
repo with its own `CLAUDE.md`.

<vocabulary>
Canonical terms, used byte-for-byte across all consumers. Full definitions: docs/glossary.md.

- **Project** — one scanned development folder; the core record. **ProjectAtlas** — the full scan result (projects + folders + frameworks), the `/api/projects` shape.
- **Scanner** — `atlas-api/src/lib/scanner.ts`, source of truth for the Project shape. **cache** — `~/dev/.atlas-cache.json` (60s TTL, stale-while-revalidate); atlas-picker reads it directly.
- **scan config** — `.atlas-config.json` at the scan root: `maxDepth`, per-subtree `depth`, `force`, `ignore`. Per-project overrides live in that project's `.atlas`.
- **slug** — kebab-case DNS label from the folder name (`.atlas` `slug` overrides). **dev hostname** — `<slug>.atlas.local.jurrejan.com` (LAN) / `<slug>.atlas.remote.jurrejan.com` (password-gated WAN), pushed to the NAS Caddy by `atlas-api/src/lib/caddyDev.ts`.
- **host** — a catalogued machine from `shared/hosts.json`: `m2` (this Mac, **primary**), `fractal` (satellite), `ubuntu` (deploy). Machine axis; `remote` in a hostname is the reachability axis.
- **isLocal** — present only on the primary host's projects; its absence hides every filesystem/GUI action. **alsoOn** — the same project on another machine, by exact name match.
- **service** — a permanent local web UI (atlas console, deckhand) given a dev hostname without being a project (`atlas-api/src/lib/services.ts`).
- **scan agent** — the bundled scanner shipped to remote hosts by `atlas hosts sync`; `--json` prints a ProjectAtlas and writes nothing.
- **registries** (all in `shared/`): **action registry** `actions.json` (not "commands"/"buttons"), **daemon registry** `daemons.json`, **host registry** `hosts.json`, **service registry** `services.json`, template registry `templates.json`.
- **consumer** — atlas-api, atlas-browser or atlas-picker reading the shared shapes. **Framework / Runner / GitStatus / DeployInfo** — typed fields on a Project; names match across consumers.
- **domains**, **umami**, **tags**, **descriptions**, **agentInterfaces**, **claudeSetup**, **flow** — Project fields; tags and descriptions live centrally in `~/dev/.atlas-tags.json` / `.atlas-descriptions.json` so they never dirty a repo.
- **web console** — atlas-api's own UI (`/`, `/ports`, `/processes`, `/system`, `/templates`, `/claude-tree`, `/disk`, `/agents`). **write guard** — `atlas-api/src/lib/guard.ts`, the per-request access check.
- **process snapshot** / **process kind** / **app row** — `atlas-api/src/lib/processes/`, this Mac only; other hosts' processes are deckhand's.
- **disk** — `atlas disk`, the disk-space manager (archive · clean · trim), local-only. **board** — `atlas board`, the agents' global message board; not the per-repo **agent journal** (`agent-log`).
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
- **The atlas-api daemon serves the adapter-node build (`bun build/index.js`), never `vite dev`**:
  vite needs ~70s for its first response and health checks kill it mid-boot. Source edits reach
  the daemon only after `bun run daemon:reload`.
- **Liveness is `GET /api/health`, never `/`**: a UI 500 must not read as "API dead".
- **A health-probe timeout means busy, not dead.** `isUp()` counts only a refused connection as
  down.
- **Pollers use `launchctl kickstart` without `-k`.** `-k` SIGKILLs a live-but-slow job; plain
  `kickstart` no-ops on a running one and `KeepAlive` handles crashes. `-k` only in
  `daemon:reload`.
- **Dev hostnames ride one NAS wildcard cert** (`sites/atlas-wildcard.caddy`, DNS-01): a push is a
  site file plus `caddy validate` + reload. If that file goes, every `ensureRoute` issues two
  certs again; the hostname doctor reports `wildcard-missing`. Mechanism:
  `.orchestrate/findings/mechanism.md`.
- **Never store an IP for a host.** The LAN is DHCP without reservations; `hosts.json` holds SSH
  aliases only.
- **Writes are confined to the primary host by the API, not the UI** (`resolveLocal()`, see
  `atlas-api/CLAUDE.md`); action gating on `isLocal` is the second layer, never the only one.
- **Worktrees of atlas-api need `.claude/worktrees/shared` symlinked to `../shared`**: the
  `$shared` alias resolves relative to the repo root.
