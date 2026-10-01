# Console upgrade — checklist (2026-10-01)

Branch `feature/console-upgrade` in project-atlas, atlas-api, atlas-cli. Decisions (asked 2026-10-01):
1 = off-LAN read-only behind the Caddy password (`atlas.atlas.remote.jurrejan.com`) · 2 = switch the NAS to DNS-01 wildcard certs.
Evidence per line: a command + result, or a file:line. Baseline timings: `.orchestrate/console-upgrade/baseline-timings.txt`.

## 1 · Consistent, modular console
- [ ] 1.1 one client fetch helper (checks `res.ok`, surfaces `{error}`) replaces browser/api.ts:7, disk-client.svelte.ts:16, claude-tree/+page.svelte:228
- [ ] 1.2 one `errorMessage` in src/lib replaces system/+page.server.ts:19, ScannerSection:24, DaemonsSection:34, HostsSection:39
- [ ] 1.3 one `tildify` in src/lib replaces ports/+page.svelte:56, disk-client:108, DiskArchiveModal:44
- [ ] 1.4 `ConfirmDialog` on Modal replaces native `confirm()` in ports and claude-tree
- [ ] 1.5 `Table` (sticky header, table-sort, row selection, keyboard focus) replaces table CSS in ports, DaemonsSection, disk.css, ProjectTable
- [ ] 1.6 one `Selection` model (disk-client vs ports plain-click disagreement resolved)
- [ ] 1.7 one sidebar tab nav replaces system/+page.svelte:56-136 and disk/+page.svelte:83-172
- [ ] 1.8 `Notice` for page state + one toast for action results; seven `.err` classes, `.failures` lists and claude-tree's toast gone
- [ ] 1.9 same loading / empty / error states on every page
- [ ] 1.10 claude-tree/+page.svelte split into components + tested logic modules on the ui primitives
- [ ] 1.11 claude-tree token alias layer (:1027-1047) and hex colours (:44-48) removed
- [ ] 1.12 ports/+page.svelte split by concern
- [ ] 1.13 `.quality.json` loc check covers every .svelte and every src/lib .ts (scanner.ts listed as exempt debt)
- [ ] 1.14 no new colours, fonts or visual language (existing tokens + primitives only)

