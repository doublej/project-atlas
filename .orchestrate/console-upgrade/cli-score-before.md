# atlas CLI: agent-friendly score BEFORE (workstream 6)

Date 2026-10-01. Read-only audit. No code was changed.

## What was scored

- CLI: `atlas-cli` at HEAD `a2deb17` on `feature/console-upgrade`. The global `atlas` is `~/.bun/bin/atlas`, a symlink to `atlas-cli/src/atlas.ts`, so HEAD is the code that ran.
- How it ran: from a scripted Bash with stdout and stderr not a TTY: `/Users/jurrejan/.bun/bin/atlas <cmd> > out 2> err; echo EXIT=$?`. The binary was called directly, skipping the zsh `atlas()` wrapper. atlas-api on :47891 was up.
- Side effects of the audit: `atlas scan --json` ran one `POST /api/refresh`, which only refreshes the cache. A probe with a bad `ATLAS_API` ran one `launchctl kickstart` without `-k`, which does nothing to a daemon that is already running. One `POST /api/daemons/nope` returned 404 and wrote nothing.

## Rubric version (re-run the AFTER score with exactly this)

- Skill `agent-friendly-cli`: `~/.claude/skills/agent-friendly-cli`, which links to `~/dev/_management/claude-skills/agent-friendly-cli`. Repo commit `cc41107` (2026-10-01 00:24 +0200).
- sha256 of `references/evaluation-rubric.md`: `9c93f9ef4fad4709ed540e9762fd6b4847318c0db1969dc2ea05403095000b2d`
- sha256 of `references/focus-areas.md`: `ee0feaa34e4c401b1d8a5679b5331bc04e7c69b324fb0e3a36c716fa440ae6b1`
- sha256 of `SKILL.md`: `faee9a880cd546252346dad12b0313c1eb7396e931f74eda4e0b41995e89213c`
- Criteria: there are 10 areas, each with 3 checklist lines (from `evaluation-rubric.md`). Each area scores 0 to 2. Prime's learnings bonus is not scored.
- Tick rule (pinned here so the AFTER run cannot drift):
  - Score each line as met = 1, half met = 0.5, or not met = 0.
  - Area score = round(sum / 3 × 2), with a sum of 1 rounding to 1, 2 to 1 and 2.5 to 2.
  - The finer number is the total of the line scores out of 30.
- Bands: 0–6 poor, 7–11 basic, 12–15 good, 16–20 excellent.

## Score

```
AGENT FRIENDLY CLI  ──  atlas (atlas-cli a2deb17)   mode: audit   score: 11/20  (line ticks 17/30)

AREA                      SCORE   PRI   GAP
──────────────────────────────────────────────────────────────
Output & formatting       1       1     --json on 6 of 22 commands; unknown --json silently ignored; >64KB piped output truncated
Token economy             1       5     search 446 rows/34KB, ports 185 lines uncapped; no --fields/--view
Input ergonomics          2       7     no @last refs; otherwise strong (bare-arg search, fuzzy, local-first)
Defaults & config         1       8     bare `atlas` = help dump with logo; no user shortcuts
Discoverability & help    1       9     `new/flow/tree --help` print one line though usage text exists; no examples in help
Errors & feedback         1       4     API {error} body lost; prose only; `atlas new` w/o TTY exits 0 doing nothing
Agent contract (prime)    1       3     no command/flag/exit list; output contract stale (omits board/disk --json, disk exits)
Safety & writes           1       2     .atlas writes not atomic; no write marking in help; disk is exemplary
Round-trip reduction      1       6     no per-command --refresh; info/search always hit the API (cached server-side)
Automation & interop      1       10    no stdin `-`, no query escape hatch; agent-log run/guard mirror exit codes
```

Rating: **Basic, 11/20.** It is usable, with friction.

## Evidence per criterion

### 1. Output & formatting: 1 (½ + 1 + ½)
- **Line: auto-JSON on pipe and colour off-TTY: ½.**
  - Auto-JSON on pipe: not met. Piped `atlas info` printed 9 lines of text with exit 0.
  - Colour: atlas's own code emits no ANSI. `grep -rnE 'x1b|u001b|\\033|NO_COLOR|chalk|picocolors' src` found 0 hits. The control grep `x1b|isTTY` found 3 hits, so the grep works.
  - The exception: `atlas new < /dev/null` writes inquirer's ANSI prompt (`\e[34m?\e[39m \e[1mCategory:`) to the piped stdout.
