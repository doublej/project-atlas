# atlas CLI: agent-friendly score AFTER (workstream 6)

Date 2026-10-01. Read-only audit, same method as `cli-score-before.md`. No code was changed.

## What was scored

- CLI: `atlas-cli` at HEAD `575052e` on `feature/console-upgrade`, with a clean worktree. The global `atlas` is `~/.bun/bin/atlas`. It points to `../install/global/node_modules/atlas-cli/src/atlas.ts`, which resolves to `atlas-cli/src/atlas.ts`, so HEAD is the code that ran.
- How it ran: from a scripted Bash, with stdout and stderr not a TTY and stdin set to `/dev/null`: `/Users/jurrejan/.bun/bin/atlas <cmd> > out 2> err < /dev/null; echo EXIT=$?`. The zsh wrapper was skipped. atlas-api on :47891 was up (`/api/health` 200), so `requireUp()` never ran a kickstart.
- Side effects of the audit: none on any project. Specifically:
  - No `scan`, `run`, `set`, `stop`, `hostnames assign`, `--fix`, `sync` or `restart` reached the API. `scan --json` and `run --json` were scored from their code.
  - The only process that was signalled was the auditor's own `sleep` (pid 86360), killed with a plain `kill`. `atlas kill` ran only as a dry run, or as a refusal without `--yes`.
  - `stop /tmp`, `set bogus 1`, `set port 80` and `set port abc` all exit before any API write: `set` validates before `requireUp()`, and `stop` dies on "No scanned project".

## Rubric version (verified unchanged)

- Skill commit: `cc41107` (2026-10-01 00:24:40 +0200), the same as the pinned one. `~/.claude/skills/agent-friendly-cli` resolves to `~/dev/_management/claude-skills/agent-friendly-cli`.
- sha256, recomputed today. All three match the pinned values:
  - `references/evaluation-rubric.md`: `9c93f9ef4fad4709ed540e9762fd6b4847318c0db1969dc2ea05403095000b2d` ✓
  - `references/focus-areas.md`: `ee0feaa34e4c401b1d8a5679b5331bc04e7c69b324fb0e3a36c716fa440ae6b1` ✓
  - `SKILL.md`: `faee9a880cd546252346dad12b0313c1eb7396e931f74eda4e0b41995e89213c` ✓
- Tick rule, unchanged:
  - Each line scores 1 (met), 0.5 (half met) or 0 (not met).
  - Area score = round(sum / 3 × 2). A sum of 1 gives 1, a sum of 2 gives 1, and a sum of 2.5 gives 2.
  - The finer total is the sum of the line ticks, out of 30.
- The before audit's own reading is kept: a line counts as met when its main parts hold, even with small leaks (as for area 1 line 2 and area 8 line 2 in the before score).

## Score

```
AGENT FRIENDLY CLI  ──  atlas (atlas-cli 575052e)   mode: audit   score: 12/20  (line ticks 18/30)

AREA                      BEFORE  AFTER   PRI   GAP
──────────────────────────────────────────────────────────────────────
Output & formatting       1       1       1     no auto-JSON on pipe; json is the only machine format
Token economy             1       1       5     search 456 rows/35KB, ports 177 unmanaged rows uncapped; no --fields/--view
Input ergonomics          2       2       7     no @1/@last refs
Defaults & config         1       1       8     bare `atlas` = 3.2KB help dump with logo; no user shortcuts
Discoverability & help    1       1       9     12 of 27 commands answer --help with one line; no examples block
Errors & feedback         1       1       4     prose only, no code/category/retryable; --json errors not JSON
Agent contract (prime)    1       2       3     no per-command flags or output shapes in the primer
Safety & writes           1       1       2     .atlas writes still writeFile (not atomic, no rollback); no write marking in help
Round-trip reduction      1       1       6     no per-command --refresh; info/search/ps always call the API
Automation & interop      1       1       10    no stdin `-`, no query escape hatch, nothing reads ids from stdin
```