## 2 · Write guard and off-LAN access
- [ ] 2.1 one guard in hooks.server.ts on every non-GET /api/*: loopback passes · trusted LAN host + matching Origin passes · off-LAN per decision 1 · else 403 with reason
- [ ] 2.2 /api/iterm and /api/finder loopback/LAN only
- [ ] 2.3 one real call each still works: CLI · Raycast extension · atlas-picker
- [ ] 2.4 decision 1 applied: atlas.atlas.remote.jurrejan.com behind the Caddy password, read-only
- [ ] 2.5 project list, ports and processes usable at 390px
- [ ] 2.6 console served compressed through the NAS

## 3 · Hostname brokering
- [ ] 3.1 `moveRoute` (ensure new, then remove old) used by atlas PATCH, rename and move
- [ ] 3.2 rename/move keep the route and update its path when a `.atlas` slug keeps the hostname
- [ ] 3.3 project-vs-project and project-vs-service slug clash → 409 naming the current holder
- [ ] 3.4 every slug write validated as a DNS label (1–63 of [a-z0-9-], no edge hyphen)
- [ ] 3.5 `removeRoute` keeps the row marked unsynced when the NAS removal fails; `nasSynced:false` shown with retry
- [ ] 3.6 `removeRouteByPath` inside the mutex; paths normalised to the ~/dev realpath; .atlas-hostnames.json migrated once (4 ~/Documents/development rows)
- [ ] 3.7 `hostnamesFor` reports remote unavailable when CADDY_DEV_AUTH_HASH is unset / no remote block written
- [ ] 3.8 hostname doctor: `atlas hostnames doctor [--fix] [--json]` + /system panel, a fix action per drift item
- [ ] 3.9 after assign/slug change the new https hostname is polled: "issuing certificate" → "live"
- [ ] 3.10 loopback-only dev servers routed through the services bridge
- [ ] 3.11 .atlas.local → WAN IP → 403 claim checked with `dig +short` + curl (Found if real)
- [ ] 3.12 decision 2 applied: DNS-01 wildcard certs for *.atlas.local / *.atlas.remote on the NAS Caddy

## 4 · Edit a project's hostname in the console
- [ ] 4.1 Hostname section: slug field with live preview of both URLs
- [ ] 4.2 `GET /api/hostnames/check?slug=&path=` (invalid · taken by <holder> · free) drives inline validation
- [ ] 4.3 devPublic toggle that says what it does
- [ ] 4.4 status pill: none · syncing · issuing certificate · live · failed (with retry)
- [ ] 4.5 copy, open and release buttons
- [ ] 4.6 saving a new slug calls `moveRoute` and shows the result in the dialog
- [ ] 4.7 port: number input 1024–65535, shows whether something listens on it now (NaN→null bug gone)
- [ ] 4.8 hostname link chip on the project row

## 5 · Ports and processes
- [ ] 5.1 one process snapshot module (one `ps -axww`, batched `lsof -d cwd`, netstat, in parallel, ~2s cache, docker skipped without its socket, projects from the in-memory index) behind both pages and the CLI
- [ ] 5.2 classifier: every process gets a kind (full list in the brief)
- [ ] 5.3 project attribution from cwd or a path in args
- [ ] 5.4 app rows fold wrapper chains (summed CPU/RSS, expandable children)
- [ ] 5.5 unit tests on fixture `ps` lines incl. atlas-api `bun build/index.js`, onenv as `node`, Adobe `….node`, argless `(Python)`
- [ ] 5.6 /processes: dev processes grouped by project by default, toggle to show everything
- [ ] 5.7 columns kind/name/project/ports/CPU/RSS/uptime/command/cwd; sort, search, filter by kind and project
- [ ] 5.8 header strip: memory pressure, swap, top consumers
- [ ] 5.9 CPU/RSS sparkline per row from a ring buffer sampled only while a client watches
- [ ] 5.10 flags: orphan, duplicate, idle, heavy
- [ ] 5.11 actions: stop (SIGTERM, SIGKILL only via explicit force after 5s), stop tree, restart atlas-run servers, open log, reveal cwd, copy pid/command, open hostname
- [ ] 5.12 bulk stop behind one ConfirmDialog listing every process that ends, children included
- [ ] 5.13 kill safety server-side for every caller (fresh snapshot pid+start time; refuse pid ≤1, atlas-api, other users, launchd jobs); old SIGKILL-from-cache kill replaced
- [ ] 5.14 /ports on the same snapshot, data in first paint: localhost + hostname links, owner → process row, audit collisions inline, macOS system port names, search by port/name/path
- [ ] 5.15 keys on both pages (`/` j k x Enter s); filters, sort, search in the URL
- [ ] 5.16 agent session name from CLD_SESSION_NAME only, server-side; no environment sent to client or log
- [ ] 5.17 this Mac only (no remote hosts' processes)

## 6 · CLI for agents
- [ ] 6.1 `--json` on every command that prints data; text output unchanged
- [ ] 6.2 API error → API's message on stderr, exit 1; disk's exit codes kept
- [ ] 6.3 `atlas ps [--project] [--kind] [--all] [--json]`
- [ ] 6.4 `atlas kill <pid|:port|project> [--tree] [--force] [--dry-run] [--yes]` (server-side safety, prints targets, --yes required without TTY)
- [ ] 6.5 `atlas stop [path]`
- [ ] 6.6 `atlas set <key> <value>` / `atlas set --unset <key>` via PATCH /api/atlas; slug change moves the route
- [ ] 6.7 `atlas hostnames check|doctor`
- [ ] 6.8 `atlas daemons [restart <label>]`
- [ ] 6.9 `atlas ports --json`
- [ ] 6.10 GUI-only (iterm, finder) and duplicate-tool routes (git, readme, bd) skipped on purpose
- [ ] 6.11 `atlas prime` updated (workflows, --json list, new commands); `atlas install-autocompletion` rerun
- [ ] 6.12 agent-friendly-cli score before and after

## Contract
- [ ] C.1 /api/processes response shape fixed before 5 and 6 split

## Done when
- [ ] D.1 gates: atlas-api `just check` + `bunx vitest run`; atlas-cli `bun run check` + `bun test`; atlas-picker `just reinstall` only if project.rs changed
- [ ] D.2 timings before/after, 3 runs: `/` <300ms <500KB · fresh snapshot <150ms · warm <30ms
- [ ] D.3 every new/changed page checked in the browser at desktop width and 390px
- [ ] D.4 docs: root CLAUDE.md (API table, routes, vocabulary: process snapshot, process kind, app row) · atlas-api/CLAUDE.md · atlas-hostname SKILL.md:117 · report.md citation → .orchestrate/findings/mechanism.md
- [ ] D.5 report .orchestrate/report-2026-10-01-console-upgrade.md (timing table, both CLI scores; Blocked on me / Changed / Found)

## Found along the way