- **Line: raw scalar, stdout = data, stderr = diagnostics: 1.**
  - `run` and `hostnames assign` print the bare URL. `run` warnings, `die()` messages and disk progress go to stderr.
  - Small leaks: `new` prints offline notes on stdout, and `disk bogus` prints its help on stdout with exit 1.
- **Line: dense tables and multiple formats: ½.**
  - Tables are padEnd tables with no box chrome (`templates`, `hosts`, `services`, `search`). The exception is board's BBS banner, which is intentional.
  - `--json` works only on `prime`, `info`, `brief`, `agent-log recent|status`, `board [read]` and `disk *`. There is no jsonl, tsv or csv.
  - How `--json` fails elsewhere:
    - Silently ignored, with text printed: `ports --json` (EXIT=1, text), `tree view --json` (EXIT=0, text), `flow audit --json` (EXIT=0, text), `scan --json` (EXIT=0, "Rescanned — 611 projects, 24 frameworks").
    - Rejected as an unknown subcommand: `hostnames --json`, `services --json` and `hosts --json` each exit 1 with "Usage: …". `templates --json` exits 1 with "Unknown subcommand '--json'".
    - Rejected as a bad flag: `search atlas --json` exits 1 with `Unknown flag "--json". Usage: atlas jump …`, which names the wrong command. `new --json` exits 1 via `node:util` parseArgs strict mode.
- **Bug found:** any piped stdout over 64 KB is cut off, for every command.
  - Repro: `atlas board --limit 400 --json | bun -e 'JSON.parse(...)'` gives "INVALID JSON 65527 … Unterminated string", with exit 0. Redirected to a file, the same output is 220573 bytes.
  - Isolated: `bun -e "console.log('x'.repeat(200000))" | wc -c` gives 200001. The same after `await import('@inquirer/prompts')` gives 65536, and after `await import('./src/registry.ts')` also gives 65536.
  - Cause: `registry.ts` → `commands/new.ts` → `new-prompts.ts` imports `@inquirer/prompts` statically. `disk/report.ts:writeOut` works around it for disk only.
  - Impact: large `--json` output from `ps --all`, `search` or `hostnames doctor` would silently corrupt.

### 2. Token economy: 1 (½ + 0 + ½)
- **Line: default limits and a truncation notice: ½.**
  - Board defaults to 15 posts and prints "407 MESSAGE(S) ON FILE. READING #0393-#0407.". `info` caps its lists at 8 with "+N more".
  - Uncapped output: `atlas search a` gives 446 lines / 34109 bytes, `ports` 185 lines (177 unmanaged), `flow audit` 234 lines. None of these prints a "showing N of M" notice.
- **Line: `--fields` and `--view`: 0.** Neither exists.
- **Line: per-column truncation and noise off by default: ½.**
  - Met in part: compact middot lines in `info`/`brief` (`51 · last today`), list caps in `info`, and archived projects hidden by default.
  - Not met: `ports` dumps all 177 "unmanaged" rows by default, and search paths are never truncated.

### 3. Input ergonomics: 2 (1 + 1 + ½)
- **Line: bare-arg intent routing: 1.**
  - `atlas atlas` routes to search and gives `project-atlas  multi-stack/project-atlas`. `atlas <q> --run <cmd>` routes to jump.
  - `[path]` args default to cwd. `info` resolves the nearest owning project from a subfolder (run from `atlas-cli/` it showed project-atlas).
- **Line: fuzzy matching and aliases: 1.** `rankProjects` ranks local-first, then exact, prefix and path matches, then a folder match. Aliases are `pj` and `-r`/`--cmd` for `--run`.
- **Line: stable IDs and @refs: ½.**
  - Stable IDs that work: project names and slugs, board `#0003`, agent-log op ids, and disk version ids `<category>/<project>@<ts>`.
  - Missing: `@1`/`@last` refs.

### 4. Defaults & config: 1 (0 + 1 + ½)
- **Line: useful no-arg action: 0.** Bare `atlas` exits 0 with a 2225-byte help dump that includes the ASCII logo.
- **Line: zero-config and persistent defaults: 1.** It works with no setup (only an `ATLAS_API` override). Per-project `.atlas` (port, slug), `.atlas-config.json` and the disk settings all shrink later calls.
- **Line: flags override config, user shortcuts: ½.** Flags win over config: `disk/scan.ts:114` uses `f.num('min-size') ?? settings.scanMinMB`. There are no user-defined aliases.