Rating: **Good, 12/20** (it was Basic, 11/20). The line ticks went from 17 to 18 out of 30.

| # | Area | Line ticks before | Line ticks after | Area before → after |
|---|---|---|---|---|
| 1 | Output & formatting | ½ + 1 + ½ = 2 | ½ + 1 + ½ = 2 | 1 → 1 |
| 2 | Token economy | ½ + 0 + ½ = 1 | ½ + 0 + ½ = 1 | 1 → 1 |
| 3 | Input ergonomics | 1 + 1 + ½ = 2.5 | 1 + 1 + ½ = 2.5 | 2 → 2 |
| 4 | Defaults & config | 0 + 1 + ½ = 1.5 | 0 + 1 + ½ = 1.5 | 1 → 1 |
| 5 | Discoverability & help | ½ + ½ + ½ = 1.5 | ½ + ½ + ½ = 1.5 | 1 → 1 |
| 6 | Errors & feedback | ½ + 0 + ½ = 1 | ½ + 0 + **1** = 1.5 | 1 → 1 |
| 7 | Agent contract (prime) | ½ + ½ + 1 = 2 | ½ + **1** + 1 = 2.5 | 1 → **2** |
| 8 | Safety & writes | ½ + 1 + ½ = 2 | ½ + 1 + ½ = 2 | 1 → 1 |
| 9 | Round-trip reduction | ½ + ½ + 1 = 2 | ½ + ½ + 1 = 2 | 1 → 1 |
| 10 | Automation & interop | 1 + 0 + ½ = 1.5 | 1 + 0 + ½ = 1.5 | 1 → 1 |
| | **Total** | **17/30** | **18/30** | **11 → 12/20** |

### The two judgement calls that move the total
- **Area 1, line 3** ("dense tables; multiple machine formats (json/jsonl/tsv/csv)") stays at ½.
  - `--json` now works on every data command, but JSON is still the only machine format. Read strictly, the "multiple formats" half is not met.
  - If JSON on every command were counted as met, area 1 would become 2, for **13/20 (18.5/30)**. The before proposal predicted this. It is not taken here, because the rubric text names jsonl/tsv/csv.
- **Area 6, line 3** rises to 1, because its three parts now hold: valid options on failure, a documented exit-code table, and fail-fast without a TTY. Small leaks remain and are listed below.
  - If it were held at ½, the line total would be 17.5/30 and the area score would stay 1, so the 12/20 total does not change.

### Why many fixes do not show in the numbers
A line can only score 0, ½ or 1. The lines below each had two problems in the before audit. One of the two is now fixed, so they stay at ½:
- A1 L3: JSON coverage is fixed; there is still only one machine format.
- A2 L1 and L3: `ps` gained a footer and cuts long commands; `search`, `ports` and `flow audit` are still uncapped.
- A5 L2: the help for `new`, `flow`, `tree` and the new commands is fixed; 12 commands still print one line.
- A5 L3: `prime` now builds its command list from `COMMANDS`; subcommand completion is still hard-coded, and only for `tree`.
- A6 L1: the API's error body now reaches the user; errors are still prose.
- A8 L1: checks now run before every write; `.atlas` writes are still not atomic.
- A10 L3: `search --json` carries the absolute path that `info` takes; still no command reads ids from stdin.

## Evidence per criterion

### 1. Output & formatting: 1 (½ + 1 + ½), unchanged
- **Line: auto-JSON on pipe and colour off without a TTY: ½.**
  - Auto-JSON on pipe: not met. `atlas info | head -3` printed text (`project-atlas  —  multi-stack/project-atlas`).
  - Colour: met.
    - `grep -l $'\x1b'` over every captured stdout and stderr in this audit (33 JSON runs, 31 error probes, `board` text, `new < /dev/null`, `prime`) found 0 files. The control file `ctrl.ansi` was found, so the grep works.
    - The before audit's one exception is gone: `atlas new < /dev/null` no longer draws an inquirer prompt.
    - In the source, `grep -rnE 'x1b|u001b|\\033|NO_COLOR|chalk|picocolors' src` (tests excluded) hits only `fake-api.ts:71`, a test helper that strips ANSI.
