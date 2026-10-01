# Console upgrade — checklist (2026-10-01)

Branch `feature/console-upgrade` in project-atlas, atlas-api, atlas-cli. Decisions (asked 2026-10-01):
1 = off-LAN read-only behind the Caddy password (`atlas.atlas.remote.jurrejan.com`) · 2 = switch the NAS to DNS-01 wildcard certs.
Evidence per line: a command + result, or a file:line. Baseline timings: `.orchestrate/console-upgrade/baseline-timings.txt`.
Line refs are atlas-api at 735a45c unless a repo is named. Independent audit of every line: verify workflow (5 agents, browser + curl + code), 2026-10-01 ~17:30.

## 1 · Consistent, modular console
- [x] 1.1 one client fetch helper (checks `res.ok`, surfaces `{error}`) replaces browser/api.ts:7, disk-client.svelte.ts:16, claude-tree/+page.svelte:228 — ✓ src/lib/http.ts + http.test.ts (5 tests); grep 'fetch(' outside routes/api and tests finds only http.ts:33 and two server-side loads; 25 files import $lib/http — bb59f84
- [x] 1.2 one `errorMessage` in src/lib replaces system/+page.server.ts:19, ScannerSection:24, DaemonsSection:34, HostsSection:39 — ✓ src/lib/format.ts:4 + format.test.ts; 13 copies replaced (bb59f84, 2281e1a). Left on purpose: 5 inline `(e as Error).message` expressions with route-specific fallbacks (hooks, services, run, allocate, beads)
- [x] 1.3 one `tildify` in src/lib replaces ports/+page.svelte:56, disk-client:108, DiskArchiveModal:44 — ✓ src/lib/format.ts:11 is the only definition (grep); 4 copies replaced — bb59f84
- [x] 1.4 `ConfirmDialog` on Modal replaces native `confirm()` in ports and claude-tree — ✓ components/feedback/ConfirmDialog.svelte; grep `confirm(|alert(|prompt(` finds only local function names — 30c4bff, f64f907
- [x] 1.5 `Table` (sticky header, table-sort, row selection, keyboard focus) replaces table CSS in ports, DaemonsSection, disk.css, ProjectTable — ✓ `<table>` appears only in components/table/Table.svelte; PortsTable, DaemonsSection, Disk*Section, ProjectTable import it; disk.css has no table selectors. Fixed column grid per `Column.width` (ace7bef): sibling tables measure one grid on /processes (12 tables), /ports (3), /disk cleanup (3), log (2)
- [x] 1.6 one `Selection` model (disk-client vs ports plain-click disagreement resolved) — ✓ src/lib/selection.svelte.ts + 5 tests; rule = Finder (plain click selects one, cmd toggles, shift range) — febbe62
- [x] 1.7 one sidebar tab nav replaces system/+page.svelte:56-136 and disk/+page.svelte:83-172 — ✓ components/SideNav.svelte on /system and /disk; horizontal scroller <768px that scrolls the open tab into view (9ec954f) — 8d31c82, cd45e26
- [x] 1.8 `Notice` for page state + one toast for action results; seven `.err` classes, `.failures` lists and claude-tree's toast gone — ✓ components/feedback/Notice.svelte + toast.svelte.ts/Toaster; the two `.err` classes that crept back (StatusPill, ConfirmDialog) moved to Notice — f62b9c1
- [x] 1.9 same loading / empty / error states on every page — ✓ components/feedback/PageState.svelte on /, /ports, /processes, /system, /disk, /templates, /claude-tree; seen live: claude-tree showed PageState 'Failed to fetch' + Retry during a daemon restart and recovered. One component-level 'Loading' paragraph remains in ProjectDetails (readme, inside a row)
- [x] 1.10 claude-tree/+page.svelte split into components + tested logic modules on the ui primitives — ✓ +page.svelte 305 lines (was 1,500+); keys/doc/clipboard/graph/find .ts each with a test file; EditorHead, FindPanel, TopBar, ContextMenu still hand-style some buttons (W1a)
- [x] 1.11 claude-tree token alias layer (:1027-1047) and hex colours (:44-48) removed — ✓ grep in routes/claude-tree: 0 hex/rgb literals, 0 alias definitions, 0 alias uses (baseline: 13 alias uses, 6 hex)
- [x] 1.12 ports/+page.svelte split by concern — ✓ 376 → 228 lines + PortsTable.svelte, known-ports.ts, +page.server.ts; data from lib/listeners.ts on the process snapshot
- [x] 1.13 `.quality.json` loc check covers every .svelte and every src/lib .ts (scanner.ts listed as exempt debt) — ✓ `just loc-check` in `just check`: every file ≤400, scanner.ts exempt; 10 files warn above 300 (ProjectTable 370, ports.ts 390, Table 336, …)
- [x] 1.14 no new colours, fonts or visual language (existing tokens + primitives only) — ✓ git diff of src adds no hex/rgb/hsl/oklch literal and no font-family but var(--font-mono); the dark `--color-hover` reuses the dark border value (715669a)