### 5. Discoverability & help: 1 (½ + ½ + ½)
- **Line: every command described, examples: ½.**
  - All 22 commands have a one-line summary in `atlas help`.
  - There is no examples block and no "run `atlas <cmd> --help`" footer. `prime` holds the example workflows instead.
- **Line: argument semantics inline: ½.**
  - Full usage exists for `disk`, `agent-log`, `board`, `hostnames` and `services`.
  - **Bug:** `atlas.ts` handles `--help` before dispatch and prints `cmd.usage ?? summary`. `new` (NEW_USAGE), `flow` (USAGE) and `tree` (HELP) have usage text but no `usage` field, so `atlas new --help`, `atlas flow --help` and `atlas tree --help` each print a single line. `atlas info --help` never mentions `--json`.
- **Line: completion generated from one model: ½.**
  - `install-autocompletion` builds the top-level list from `COMMANDS`. The installed `~/.zsh/completions/_atlas` (2026-09-23) has all 22 commands plus `tree`'s 4 subcommands.
  - Subcommands are hard-coded for `tree` only. `prime`'s `WORKFLOWS` and `OUTPUT` are maintained by hand, separately.

### 6. Errors & feedback: 1 (½ + 0 + ½)
- **Line: structured errors: ½.**
  - Messages carry hints inline: "No scanned project at /tmp. Run: atlas scan", and `hosts sync` lists the known hosts.
  - `disk --json` prints `{command, exit:'error', error}`. Everything else is one prose line on stderr.
  - **API body lost.** `curl /api/atlas?path=/tmp` returns `{"error":"path is not in this machine's catalog"}` (HTTP 400), but `apiGet` throws `GET /api/atlas?path=/tmp → 400 Bad Request`. The cause is `api.ts:26/37/48`, which checks `!r.ok` and never reads the body.
- **Line: error categories and a retryable flag: 0.** Neither exists.
- **Line: valid options, exit codes, fail-fast without a TTY: ½.**
  - Exit codes: disk uses 0/1/2/3/4, `ports` exits 1 on collisions, `templates lint` 1 on errors, `agent-log doctor` 1. Everything else is 0 or 1.
  - Wrong signals:
    - `tree bogus` prints help with exit 0.
    - `atlas --version` exits 1 with `Unknown flag "--version". Usage: atlas jump …`.
    - Extra args are silently ignored: `hostnames list extra` exits 0.
  - Without a TTY:
    - disk refuses with a reason: `approval.ts:81` gives "no terminal; rerun with --unattended".
    - `atlas jump` exits 1 but blames the install: "Device not configured … installed? `just reinstall`".
    - `atlas new < /dev/null` exits 0 after rendering an ANSI prompt. Nothing is created, and it reports success.

### 7. Agent contract (`prime`): 1 (½ + ½ + 1)
- **Line: one-shot primer: ½.**
  - The primer is one call (2381 bytes), but it sends the reader to `atlas help` for commands and `<cmd> --help` for flags. That `--help` is broken for `new`, `flow` and `tree`.
  - It lists no output shapes and no error codes.
- **Line: Markdown default and output contract: ½.**
  - Markdown is the default even when piped, and `--json` gives the same model: keys `name, version, purpose, workflows, guardrails, output, detected`.
  - The OUTPUT contract is stale:
    - It says "`--json` on `info`, `brief` and `agent-log`", leaving out board and disk.
    - It says "Errors: one line on stderr, exit 1", but disk uses exits 2/3/4 and prints `--json` errors on stdout.
    - `WORKFLOWS` covers disk and board, but the contract does not.
- **Line: detected block, workflows, guardrails: 1.**
  - The Detected block holds cwd, API up/down, the owning project and the catalog count/time.
  - It has 8 workflows and 6 guardrails, covering cert cost, `flow init --dry-run`, read-only remote rows and no `kickstart -k`.

### 8. Safety & writes: 1 (½ + 1 + ½)
- **Line: atomic writes, validate before commit: ½.**
  - disk is exemplary: an fsync'd op log start, a lock, `recover`, and the approval policy.
  - `flow init` checks for a dirty tree, a foreign remote and the wrong branch before writing.
  - `.atlas` writes are read-modify-write with no temp file and rename: `init` uses `Bun.write`, `flow.ts:writeAtlasFlow`, and atlas-api `patchAtlas` uses `writeFile`.