- **Line: raw scalar; stdout = data, stderr = diagnostics: 1.**
  - `hostnames check 'Bad_Slug!'` prints the bare scalar `invalid: slug may only hold a-z, 0-9 and -`.
  - `kill` sends its preview to stderr when it acts, and to stdout only under `--dry-run`, where the preview is the data. Its refusal goes to stderr.
  - Leak: `disk bogus` still prints its help on stdout with exit 1.
- **Line: dense tables and multiple formats: ½.**
  - Tables are padded columns with no box drawing (`ps`, `daemons`, `hostnames`, `search`).
  - `--json` was checked on 33 read invocations, and every one parsed. Each printed a single line except `info`, `prime` and `disk`, which print indented JSON, as `prime` says they do:

    `info`, `search`, `atlas <q>`, `ports`, `ps`, `ps --all`, `daemons`, `hostnames [list]`, `hostnames check`, `hostnames doctor`, `services [list]`, `hosts [list]`, `templates [list]`, `templates lint`, `flow [status]`, `flow audit`, `tree view|search|compose`, `brief`, `board [read]`, `agent-log recent|status`, `disk archives|log|doctor`, `prime`.
  - `scan --json` (`{projects, frameworks}` counts) and `run --json` were confirmed in `scan.ts` and `run.ts:58`. They were not run, because both write.
  - No jsonl, tsv or csv: `grep -rnE -- "--fields|--view|jsonl|--format|tsv|csv"` finds only git/tar format strings and board's file name. As a control, the `--json` pattern finds 27 places.
- **Before bug fixed: piped output over 64 KB.**
  - `atlas board --limit 400 --json | bun -e JSON.parse` → VALID, 220105 bytes, 400 posts. In the before audit this was INVALID at 65527 bytes.
  - `atlas ps --all --json | …` → VALID, 149106 bytes, 635 rows.
  - The fix is `3117705`, which loads the `new` prompts lazily.

### 2. Token economy: 1 (½ + 0 + ½), unchanged
- **Line: default limits and a truncation notice: ½.**
  - New: `ps` shows dev rows by default with the footer `29 shown · 596 hidden (--all)`.
  - Kept: board shows 15 posts by default, and `info` caps its lists at 8.
  - Still uncapped, with no notice:
    - `atlas search a`: 456 lines, 35222 bytes (89 KB with `--json`).
    - `ports`: 185 lines, 177 of them in the unmanaged list.
    - `flow audit`: 234 lines.
- **Line: `--fields` and `--view`: 0.** Neither exists (same grep as area 1).
- **Line: per-column truncation and noise off by default: ½.**
  - New: `ps` cuts COMMAND to the terminal width, or 80 columns when piped (`node /Users/jurreja…`). `kill` previews cut commands at 80. `ps --json` rows carry no raw command.
  - Not met: `ports` still lists all 177 unmanaged rows by default, and search paths are never truncated.

### 3. Input ergonomics: 2 (1 + 1 + ½), unchanged
- **Line: bare-arg intent routing: 1.** `atlas atlas --json` prints exactly what `atlas search atlas --json` prints (356 bytes, 2 rows). `[path]` defaults to cwd. `flow` now also finds the owning project from a subfolder: run from `atlas-cli/`, it exited 0 and showed `project-atlas (trunk)`.
- **Line: fuzzy matching and aliases: 1.** Unchanged, plus a new target shorthand: `kill <pid | :port | project>`. `kill :59997 --dry-run` exits 2 with "Nothing matches :59997. See: atlas ps --all".
- **Line: stable IDs and @refs: ½.**
  - New stable ids: `ps` row ids `pgid@startTime`, and `kill` checks pid plus start time.
  - Still missing: `@1` and `@last`. `grep '@last'` finds nothing; as a control, the `'@'` pattern finds the disk version-id code.

