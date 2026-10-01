# Console upgrade — report, 2026-10-01

All six workstreams were built in one session on `feature/console-upgrade`:

| Repo | Commits | Diff |
|---|---|---|
| atlas-api | 122 | 203 files, +14,982 / −5,630 |
| atlas-cli | 20 | 34 files, +1,576 / −105 |
| project-atlas | 9 | docs and evidence |
| claude-skills | 1 | — |

Nothing is pushed and nothing is merged into main. The live daemon serves atlas-api 735a45c.

- Checklist, with evidence on every line: `.orchestrate/console-upgrade-tasks.md`.
- Independent verification run: 5 agents covering browser at desktop and 390px, curl, code audit and a security review. It confirmed 69 of 76 lines as done. Its 16 UI defects and 4 actionable security findings were fixed afterwards, and every page was rechecked at 1280px and 390px.

## Timings

Method: the same as `baseline-timings.txt` — `curl time_total size_download` against the daemon build, 3 runs.

- Before: main @ 833c883.
- After: two samples, at load 96 and at load 112. Other sessions on this Mac kept the load average between 30 and 210 all day, so the after numbers are noisy.

Raw data: `console-upgrade/baseline-timings.txt` and `console-upgrade/after-timings.txt`.

| Measure | Target | Before | After, load 96 | After, load 112 | Met |
|---|---|---|---|---|---|
| `/` time | < 300 ms | 977 · 172 · 210 ms | 89 · 51 · 43 ms | 257 · 1,328 · 598 ms | yes at load 96, not at 112 |
| `/` size | < 500 KB | 1,453,831 B | 461,976 B | 461,976 B | yes |
| `/` through the NAS, zstd | — | not compressed | 59,409 B | 59,410 B | — |
| fresh snapshot `/api/processes?fresh=1` | < 150 ms | did not exist | 241 · 107 · 177 ms | 433 · 661 · 402 ms | min yes, median no |
| warm snapshot `/api/processes` | < 30 ms | did not exist | 71 · 20 · 26 ms | 32 · 56 · 43 ms | min yes, median at load 96 yes |
| `/api/ports/listeners?fresh=1` | — | 282 · 244 · 236 ms | 1,016 · 351 · 5,374 ms | 667 · 358 · 579 ms | — |
| `/api/ports/listeners` warm | — | 22 · 21 · 11 ms | 564 · 23 · 19 ms | 33 · 25 · 28 ms | — |
| `/ports` | — | 12 ms · 8,949 B | 30 ms · 63,299 B | 56 ms · 59,813 B | — |
| `/processes` | — | did not exist | 42 ms · 215,311 B | 53 ms · 197,747 B | — |
| `/system` | — | 805 ms | 152 ms | 121 ms | — |
| `/disk` | — | 365 ms | 680 ms | 383 ms | — |
| `/templates` | — | 80 ms | 335 ms | 384 ms | — |
| `/claude-tree` (shell) | — | 20 ms | 30 ms | 23 ms | — |

Notes on the table:

- **Snapshot floor.** The fresh snapshot misses 150 ms at the median under this load. Measured earlier the same day, a standalone build took 125–214 ms and the raw `ps` call 40–50 ms. The rest is netstat, launchctl and sysctl, which run in parallel with `ps`, plus `lsof` for processes not seen before.
- **The 5,374 ms run.** `ps` passed its 5 s timeout and the route answered a bare 500. It now answers 503 with the reason (fafaf26, 735a45c).
- **`/ports`.** It grew because the data now arrives in the first paint instead of from a client fetch.
- **`/system`, `/disk`, `/templates`.** `/system` got faster. `/disk` still spawns `atlas disk` 7 times. Why `/templates` slowed down was not investigated.

## CLI score (agent-friendly-cli, rubric pinned at cc41107)

| | Score | Line ticks | Band |
|---|---|---|---|
| Before, main | 11/20 | 17/30 | Basic |
| After, atlas-cli 575052e | **12/20** | 18/30 | Good |

The score would be 13/20 if `--json` on every command counted as the machine format. The scorer gave that line ½ because JSON is the only format.