- **Line: guarded and idempotent writes, `--dry-run`: 1.**
  - `init` refuses an existing `.atlas`.
  - `flow init` has `--dry-run` and `--force`. disk has `--dry-run` everywhere. `agent-log gc` has `--dry-run`.
  - `hostnames assign` reuses the `.atlas` port.
- **Line: secrets and read/write separation: ½.**
  - No secrets are printed.
  - `atlas help` does not say which commands write: `hostnames assign` costs ACME certs, `hosts sync` runs ssh/scp, `run` spawns a process. Only `prime`'s guardrails cover part of this.

### 9. Round-trip reduction: 1 (½ + ½ + 1)
- **Line: query-shape cache and `--refresh`: ½.** atlas-api serves from a 60 s cache that it refreshes in the background. `atlas scan` is the refresh, and disk has `--cached`. There is no per-command `--refresh` and no CLI-side cache.
- **Line: read-only commands avoid the backend: ½.**
  - These read only local files: `prime` and `brief` read `.atlas-cache.json` directly, and `board`, `disk` and `agent-log` are local.
  - `info`, `search`, `flow` and `hosts` call the API every time (about 30 ms, served from its cache).
- **Line: health probe and graceful degradation: 1.**
  - `run` returns `bound`, `lanReachable`, `exited` and the log path plus its tail.
  - `requireUp()` restarts the daemon when it is down. `open` and `tree web` print the URL when the API is down.
  - `info` survives a failed hostnames call, and `hosts` shows `⚠ unreachable` along with the last scan.

### 10. Automation & interop: 1 (1 + 0 + ½)
- **Line: inject-and-exec: 1.**
  - `agent-log run` (`run.ts:18`) and `agent-log guard` both call `process.exit(exitCode)`.
  - `jump --run` chains the command in the parent shell.
- **Line: query escape hatch and stdin `-`: 0.** Neither exists. The only stdin use is hook JSON for `agent-log hook` and `session-end`.
- **Line: pipe-through and session lifecycle: ½.**
  - Session lifecycle is automatic: `brief` runs as the SessionStart hook and `agent-log session-end` as SessionEnd.
  - Output does not feed the next command. `search` prints `relativePath`, which is relative to `~/dev`, not to cwd, so it cannot go straight into `info`. No command reads ids from stdin.

## Inventory

### Commands
In the table, "data" means the command prints something an agent reads, and "action" means it changes something. JSON states:
- **yes** — `--json` works today.
- **ignored** — `--json` is accepted, but text is printed.
- **err** — `--json` makes the command fail.
- **n/a** — the command is for humans or only writes.