### 4. Defaults & config: 1 (0 + 1 + ½), unchanged
- **Line: useful no-arg action: 0.** Bare `atlas` exits 0 with a 3173-byte help dump that includes the ASCII logo (it was 2225 bytes).
- **Line: zero-config and persistent defaults: 1.** Unchanged.
- **Line: flags override config; user shortcuts: ½.** Unchanged: there are no user-defined aliases.

### 5. Discoverability & help: 1 (½ + ½ + ½), unchanged
- **Line: every command described; examples: ½.**
  - All 27 commands have a one-line summary.
  - New footer: "`atlas <command> --help` for flags. `--json` on every command that prints data, except the text-only ones `atlas prime` lists."
  - Top-level help still has no examples block. The examples live in `prime`'s workflows.
- **Line: argument meanings shown inline: ½.**
  - Fixed: `new` (11 lines), `flow` (10) and `tree` (11) now print their full usage.
  - The new commands have full usage: `ps` 9 lines, `kill` 15 with an exit table, `set` 9 with value types, `stop`, `daemons` 4, `info`.
  - Still one line: `--help` was run on all 27 commands, and 12 print only `atlas <cmd> — <summary>`: `init`, `scan`, `open`, `run`, `pick`, `jump`, `search`, `ports`, `templates`, `hosts`, `brief` and `install-autocompletion`.
    - So `search --help`, `ports --help`, `templates --help`, `hosts --help`, `run --help`, `scan --help` and `brief --help` never mention `--json`. `hosts --help` doesn't mention `sync` or `scan`, and `templates --help` doesn't mention `lint`.
- **Line: completion generated from one model: ½.**
  - Better: `prime.ts:74` now builds its Commands section from `COMMANDS`, so help, completion and the primer share one command list. The installed `~/.zsh/completions/_atlas` was regenerated and includes `set`, `stop`, `ps`, `kill` and `daemons`.
  - Still missing:
    - Subcommands are hard-coded for `tree` only (`install-autocompletion.ts:32`). `hostnames`, `daemons`, `disk`, `flow`, `hosts` and `services` get no subcommand completion.
    - No flags are completed.

### 6. Errors & feedback: 1 (½ + 0 + 1), was 1 (½ + 0 + ½)
- **Line: structured errors: ½.**
  - Fixed: the API's own error text now reaches the user (`api.ts` `errorText`).
    - `tree view /tmp` prints "path is outside the project catalog", where it used to print `→ 400 Bad Request`.
    - A non-JSON body falls back to the status line (`80c5a11`).
  - Hints stay inline ("Run: atlas scan", "See: atlas ps --all", "rerun with --yes").
  - Still prose: in `--json` mode an error is not JSON. `daemons restart nope --json` and `search zzqqxxnomatch --json` print 0 bytes on stdout and one prose line on stderr. Only `disk --json` gives `{command, exit, error}`.
- **Line: categories and a retryable flag: 0.** Neither exists.
- **Line: valid options, exit codes, fail-fast without a TTY: 1.**
  - Valid options on failure:
    - `daemons restart nope` lists every label.
    - `hosts sync nope` gives "Known: fractal, ubuntu".
    - `set bogus 1` lists the 12 keys.
    - `ps --kind` lists the kinds.
    - `set port 80` gives "port takes an integer port 1024–65535".
  - Exit codes, now one documented table:
    - `kill`: dry-run on own pid → 0; `:59997` → 2 (nothing matched); `kill 1 --dry-run` → 4 (refused: protected-pid); no TTY and no `--yes` → 4.
    - `hostnames check` taken or invalid → 1, and `hostnames doctor` with drift left → 1.
  - Fail fast without a TTY:
    - `atlas new < /dev/null` now exits 1 with the non-interactive form. Before, it exited 0 after drawing a prompt.
    - `kill` refuses with 4 and says to "rerun with --yes".
    - disk refuses with its reason.
  - Small leaks that remain:
    - `atlas --version` exits 1 with `Unknown flag "--version". Usage: atlas jump …`, which names the wrong command.
    - `tree bogus` prints help with exit 0.
    - Extra args and unknown flags are silently ignored by `hostnames list extra` (exit 0), `info --bogus` (0), `ports --bogus` and `brief --bogus` (0).
    - `board --bogus` prints "board: undefined needs a value".
    - `agent-log bogus` exits **2**, but `prime`'s table defines 2 as "nothing to do".
    - `jump` without a TTY still blames the install ("Device not configured … `just reinstall`").