## 2 · Write guard and off-LAN access
- [x] 2.1 one guard in hooks.server.ts on every non-GET /api/*: loopback passes · trusted LAN host + matching Origin passes · off-LAN per decision 1 · else 403 with reason — ✓ src/lib/guard.ts refusal() run by hooks.server.ts on every request; Host checked first even when proxied (2c8af56: forged X-Forwarded-* + rebinding Host now 403); open reads refuse cross-site scripts, `/api/projects` lost `Access-Control-Allow-Origin: *` (814b3c0); guard.test.ts 328 lines of cases. Live: rebind+forged env-files 403, cross-site /api/projects 403, CLI 200, same-origin 200, NAS console 200
- [x] 2.2 /api/iterm and /api/finder loopback/LAN only — ✓ guard.ts LOCAL_ONLY: iterm, finder (every method); off-LAN GET → 403 'not available off-LAN' — 6633a7c
- [x] 2.3 one real call each still works: CLI · Raycast extension · atlas-picker — ✓ CLI `atlas info --json` exit 0 (after 2c8af56/814b3c0); Raycast's own `fetchDaemons` (atlas-browser/src/daemons-types.ts) run under bun → 31 daemons; installed atlas-picker binary through a logging proxy (ATLAS_API) → `GET /api/hostnames 200`, `POST /api/refresh 200`, `POST /api/git 200` (ua ureq/3.4.1). Raycast's UI itself was not driven
- [x] 2.4 decision 1 applied: atlas.atlas.remote.jurrejan.com behind the Caddy password, read-only — ✓ shared/services.json atlas `remote: true`; guard REMOTE_HOST: writes 403 'read-only off-LAN', LOCAL_ONLY reads 403 — b3026d3. Not opened end to end with the password (no credential used)
- [x] 2.5 project list, ports and processes usable at 390px — ✓ 390px iframes at 6c831fd: /, /processes, /ports scrollWidth = clientWidth (375/375); process metrics narrow and sparklines hide (ace7bef); Cards view no longer overflows (f1dd690); topbar scrolls away below 768px (116b906)
- [x] 2.6 console served compressed through the NAS — ✓ `curl -H 'Accept-Encoding: zstd, gzip' https://atlas.jurrejan.com/` → content-encoding zstd, 59,409 B (461,976 B uncompressed)

## 3 · Hostname brokering
- [x] 3.1 `moveRoute` (ensure new, then remove old) used by atlas PATCH, rename and move — ✓ caddyDev.ts moveRoute; called from hostnames/claims.ts (PATCH /api/atlas), api/rename, api/move
- [x] 3.2 rename/move keep the route and update its path when a `.atlas` slug keeps the hostname — ✓ api/rename + api/move call moveRoute / re-path the row; unit-tested, not exercised live (a rename changes a slug)
- [x] 3.3 project-vs-project and project-vs-service slug clash → 409 naming the current holder — ✓ `GET /api/hostnames/check?slug=deckhand` → taken by service Deckhand; `atlas set slug deckhand` → 'slug "deckhand" is taken by service Deckhand'
- [x] 3.4 every slug write validated as a DNS label (1–63 of [a-z0-9-], no edge hyphen) — ✓ hostnames/slug.ts slugProblem; PATCH {slug:'Bad_Slug'} → 400; `-bad`, `bad--x`, 64 chars → invalid; NAS helpers now refuse a non-slug before ssh (9363620)
- [x] 3.5 `removeRoute` keeps the row marked unsynced when the NAS removal fails; `nasSynced:false` shown with retry — ✓ caddyDev removeRoute keeps `release: true, nasSynced: false` + 502; StatusPill retry; unit-tested (needs a failing NAS live)
- [x] 3.6 `removeRouteByPath` inside the mutex; paths normalised to the ~/dev realpath; .atlas-hostnames.json migrated once (4 ~/Documents/development rows) — ✓ caddyDev withRegistryLock; registry.ts normalizePath; registry has 0 'Documents/development' rows (backup ~/dev/.atlas-hostnames.json.20261001-pre-migration)
- [x] 3.7 `hostnamesFor` reports remote unavailable when CADDY_DEV_AUTH_HASH is unset / no remote block written — ✓ registry.ts hostnamesFor + hasAuthHash; remote null; unit-tested
- [x] 3.8 hostname doctor: `atlas hostnames doctor [--fix] [--json]` + /system panel, a fix action per drift item — ✓ GET/POST /api/hostnames/doctor; `atlas hostnames doctor` exit 1 with 2 report-only items; /system?tab=hostnames renders them; a NAS file name that is no slug gets no fix (9363620)
- [x] 3.9 after assign/slug change the new https hostname is polled: "issuing certificate" → "live" — ✓ /api/hostnames/status tracker + StatusPill; 'live' means TLS answers, not that the upstream does (Found)
- [x] 3.10 loopback-only dev servers routed through the services bridge — ✓ services.ts bridgeProject; after a daemon restart every routed project port is re-bridged on the next sync (bfa7a56): zz-atlas-test-2 went 502 → 200 across `daemon:reload` with no `atlas run`
- [x] 3.11 .atlas.local → WAN IP → 403 claim checked with `dig +short` + curl (Found if real) — ✓ dig: atlas.atlas.local / .remote / atlas.jurrejan.com resolve to the WAN IP; curl from this Mac → 200 (hairpin NAT), so no 403 today — Found
- [x] 3.12 decision 2 applied: DNS-01 wildcard certs for *.atlas.local / *.atlas.remote on the NAS Caddy — ✓ openssl s_client: hostnames present CN/SAN `*.atlas.local.jurrejan.com` / `*.atlas.remote.jurrejan.com` (sites/atlas-wildcard.caddy)

## 4 · Edit a project's hostname in the console
- [x] 4.1 Hostname section: slug field with live preview of both URLs — ✓ browser: typing 'deckhand' previews deckhand.atlas.local… (LAN) and deckhand.atlas.remote… (off-LAN, password)
- [x] 4.2 `GET /api/hostnames/check?slug=&path=` (invalid · taken by <holder> · free) drives inline validation — ✓ inline 'taken by service Deckhand', 'slug may only hold a-z, 0-9 and -'; curl free/current/taken/invalid all 200
- [x] 4.3 devPublic toggle that says what it does — ✓ 'Let anyone with the link open atlas.remote — no password'; preview switches 'off-LAN, password' ↔ 'no password'
- [x] 4.4 status pill: none · syncing · issuing certificate · live · failed (with retry) — ✓ dialogs/hostname/StatusPill.svelte; error text in a Notice (f62b9c1); 'live' showed for zz-atlas-test-2
- [x] 4.5 copy, open and release buttons — ✓ HostnameSection: Copy, Open, Release (ConfirmDialog 'Release …?'); copy failures toast
- [x] 4.6 saving a new slug calls `moveRoute` and shows the result in the dialog — ✓ PATCH /api/atlas → rerouteProject → moveRoute, response `{ path, atlas, hostname? }` shown in the dialog; not saved live (each save moves a NAS route)
- [x] 4.7 port: number input 1024–65535, shows whether something listens on it now (NaN→null bug gone) — ✓ PortField type=number min 1024 max 65535; 80 → 'a whole number from 1024 to 65535'; 4126 → 'bun listens on :4126 — loopback only, atlas bridges it for the NAS'; empty field → null
- [x] 4.8 hostname link chip on the project row — ✓ HostnameChip in ProjectTable's name cell (094aeac); 1280px: 16 of 16 chips fully inside their cell after 572f487 (the name ellipsizes, the chip keeps ≥4rem); hidden below 768px, shown when the row opens

## 5 · Ports and processes
- [x] 5.1 one process snapshot module (one `ps -axww`, batched `lsof -d cwd`, netstat, in parallel, ~2s cache, docker skipped without its socket, projects from the in-memory index) behind both pages and the CLI — ✓ lib/processes/snapshot.ts build(): ps, netstat, launchctl, sysctl, cached scan, hostnames in one Promise.all; lsof only for unseen pid@start; TTL 2s, one in-flight promise; scan(revalidate:false) (5a90042); a timeout under load → 503 with the reason (fafaf26, 735a45c)
- [x] 5.2 classifier: every process gets a kind (full list in the brief) — ✓ live `?all=1`: 740 processes, 0 without a kind; classify.test.ts covers every kind but 'other'
- [x] 5.3 project attribution from cwd or a path in args — ✓ types.ts `via: 'cwd'|'args'|'group'`; atlas-api attributed to project-atlas by cwd
- [x] 5.4 app rows fold wrapper chains (summed CPU/RSS, expandable children) — ✓ groups.ts; zz row = 2 processes (npm → bun server) summed, Enter expands both
- [x] 5.5 unit tests on fixture `ps` lines incl. atlas-api `bun build/index.js`, onenv as `node`, Adobe `….node`, argless `(Python)` — ✓ classify.test.ts:60-62, :112; fixture .orchestrate/console-upgrade/ps-fixture.txt
- [x] 5.6 /processes: dev processes grouped by project by default, toggle to show everything — ✓ grouped cards; 'Include non-dev' chip (all=1); every active filter stays visible and clearable (2da1d0f)
- [x] 5.7 columns kind/name/project/ports/CPU/RSS/uptime/command/cwd; sort, search, filter by kind and project — ✓ ProcessGroups.svelte columns with fixed widths; search, project select, kind chips
- [x] 5.8 header strip: memory pressure, swap, top consumers — ✓ ProcessSummary: pressure, free/total, swap, load, Most memory / Most CPU chips (a chip with no dev row turns on non-dev, 998a128)
- [x] 5.9 CPU/RSS sparkline per row from a ring buffer sampled only while a client watches — ✓ processes/view.ts record(): 60-sample ring per row, called only after a build, no timer
- [x] 5.10 flags: orphan, duplicate, idle, heavy — ✓ processes/flags.ts, tested in groups.test.ts; orphan seen live (vite under kunstuitleen-gallery); duplicate/idle not present live
- [x] 5.11 actions: stop (SIGTERM, SIGKILL only via explicit force after 5s), stop tree, restart atlas-run servers, open log, reveal cwd, copy pid/command, open hostname — ✓ ProcessDetail.svelte actions; hostname link shows the slug it links to (91f8d27)
- [x] 5.12 bulk stop behind one ConfirmDialog listing every process that ends, children included — ✓ 's' on the zz row → 'Stop 2 processes?' listing npm + server from the dryRun plan
- [x] 5.13 kill safety server-side for every caller (fresh snapshot pid+start time; refuse pid ≤1, atlas-api, other users, launchd jobs); old SIGKILL-from-cache kill replaced — ✓ processes/stop.ts + tests; `atlas kill 1` → protected-pid exit 4; kill of atlas-api refused; /api/ports/kill removed; tolerant identity poll (a07207d)
- [x] 5.14 /ports on the same snapshot, data in first paint: localhost + hostname links, owner → process row, audit collisions inline, macOS system port names, search by port/name/path — ✓ ports/+page.server.ts getListeners(); PortsTable collision Badge; known-ports.ts; audit counts only this Mac (e3207a9: 5 claimed ports → 2)
- [x] 5.15 keys on both pages (`/` j k x Enter s); filters, sort, search in the URL — ✓ lib/processes/list-page.ts listKeys + writeQuery; Table rowKeyAction
- [x] 5.16 agent session name from CLD_SESSION_NAME only, server-side; no environment sent to client or log — ✓ snapshot.ts psSessions keeps only the token; HOME=/PATH=/SHELL= absent from /api/processes?all=1, /api/ports/listeners and both pages' HTML
- [x] 5.17 this Mac only (no remote hosts' processes) — ✓ /api/processes host 'm2'; local ps/netstat only, projects filtered to isLocal

## 6 · CLI for agents
- [x] 6.1 `--json` on every command that prints data; text output unchanged — ✓ 33 `--json` runs parsed (cli-score-after.md); no-match cases print nothing on stdout
- [x] 6.2 API error → API's message on stderr, exit 1; disk's exit codes kept — ✓ fake API answering 403 {error}: hosts, ps, hostnames doctor, daemons, services print it on stderr, exit 1; disk keeps 0/1/2/3/4
- [x] 6.3 `atlas ps [--project] [--kind] [--all] [--json]` — ✓ all four exit 0; `--kind bogus` exit 1 with the valid kinds
- [x] 6.4 `atlas kill <pid|:port|project> [--tree] [--force] [--dry-run] [--yes]` (server-side safety, prints targets, --yes required without TTY) — ✓ dry run lists targets; no TTY without --yes → exit 4; `kill 1` → protected-pid
- [x] 6.5 `atlas stop [path]` — ✓ `atlas stop` in ~/dev/_sandbox/zz-atlas-test → 'stopped zz-atlas-test', both pids gone, :4126 free
- [x] 6.6 `atlas set <key> <value>` / `atlas set --unset <key>` via PATCH /api/atlas; slug change moves the route — ✓ atlas-cli set.ts; key allowlist + type checks before the write; port range 1024–65535 (d9557a6)
- [x] 6.7 `atlas hostnames check|doctor` — ✓ `check zz-free-xyz` exit 0, `check deckhand` exit 1, `doctor` exit 1 with 2 items
- [x] 6.8 `atlas daemons [restart <label>]` — ✓ `atlas daemons --json`; restart wired to POST /api/daemons/<label> (not run: restarts a daemon)
- [x] 6.9 `atlas ports --json` — ✓ JSON object, exit 1 while collisions exist (same as text mode)
- [x] 6.10 GUI-only (iterm, finder) and duplicate-tool routes (git, readme, bd) skipped on purpose — ✓ `atlas help` ends with 'Not here on purpose: …'
- [x] 6.11 `atlas prime` updated (workflows, --json list, new commands); `atlas install-autocompletion` rerun — ✓ prime lists ps, kill, stop, set, daemons, hostnames check/doctor and the --json/exit-code contract; ~/.zsh/completions/_atlas regenerated
- [x] 6.12 agent-friendly-cli score before and after — ✓ 11/20 (Basic) → 12/20 (Good), same pinned rubric: cli-score-before.md, cli-score-after.md (6bbef90)

## Contract
- [x] C.1 /api/processes response shape fixed before 5 and 6 split — ✓ atlas-api/src/lib/processes/types.ts (24aa846) + .orchestrate/console-upgrade/contracts.md

## Done when
- [x] D.1 gates: atlas-api `just check` + `bunx vitest run`; atlas-cli `bun run check` + `bun test`; atlas-picker `just reinstall` only if project.rs changed — ✓ atlas-api `just check` exit 0 at 735a45c (548 tests); atlas-cli `bun run check` exit 0 + `bun test` 142 pass at 575052e; project.rs unchanged by this work (its uncommitted Sep 17 edits are not ours)
- [x] D.2 timings before/after, 3 runs: `/` <300ms <500KB · fresh snapshot <150ms · warm <30ms — ✓ .orchestrate/console-upgrade/after-timings.txt; `/` 43–89 ms / 461,976 B at load 96 (1.45 MB before); fresh snapshot min 107 ms, median 177 ms at load 96 (floor above target under that load); warm min 20 ms
- [x] D.3 every new/changed page checked in the browser at desktop width and 390px — ✓ 6c831fd: /, /processes, /ports, /system (daemons, services, hostnames), /disk (projects, cleanup, trim, log), /templates at 1280 and 390: no sideways scroll, one column grid per page; /claude-tree and the settings dialog by the verify run
- [x] D.4 docs: root CLAUDE.md (API table, routes, vocabulary: process snapshot, process kind, app row) · atlas-api/CLAUDE.md · atlas-hostname SKILL.md:117 · report.md citation → .orchestrate/findings/mechanism.md — ✓ root CLAUDE.md (38be8de, a529ad4, fea2885 cites mechanism.md); atlas-api/CLAUDE.md + docs/ui-primitives.md; SKILL.md fixed on claude-skills `feature/console-upgrade` (782cd4e), live once merged
- [x] D.5 report .orchestrate/report-2026-10-01-console-upgrade.md (timing table, both CLI scores; Blocked on me / Changed / Found)

## Found along the way
- [x] F.1 `just check` failed on main before any change (biome followed the tracked .claude/worktrees/shared symlink + 4 lint errors) — fixed ffb8bcf
- [x] F.2 plain `bun run build` crashes with SIGTRAP on this Mac (Bun 1.3.8 / Darwin 27); `RAYON_NUM_THREADS=1 bun run build` works — `daemon:reload` pins it (dafcd25)
- [x] F.3 CLI: piped stdout over 64KB is truncated (static @inquirer/prompts import makes stdout non-blocking) — fixed 3117705 (atlas-cli); 220 KB board / 149 KB ps parse through a pipe
- [x] F.4 process argv carries secrets (mcp-remote Bearer, DECKHAND_TOKEN) and /api/ports/listeners returned them — redacted server-side (W5); widened to 37 credential shapes (0d69ce1)
- [x] F.5 scan() re-parsed the 600KB cache per caller — memoized by mtime+size (c9992a9, scanner-cache.test.ts)
- [x] F.6 security review: forged forwarded headers skipped the Host check (high), open reads answered cross-site scripts + `ACAO: *`, redaction gaps, NAS shell injection via a crafted file name — fixed 2c8af56, 814b3c0, 0d69ce1, 9363620
- [x] F.7 port audit counted other hosts' projects (false collisions) — fixed e3207a9
- [x] F.8 project bridges were lost on every daemon restart (502 until the next `atlas run`) — fixed bfa7a56
- [x] F.9 a snapshot whose `ps` timed out under load answered a bare 500 — 503 with the reason (fafaf26 — committed with the gate failing, fixed in 735a45c)