| command | subcommands / args | kind | --json today | exit codes | non-TTY |
|---|---|---|---|---|---|
| `prime` | `[--json]` | data | yes (pretty) | 0 | fine |
| `tree` | `view [path] [--up]` · `search <q> [path]` · `compose [path]` · `web [path]`; no sub or an unknown sub prints help with exit 0 | data (`web` opens a browser) | ignored | 0/1 | fine |
| `init` | — | action: writes `.atlas` and bootstraps the journal | n/a | 1 if `.atlas` exists | fine |
| `info` | `[path] [--json]` | data | yes (pretty raw `Project` + `hostname`) | 0/1 | fine |
| `new` | interactive, or `<family/name> --name --category\|--out --var k=v` | action: cookiecutter, git flow, rescan, cd | err (parseArgs strict) | cookiecutter's code; 0 on cancel | **renders a prompt, exits 0** |
| `scan` | — | action plus counts | ignored | 0/1 | fine |
| `open` | — | human (browser) | n/a | 0 | fine |
| `run` | `[path]` | action: prints the URL scalar | ignored | 1 on exited or not bound | fine |
| `pick` | passthrough to atlas-picker | human | n/a | picker's code | fails |
| `jump` | `[q] [--run\|--cmd\|-r <cmd>]` | human (shell line via `$ATLAS_SHELL_FILE`) | n/a | 0/1 | no query: fails with a misleading hint |
| `search` (also `atlas <q>`) | `<q> [--run …]` | data | err ("Unknown flag", names `jump`) | 1 on no match | fine |
| `ports` | — | data: `GET /api/ports/audit` | ignored | 1 on collisions | fine |
| `templates` | `[list\|lint]` | data | err ("Unknown subcommand") | lint: 1 on errors | fine |
| `flow` | `[status] [path]` · `audit` · `init [path] [--dry-run] [--force]` | data plus action (`init`) | ignored | 0/1 | fine |
| `hosts` | `[list]` · `sync [host]` · `scan [host]` | data plus action | err (usage) | 0/1 | fine |
| `hostnames` | `[list]` · `assign [path]` · `rm [path]` | data plus action | err (usage) | 0/1 | fine |
| `services` | `[list]` · `sync` | data plus action | err (usage) | 0/1 | fine |
| `disk` | analyze, archive, archives, restore, scan, clean, trim, schedule, recover, log, config, doctor, tui, job | data plus action | yes on all (`Report` envelope, pretty) | **0 ok · 1 error · 2 nothing · 3 partial · 4 refused** | refuses with a reason; `--unattended` |
| `agent-log` | recent, begin, finding, end, handoff, session-end, run, init, console, status, claim, release, renew, checkpoint, guard, hook, gc, doctor | data plus action | yes on `recent`, `status` (compact); `hook` always prints JSON | doctor 1; run/guard mirror the child's code | fine |
| `board` | `[read] [--limit N] [--json]` · `post --re <s> <text>` · `speak` | data plus action | yes on read (compact array) | 0/1 | fine |
| `brief` | `[--json\|--install-hook]` | data | yes (compact); **prints nothing outside a project, even with --json** | always 0 | fine |
| `install-autocompletion` | — | action: writes `_atlas` | n/a | 0 | fine |
| `help`, `-h`, `--help`; `<cmd> --help` | — | help | — | 0 | — |

Commands that define a `usage` field: prime, hostnames, services, disk, agent-log and board. Every other command answers `--help` with its one-line summary.

### API error handling
- `api.ts` has `apiGet`, `apiPost` and `apiDelete`. Each throws `METHOD path → status statusText` and never reads the body. There is no `apiPatch`.
- `atlas.ts` `main().catch` prints `e.message` to stderr and exits 1. That makes it the single place every API error surfaces, so fixing `api.ts` fixes every caller.
- Callers that catch the error themselves:
  - `info` hostnames: `.catch(() => [])`.
  - `templates`: `die('GET /api/templates failed: …')`.
  - `new`: warns and falls back.
- All atlas-api routes return `{ error: string }` with a 4xx status: `/api/atlas`, `/api/run`, `/api/ports/kill`, `/api/daemons/:label` (`'writes disabled'`, `'not found'`, `'self-managed'`, `'invalid action'`).

### TTY handling and prompts
- `isTTY` appears only in `disk/approval.ts`, where `confirm()` returns false without a TTY and `approve()` refuses, and in `disk/clean.ts`.
- `@inquirer/prompts` is imported lazily by disk (`approval.ts:72`, `clean-pick.ts:12`). It is imported **statically** through `new-prompts.ts` on every invocation, which is the cause of the 64 KB truncation.
- `jump` with no query and `pick` run atlas-picker, which renders to `/dev/tty`.

### `atlas prime` output contract (`src/commands/prime.ts`)
- The constants `PURPOSE`, `WORKFLOWS` (8), `GUARDRAILS` (6) and `OUTPUT` (3) are maintained by hand. `detect()` reads the cache file and calls `isUp()`.
- `--json` returns `{name, version, purpose, workflows[{goal,steps}], guardrails, output, detected{cwd,api,project?,catalog?}}`.
- Commands are deliberately left to `atlas help`.
- The OUTPUT section leaves out board and disk `--json`, disk's exit codes 2/3/4, and the fact that disk's JSON errors go to stdout.

### install-autocompletion
- `completionScript(COMMANDS)` builds a zsh `_atlas` for both `atlas` and `pj`. It is written to `~/.zsh/completions` when that directory is on `$fpath`, otherwise to the first `$fpath` directory under `$HOME`.
- Contents: the top-level commands with their summaries from `COMMANDS`; `tree` subcommands hard-coded; project names read from `.atlas-cache.json` via `jq` at completion time (local projects only, not archived); and `_normal` after `--run`.
- A new top-level command only needs a rerun. Subcommands of `hostnames`, `daemons`, `disk` and the others are not completed.