### 7. Agent contract (`prime`): 2 (½ + 1 + 1), was 1 (½ + ½ + 1)
- **Line: one-shot primer with commands, flags, output shapes and error codes: ½.**
  - Commands: the new `## Commands` section lists all 27, built from `COMMANDS`. Error codes: the exit table `0 · 1 · 2 · 3 · 4`.
  - Flags: missing. "`atlas <command> --help` for flags" sends the agent to `--help`, which is one line for 12 commands (area 5).
  - Output shapes: only the general rule (one JSON document, single-line JSON), plus inline hints such as `hostnames check  # free · current · taken by … · invalid: …`. There is no per-command schema.
  - Size: Markdown 6154 bytes, `--json` 8232 bytes.
- **Line: Markdown by default, output contract: 1.**
  - Piped `prime` prints Markdown. `--json` gives the same model with the keys `name, version, purpose, commands, workflows, guardrails, output, detected`; `commands` is new.
  - The output contract is now accurate on the points the before audit found stale:
    - `--json` on every data command, single-line except `info`, `prime` and `disk`. Verified on all 33 runs.
    - The list of text-only commands.
    - disk `--json` errors go to stdout.
    - Exit codes 2, 3 and 4 for `disk` and `kill`.
  - Small inaccuracy: `agent-log` uses exit 2 for a usage error.
- **Line: detected block, workflows, guardrails: 1.**
  - Detected: cwd, API up, and the catalog (621 projects, with scan time).
  - 12 workflows; Processes, Project settings, Hostnames and Daemons are new.
  - 8 guardrails, including `kill` dry-run first and `--yes` without a TTY, `set slug` moving the hostname, and never restarting atlas-api.

### 8. Safety & writes: 1 (½ + 1 + ½), unchanged
- **Line: atomic writes; validate before commit: ½.**
  - Validate before commit is now fully met:
    - `set` checks the key against an allowlist and each value against its type before any API call (`set.ts`: `die` comes before `requireUp`).
    - `PATCH /api/atlas` runs `patchProblem` (DNS-label slug, port range) and `assertPatchFree` (a 409 on a slug clash) "before anything is written".
    - `kill` gets a server dry run and checks pid plus start time.
  - Atomic is still not met:
    - `atlasFile.ts:36` `patchAtlas` uses `writeFile` with no temp file and rename. `flow.ts:54` and `init.ts:21` use `Bun.write`.
    - A failed `rerouteProject` after `patchAtlas` leaves the new `.atlas` in place, with no rollback.
    - Only the hostname registry is atomic (`hostnames/registry.ts:82-84`, temp file then `rename`).
- **Line: guarded and idempotent writes, `--dry-run`: 1.**
  - New: `kill --dry-run` (server-side, refusals included), `--yes` required without a TTY, and `hostnames doctor` without `--fix` as a preview.
  - `daemons restart atlas-api` is refused on the client ("self-managed: never restart it from here").
- **Line: secrets; read/write separation: ½.**
  - Secrets: met. `ps --json` rows carry no `command` field. The server's process list is redacted (`redact()`): in the full list of 784 processes, a scan for credential patterns found only 4 false positives (`1Password --g…`, `--s…` flags), with values masked in the check.
  - Read/write separation: still not explicit. `atlas help` has no read or write marker. `hostnames`, `hosts`, `services`, `flow` and `daemons` mix reads and writes in one row. Only `prime`'s guardrails and the text-only list hint at which commands write.