What moved:

- the agent contract: `prime` now lists every command, with the `--json` and exit-code contract;
- error text: the API's own message reaches the user;
- safety: `set` validates before writing, and `kill` does a server-side dry run and needs `--yes` without a terminal;
- the pipe-truncation fix: piped output is no longer cut at 64 KB.

Top gaps left:

1. no automatic JSON when stdout is not a terminal;
2. `.atlas` writes are not atomic;
3. `--help` is one line for 12 commands;
4. errors are prose, with no code and no retryable flag.

Files: `console-upgrade/cli-score-before.md`, `console-upgrade/cli-score-after.md`.

## Blocked on me

1. **Dev password hash in a public repo's history.** `atlas-api/launchd/com.jurrejan.atlas-api.plist` holds the bcrypt hash of the shared dev password (`CADDY_DEV_AUTH_HASH`). It was committed in 8eb9b65 on local main and is not on GitHub yet; the repo is public. Before the first push, either:
   - move the value to onenv (a plist wrapper) and rewrite the unpushed history, or
   - rotate the password.

   Until then, do not push atlas-api main.
2. **Review and merge `feature/console-upgrade` in four repos:**
   - atlas-api;
   - atlas-cli;
   - project-atlas;
   - claude-skills (782cd4e). The live atlas-hostname skill keeps its outdated "Nothing cleans it up" line until this merges.

   Several intermediate merge commits from the parallel build do not build on their own, and fafaf26 fails `just check`; it is fixed in 735a45c. I did not rewrite history.
3. **Legacy NAS file `multi-stack-framelink-homepage-dev.caddy`.** The hostname doctor lists it and offers no fix. Delete it, or keep it?
4. **The `ports` service** in `shared/services.json` is down, because Active Ports was folded into `/ports`. Remove the entry? Changes to `services.json` beyond the two decisions are yours to make.
5. **What the off-LAN read-only tier shows.** It sits behind the same password as every dev preview and shows process lists (redacted), agent-log handoff text, disk job arguments, the daemon list and the hostname doctor (one ssh per call). Options:
   - keep it as is;
   - switch to a short allowlist of routes;
   - give the console its own credential.

Left as I found them: uncommitted changes that are not mine — the atlas-api plist's PATH line, project-atlas `shared/daemons.json`, and atlas-picker `project.rs`/`ui.rs` (from Sep 17).

Delete when you are happy:

- `~/dev/.atlas-hostnames.json.20261001-pre-migration` (the registry backup taken before the path migration);
- the W34 clean-up folders in `~/.Trash`.

## Changed

### 1. Console

One way of building every page:

- `$lib/http`, `errorMessage` and `tildify`;
- ConfirmDialog, Notice, toast and PageState;
- `Table`, with a sticky header, sort, `Selection` (Finder rules) and roving focus;
- `SideNav` on `/system` and `/disk`.

Page changes:

- `claude-tree/+page.svelte` went from 1,569 to 305 lines, split into components and tested modules.
- `/ports` was split by concern.
- The loc check covers every `.svelte` and `src/lib` `.ts` file; `scanner.ts` is listed as exempt debt.
- Tables span the full page. Every column has a fixed width, so sibling tables share one grid and polling never shifts a column.
- `/processes` filters always show what is active, with a single "Clear filters" action.

Contract: `atlas-api/docs/ui-primitives.md`.

### 2. Guard

`hooks.server.ts` calls `guard.ts` on every request:

- **Host first**, before the forwarded headers.
- **LAN:** the console hostnames work with a matching `Origin`.
- **Off-LAN:** `atlas.atlas.remote.jurrejan.com`, behind the Caddy password, is read-only.
- **Local-only routes:** env files, agent files, claude-tree, port allocation, process logs, iTerm and Finder.
- **Open reads:** another site's scripts are refused; link navigation still works.

The catalog no longer sends `Access-Control-Allow-Origin: *`. The console is served compressed (zstd) through the NAS.

### 3. Hostnames