### Argument parsing
- No library is used, apart from the standard library's `node:util` `parseArgs` in `new` (strict, so an unknown option throws).
- Everything else is hand-written:
  - `args.includes('--x')` combined with `args.find(a => !a.startsWith('-'))`, used by info, run, flow and tree.
  - Positional destructuring, which takes `--json` as a subcommand: hostnames, services, hosts, templates.
  - Three small parsers: `board.ts:parse`, `agent-log/args.ts:splitArgs` (every flag needs a value, so `--json` is stripped first) and `disk/flags.ts:parseFlags` (`--k v`, `--k=v`, with a set of value-less flags).
- Unknown flags are silently ignored, except in `search`/`jump` (`findUnknownFlag`) and `new`.

## Other findings
1. **Piped stdout is cut at 64 KB** in every command, because of the static `@inquirer/prompts` import (repro above). Fix it where it starts: load `new-prompts` lazily inside `new.ts:scaffoldFlow` (`await import('../new-prompts')`), the same way disk already does. Then `writeOut` is no longer needed as a workaround. **This must land before any large `--json` output (`ps --all`, `search`).**
2. **`--help` hides the real usage of `new`, `flow` and `tree`.** Set `usage: NEW_USAGE`, `usage: USAGE` and `usage: HELP` on those commands, one line each.
3. **`flow` matches the project path exactly** (`flow.ts:85`) instead of using `projectFor`, so `atlas flow` from a subfolder exits 1 ("No scanned project …atlas-cli"), while `info` from the same folder works.
4. **Without a TTY, `atlas new` prompts and then exits 0.** It should exit 1 immediately and point to the non-interactive form.
5. **`brief --json` prints nothing outside a project.** For JSON consumers it should print `null`; text mode must stay silent for the hook.
6. **`DELETE /api/run` runs a full `scan(DEV_FOLDER)` on every stop** (`run/+server.ts:204`), only to find the port. `atlas stop` will feel that cost. It is server-side, so the note is for workstream 5.

## Proposal (design for 6.1–6.11, in the style of the existing commands)

### Conventions (apply to every command touched)
- **Flags.** New commands parse with stdlib `node:util` `parseArgs({ strict: true, allowPositionals: true })`, as `new` already does. An unknown flag then exits 1 with parseArgs' message. Existing commands get the smallest possible change: `const json = args.includes('--json')`, and positionals skip `-`-prefixed args (the pattern `run`, `info` and `flow` already use). No new parser and no library.
- **`--json` output.**
  - Print the payload raw: the API response, or the rows the text shows. No envelope.
  - Write it compact on one line, as `brief`, `board` and `agent-log` already do. `info` and `disk` keep their pretty output unchanged.
  - The data goes to stdout. Exit codes are identical to text mode.
  - Text output stays byte-for-byte the same.
- **Errors.**
  - Change `api.ts` to a single `request(method, path, body?)` behind the existing `apiGet`, `apiPost` and `apiDelete` (signatures unchanged), and add `apiPatch`.
  - On `!r.ok`, read the body and throw `new Error(body.error ?? \`${method} ${path} → ${status} ${statusText}\`)`. The `atlas.ts` catch already prints it to stderr and exits 1, so nothing else needs to change.
  - disk keeps its `Report`/`emit` contract and its 0–4 exit codes.
- **Exit codes.** One table for the whole CLI, stated in `prime`:
  - 0 ok
  - 1 error, or a problem found (`ports` collisions, `hostnames check` taken or invalid, `hostnames doctor` drift remaining, `templates lint`)
  - 2, 3 and 4 are disk's codes, also used by `kill`: nothing matched, partial, refused.
- **TTY.** A command that wants confirmation uses disk's `confirm()` (`disk/approval.ts`). It returns false without a TTY, and the command then refuses with exit 4 and says which flag to pass. Never show a prompt without a TTY.
- **Help.** Every new command sets `usage`, with a signature and flags in the style of `services`. Fix finding 2 alongside.