### 9. Round-trip reduction: 1 (½ + ½ + 1), unchanged
- **Line: query-shape cache and `--refresh`: ½.** No CLI flag: `grep "'--refresh'|'--fresh'|--no-cache"` finds nothing, while the control `fresh=1` matches `kill.ts:83`. `kill` alone forces a fresh snapshot.
- **Line: read-only commands avoid the backend: ½.**
  - `prime` and `brief` read local files.
  - `info`, `search`, `ps`, `daemons`, `hostnames` and `flow` call the API on every run.
- **Line: health probe, graceful degradation: 1.** Unchanged: `run` returns `bound` and `lanReachable` (and `575052e` prints the hostname of a server bound to loopback only), and `requireUp()` heals the daemon.

### 10. Automation & interop: 1 (1 + 0 + ½), unchanged
- **Line: inject-and-exec: 1.** Unchanged: `agent-log run`/`guard` and `jump --run`.
- **Line: query escape hatch and stdin `-`: 0.**
  - No query mode exists.
  - No `-` argument: `grep "=== '-'"` finds nothing. The only stdin reads are hook JSON in `agent-log.ts:69,85`; the control `Bun.stdin` pattern matches those two lines.
- **Line: pipe-through, session lifecycle: ½.**
  - Session lifecycle is automatic.
  - Better: `search --json` now carries the absolute `path`, and `info <that path> --json` exits 0. `ps --json` ids and pids feed `kill`.
  - Not met:
    - Text `search` still prints `relativePath`. `atlas info multi-stack/project-atlas` run from `/tmp` exits 1.
    - No command reads ids or paths from stdin, so every loop needs `jq` plus `xargs`.

## Before findings: status
| # | Before finding | Now |
|---|---|---|
| 1 | Piped stdout cut at 64 KB | **Fixed**: 220 KB board and 149 KB `ps --all` parse through a pipe |
| 2 | `new`/`flow`/`tree --help` print one line | **Fixed** for those three; 12 other commands still print one line |
| 3 | `flow` matches the project path exactly | **Fixed**: works from `atlas-cli/` |
| 4 | `atlas new` without a TTY prompts and exits 0 | **Fixed**: exit 1 with the non-interactive form |
| 5 | `brief --json` prints nothing outside a project | **Fixed**: prints `null`; text mode stays silent |
| 6 | API `{error}` body lost | **Fixed**: the server's own message, with a fallback to the status line |
| — | `--json` on 6 of 22 commands | **Fixed**: every data command (33 runs checked) |
| — | `prime` output contract stale | **Fixed**, apart from agent-log's exit 2 |

## Top remaining gaps (in rubric priority order)
1. **Output (A1, priority 1):** no auto-JSON when stdout is not a TTY; JSON is the only machine format (no jsonl for `ps --all` or `search`). Auto-JSON on pipe is the single biggest gain left.
2. **Safety (A8, priority 2):** make `patchAtlas`, `flow.ts:writeAtlasFlow` and `init` write through a temp file and `rename` (the pattern `hostnames/registry.ts` already uses), and roll back `.atlas` if `rerouteProject` fails. Mark the commands that write in `atlas help`.
3. **Contract and help (A7 L1 and A5 L2, priorities 3 and 9):** give `usage` to the 12 commands that print one line, `search`, `ports`, `templates`, `hosts`, `run`, `scan` and `brief` first, and render flags into `prime` from those usages.
4. **Errors (A6, priority 4):** a JSON error object `{code, message, hint, retryable}` on stdout when `--json` is set; fix `--version`, `tree bogus` exiting 0, unknown flags being ignored on `info`/`ports`/`brief`, and `board --bogus`'s "undefined"; align agent-log's exit 2 with the table.
5. **Token economy (A2, priority 5):** a default `--limit` with "showing N of M" for `search` (456 rows), `ports` (177 unmanaged rows) and `flow audit` (234 lines), plus `--fields`.
6. Later: `@last` refs (A3), a status snapshot instead of help for bare `atlas` (A4), stdin `-` (A10) and `--refresh` (A9).