- `moveRoute`; rename and move keep the route.
- A slug clash answers 409 naming the holder.
- Every slug write is checked as a DNS label.
- Unsynced rows are kept, with a retry.
- Paths are normalised, and a one-time migration did that for the existing registry.
- The remote half is reported unavailable when the auth hash is missing.
- Status polling: syncing → issuing → live.
- Doctor in the CLI and on `/system`.
- Loopback-only dev servers are reached through a NAS-only bridge, which every sync now restores after a daemon restart.
- DNS-01 wildcard certificates on the NAS (decision 2).

### 4. Hostname editing in the console

The settings dialog has a Hostname section:

- slug field with a live preview of both URLs and inline check;
- devPublic toggle that says what it does;
- status pill;
- copy, open and release;
- port field (1024–65535) that says what listens there.

Project rows carry a hostname chip.

### 5. Processes

The process snapshot runs one `ps`, netstat, launchctl and sysctl in parallel, with `lsof` only for new processes and a 2 s cache.

- A classifier gives every process a kind.
- Processes are attributed to projects.
- App rows fold wrapper chains, with flags and sparklines.
- `/processes` is new, and `/ports` was rebuilt on the snapshot.
- Stopping is safe on the server for every caller.
- Keyboard shortcuts and URL state on both pages.
- Agent session names come only from `CLD_SESSION_NAME`.
- Commands are redacted on the server: 37 credential shapes are covered.

### 6. CLI

- `--json` on every data command.
- API errors go to stderr with exit 1.
- New commands: `ps`, `kill`, `stop`, `set`, `hostnames check|doctor` and `daemons`.
- `prime` and completion were rebuilt from the command list.
- Fix: piped stdout was cut off at 64 KB.

### Docs

- Root `CLAUDE.md`: vocabulary for the write guard, process snapshot, process kind and app row; the API table; the console routes; a citation of `findings/mechanism.md`.
- `atlas-api/CLAUDE.md`.
- `atlas-cli/CLAUDE.md`.
- The atlas-hostname skill, on its branch.

## Found

- **The LAN hostnames resolve to the WAN IP.** `*.atlas.local.jurrejan.com` and `atlas.jurrejan.com` resolve publicly to the WAN IP and work from the LAN only through the router's hairpin NAT. There is no 403 today. Split-horizon DNS is not an option, because the router filters private-IP DNS answers. If the hairpin ever breaks, the LAN console breaks with it.
- **Security review, now fixed:**
  - High: forged `X-Forwarded-*` headers skipped the Host check, so a DNS-rebinding page could read env files and any file under `~/dev`.
  - Medium: open reads answered other sites' scripts, and `/api/projects` sent `ACAO: *`.
  - Medium: 17 of 27 common credential argv shapes leaked through redaction.
  - Low: a crafted NAS file name could inject into the doctor's `rm`.
- **Security, still open:**
  - The `services.json` `host` field is interpolated into the NAS heredoc without validation. Hand-curated, so low.
  - `-p<password>` is masked only after `mysql`/`mariadb`.
  - A raw `POST /api/processes/stop` will stop an agent session; only the CLI's `kill <project>` skips those.
- **Bugs fixed along the way:**
  - The port audit counted twins on fractal and ubuntu as collisions: 5 claimed ports, really 2.
  - Every daemon restart dropped the project bridges, so hostnames answered 502 until the next `atlas run`.
  - `just check` was already failing on main.
  - `bun run build` crashes with SIGTRAP on Bun 1.3.8 / Darwin 27; `daemon:reload` now sets `RAYON_NUM_THREADS=1`.
  - `scan()` re-parsed the 600 KB cache for every caller.
- **"live" means only that TLS answers.** It does not mean the upstream answers. A stopped server reads live and returns 502.
- **claude-tree is slow cold.** A cold load took 19–33 s (4.1 MB, 2,035 nodes) and each find 18–30 s, at load 34–48. Its initial view lands far from the root node. Some CodeMirror lines render at double height.
- **Machine load.** Load from other sessions (Playwright Chromium and others) made every timing noisy. A stray `python http.server` on :8971, from another session's `/private/tmp/room-vault`, was left alone.