### `--json` on every command that prints data (6.1, 6.9)
| command | JSON payload |
|---|---|
| `search <q> --json` | `[{name, slug, path, relativePath, host?, isLocal?}]`: the text columns plus the absolute path, so the output feeds `info`. Not the raw `Project[]`, which is about 0.5 MB. |
| `ports --json` | `/api/ports/audit` raw `{collisions, unmanaged}`; exit 1 on collisions kept |
| `scan --json` | `{projects, frameworks}` counts, never the whole atlas |
| `run --json` | `RunResult` raw (url, local, remote, bound, lanReachable, exited, replaced, log); exit 1 on exited or not bound kept, JSON still printed |
| `templates [list\|lint] --json` | list: the table rows `{family,name,version,vars,status}`; lint: `{errors, lint}`; exit codes kept |
| `flow [status] --json` | `{name, path, gitBranch, git, flow}`; `flow audit --json` → `{ready:[relativePath], blocked:[{relativePath,reason}], done:[…], skipped:n}` |
| `hosts [list\|scan] --json` | `[{id, role, ssh?, root, status, scannedAt, projectCount, error?}]` |
| `hostnames [list] --json` | `/api/hostnames` raw; `assign --json` → `AssignResult` raw |
| `services [list\|sync] --json` | `ServiceState[]` raw |
| `tree view\|search\|compose --json` | `TreeNode[]` · `SearchHit[]` · `[{path, kind, content}]` |
| `brief --json` | unchanged, plus `null` outside a project |

Commands for humans or for writing only get no `--json`: `open`, `pick`, `jump`, `tree web`, `init`, `new`, `install-autocompletion`, `board speak`, `agent-log console`.

### New commands
- **`atlas ps [--project <q>] [--kind <k>] [--all] [--json]`** (6.3)
  - Calls `GET /api/processes`; the shape is fixed by C.1.
  - Filtering happens on the client over the one snapshot:
    - The default shows app rows that have a project or a dev kind; `--all` shows everything.
    - `--kind` matches exactly.
    - `--project` is a case-insensitive substring of the project name or slug, matched with `search`'s normalisation.
  - Text output is a dense table, `PID KIND PROJECT PORTS CPU RSS UP COMMAND`, with COMMAND cut to the terminal width (or 80 columns when piped) and a footer `N shown · M hidden (--all)`.
  - `--json` prints the API rows filtered, untruncated and unchanged. An empty result exits 0.
- **`atlas kill <pid|:port|project> [--tree] [--force] [--dry-run] [--yes]`** (6.4)
  - Resolving the target:
    - `/^\d+$/` is a pid.
    - `/^:\d+$/` is every snapshot row listening on that port.
    - Anything else is a local project query, ranked like `search`. If it is ambiguous, list the candidates and exit 1.
  - Before acting, it always prints the targets to stderr: pid, kind, name, project, command, and the children when `--tree` is given.
  - It then sends `POST /api/processes/kill {pids, tree, force, dryRun}`; the name and path depend on C.1.
  - The server does all the safety work: a fresh snapshot checked by pid plus start time; it refuses pid ≤ 1, atlas-api itself, other users and launchd jobs; it sends SIGTERM and escalates to SIGKILL after 5 s only with `force`.
  - The server returns `[{pid, outcome: done|refused|failed, reason?}]`. The CLI maps these to disk's `ItemReport` and prints them through `disk/report.ts` `emit()`. That reuses the ✓/⊘/✗ rendering, `--json` and exit codes 0/2/3/4 without new code.
  - `--dry-run` sends `dryRun: true`, so the server's refusals are part of the preview.
  - Without `--yes`:
    - With a TTY, it asks `confirm()`.
    - Without a TTY, it refuses with exit 4: "no terminal; pass --yes".
  - It replaces the old `/api/ports/kill` path, which sent SIGKILL based on cached data (5.13).
- **`atlas stop [path]`** (6.5)
  - Resolves the path with `resolveRoot` plus `projectFor`, like `run`, then sends `DELETE /api/run {path: project.path}`.
  - Text output: `stopped <name>` or `<name> wasn't running`.
  - `--json` prints `{name, path, stopped}`. Both outcomes exit 0.
- **`atlas set <key> <value>` / `atlas set --unset <key>`** (6.6)
  - The target is the project that owns cwd (`projectFor`, like `info`). It sends `PATCH /api/atlas {path, patch: {[key]: value | null}}`.
  - Accept input loosely and store it strictly: the value goes through `JSON.parse` (numbers, booleans, objects), falling back to a string. `slug`, `description`, `url` and `domain` always stay strings.
  - Keys are checked against an allowlist of the keys the scanner reads: `slug port description archived devPublic type framework url domain domains umami flow template template_version agent-log`. An unknown key exits 1 and lists the valid ones, so a typo never silently writes junk.
  - DNS-label validation of the slug, and the route move, happen on the server (workstreams 3.1 and 3.4, `moveRoute` inside PATCH). The CLI never calls hostnames assign or rm itself.
  - Text output: `slug = foo  (project-atlas/.atlas)`, plus the new hostname line when the response carries one. `--json` prints the response raw.
  - Guardrail: every slug change costs two ACME certificates.
- **`atlas hostnames check <slug> [path]` and `atlas hostnames doctor [--fix] [--json]`** (6.7)
  - `check` calls `GET /api/hostnames/check?slug=&path=` (4.2) and prints a raw scalar: `free`, `taken by <holder>` or `invalid: <reason>`. It exits 0 only when the slug is free.
  - `doctor` calls `GET /api/hostnames/doctor` (3.8) and prints one line per drift item, `slug  kind  detail  → fix`.
  - `--fix` calls `POST /api/hostnames/doctor {fix: true}` and prints a result per item. Exit 1 while any drift remains. Doctor without `--fix` is the dry run.
  - These are added as two more branches in `hostnames.ts`; split the file if it grows past about 150 lines.
- **`atlas daemons [--json]` and `atlas daemons restart <label>`** (6.8)
  - The list comes from `GET /api/daemons`. Text table: `name label state :port(in use?) flags`, where flags are `stale`, `scheduled` and `self-managed`.
  - `restart` calls `POST /api/daemons/:label {action:'restart'}`. The label can be the exact label, or a unique substring of the label or name. If nothing matches, list the labels; if several match, list the candidates; both exit 1.
  - It refuses `selfManaged` daemons on the client, before calling, with a hint pointing to atlas-watchdog. A 403 `writes disabled` comes back through the new API error message.
  - No `start` or `stop` (YAGNI).

### prime and completion (6.11)
- **OUTPUT:**
  - `--json` on every command that prints data, compact, with the same exit codes. The exceptions are `open`, `pick`, `jump`, `tree web`, `init`, `new` and `install-autocompletion`.
  - Errors are the API's own message on stderr with exit 1. disk prints `{command, exit:'error', error}` on stdout.
  - Include the exit-code table.
- **WORKFLOWS:**
  - "Processes": `atlas ps --project <q> --json` → `atlas kill <target> --dry-run` → `--yes` · `atlas stop`
  - "Project settings": `atlas set <key> <value>` · `atlas set --unset <key>`
  - "Hostnames": `atlas hostnames check <slug>` · `atlas hostnames doctor --json` → `--fix`
  - "Daemons": `atlas daemons` · `atlas daemons restart <label>`
- **GUARDRAILS:**
  - `kill`: always `--dry-run` first, and `--yes` is required without a TTY.
  - `set slug` costs two certificates, and must never run in a loop.
  - Never `daemons restart` atlas-api.
  - Change "overrides go in `.atlas` (`atlas init`)" to "… (`atlas set`)".
- **Commands section** (recommended; it is what raises area 7 to 2):
  - Render `name — summary` from `COMMANDS` through a dynamic `import('../registry')`, the same trick `install-autocompletion` uses to avoid the circular import.
  - This is about 25 lines, and it makes `prime` a single call that cannot drift from the real commands.
- **Completion:** rerun `atlas install-autocompletion` after registering `ps`, `kill`, `stop`, `set` and `daemons`. Completing nested subcommands (hostnames, daemons, disk) stays out of scope until someone asks for it.

### Expected AFTER (same rubric and tick rule)
- Output & formatting goes from 1 to 2: `--json` everywhere and the 64 KB fix.
- Errors & feedback stays at 1, with a stronger line 3: API messages, `kill`/`stop` exit codes 0/2/3/4, and fail-fast without a TTY.
- Agent contract goes from 1 to 2, if `prime` gets the Commands section and an accurate output contract.
- Safety & writes goes from 1 to 2: `kill` with `--dry-run`, `--yes` and server-side safety, and `set` with its allowlist.
- Target: about 13–14/20 ("good"). Auto-JSON on pipe, `--fields`, error codes and categories, and stdin `-` remain open levers. They are out of scope for this brief.
