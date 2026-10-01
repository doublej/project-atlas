# Process snapshot, classifier and `/api/processes` contract (workstream 5 + 6, item C.1)

Research only, 2026-10-01, this Mac (Darwin 27, 10 cores, 16 GB). No code changed.
Fixture: `.orchestrate/console-upgrade/ps-fixture.txt` (command on line 1, then 116 real rows, secrets redacted).
Load average during measurements swung 40 → 334 (other agents' builds); every timing carries its load.

---

## 1. The `ps` invocation

```
LC_ALL=C /bin/ps -axww -o pid=,ppid=,pgid=,uid=,rss=,%cpu=,time=,lstart=,ucomm=,args=
```

Why each choice (all checked on the real output):

| Choice | Evidence |
|---|---|
| `LC_ALL=C` is mandatory | Without it (shell has `LANG=nl_NL.UTF-8`) `%cpu` prints `4,7` and `lstart` prints `ma 28 sep. 16:54:04 2026`. `sysctl vm.swapusage` has the same decimal comma. Pass `env: { LC_ALL: 'C' }` to every spawn (absolute binary paths, so no PATH needed). |
| `ucomm`, not `comm` | `comm` is the full exec path but clipped to 16 bytes unless it is the *last* column (`/usr/libexec/log` for logd). `ucomm` is the kernel's `p_comm`: the executable **basename**, ≤16 bytes (MAXCOMLEN), always left-justified in a fixed 16-byte column. 68–73 rows have spaces in it (`Google Chrome He`, `Creative Cloud C`), ~300 are clipped at 16. |
| `args` last | Only the last column is unpadded and untruncated (`-ww`). Longest real row: 5205 bytes (Agent-SDK `claude --system-prompt …`). |
| `lstart` (drop `etime`) | Fixed format `Thu Oct  1 13:00:23 2026`; `new Date(lstart)` in Bun parses it as local time correctly. Cross-check over all rows: max \|now − lstart − etime\| = 0.3 s, so `etime` is redundant. `pid + lstart` is the process identity for kill re-checks. |
| `time` added | Accumulated CPU (`min:ss.cc`, minutes unbounded, e.g. `983:49.36`). Gives lifetime-average CPU for the idle flag and exact CPU% between two samples for sparklines; `%cpu` is only a decaying average. |
| `uid` can be negative | `-2` (nobody: dhcp6d, distnoted). First parse attempt failed exactly on those 2 rows. |

**Encoding.** `args` is vis-encoded by ps (pure ASCII: newline → `\012`, `ö` → `M-C M-6`), but `ucomm` is raw UTF-8 and padded **by bytes** (tested with a copied binary named `ünïcödé-slp`: 15 bytes + 1 pad). So decode stdout as `latin1` (1 char = 1 byte), slice, then decode only `ucomm` back to UTF-8. Clipping at 16 bytes can split a multibyte char; that only garbles a display name.

**Parse (unambiguous: 7 numeric/time tokens, a 5-token date, a fixed 16-byte column, then the rest):**

```ts
// latin1: one char per byte, so the 16-byte ucomm column slices exactly; args are vis-encoded ASCII.
const ROW = /^ *(\d+) +(\d+) +(\d+) +(-?\d+) +(\d+) +(\d+\.\d+) +(\d+):(\d\d\.\d\d) +(\w{3} \w{3} [ \d]\d \d\d:\d\d:\d\d \d{4}) +(.{16}) (.*)$/
// 1 pid 2 ppid 3 pgid 4 uid 5 rss KiB 6 %cpu 7+8 cputime min/sec 9 lstart 10 ucomm 11 args
const exe = Buffer.from(m[10].trimEnd(), 'latin1').toString('utf8')
const args = m[11].trimEnd()            // retitled processes pad with spaces: "Raycast Backend  ", "npm exec   "
```

Do not rely on header column offsets: `RSS` overflows its 6-wide column past 1 GB and shifts later columns, so whitespace tokens are the only safe split for the numeric part.

Verified: 811 / 820 / 820 live rows, **0 unparsed** (after the `-?` uid fix); all 116 fixture rows parse. JS parse time 0.5–1.6 ms for ~740 rows (10 ms on a cold Bun).

**Special `args` values:**
- `<defunct>`: zombie. It cannot be signalled; only its parent can reap it. Seen: `git` zombies in atlas-api's own group, `node` under shopify.
- `(<ucomm>)`, e.g. `(Python)`, `(bash)`, `(node)`, `(bun)`, `(compile)`, `(asm)`: ps could not read the args, so it printed `p_comm` in parentheses. These are mostly mid-exec, but not always: a `(node)` with 10.5 s of CPU and a `(bun)` test worker were seen. Rule: `args === '(' + exe + ')'` sets `argsUnavailable`, and the row is classified by `ucomm` plus its parent/group. A paren *inside* args (`/usr/libexec/UserEventAgent (System)`, `Core Audio Driver (BlackHole16ch.driver)`) is not this case.

---

## 2. Fixture (`ps-fixture.txt`)

Line 1 is the exact command; rows come from three real captures (system snapshot 13:02, an earlier one at 12:57, and short-lived probes I started under `/tmp/psprobe` and stopped afterwards). Every pid is unique. Parent chains within each group are consistent.

Covered (pid → what):
- **atlas-api itself**: 977 `bun build/index.js` (launchd `com.jurrejan.atlas-api`), its transient `(bash)` 75502 and `git <defunct>` 73350 in pgid 977, its atlas-run server 67570 `bun dev` → 67584 `node …/vite dev --host 0.0.0.0 --port 4123` (own pgid, ppid 977).
- **bun run / bunx**: 34702 `bun run build` → 34703 vite build; 66265 `node …/bunx-501-mcp-remote@latest/…/mcp-remote` (Bearer REDACTED); 28686 `bun …/channel.ts`; 23074 `bun /tmp/perfbench/series.ts`.
- **node + vite/wrangler/tsx/esbuild**: vite dev/build/preview (67584, 34703, 48894 relative `node node_modules/.bin/vite preview`, 72729/72732 orphans); wrangler 61126 → 61250 (`wrangler-dist/cli.js dev`) → esbuild 62577; tsx 61101 → 61461 (`--require …preflight.cjs --import … --eval`) + esbuild 61427; esbuild service 61099.
- **npm exec / npx**: 61102 retitled `npm exec   ` (ucomm `node`) → 61743 `node -e …`.
- **uv run → .venv python**: 981→1223, 986→1116→1364 (+ `bd list --json --all` 75800), 993→1125(+zombie 74329), 994→1073→Agent-SDK claude 73102 + ssh 51980 (DECKHAND_TOKEN REDACTED); `uv run --no-project python serve.py` 94714→94721 (uv-managed cpython); `uv run --project … deckhand-mcp` under every claude session.
- **python**: uvicorn 61116 (argv0 is Homebrew's `Python.app/Contents/MacOS/Python`, the venv path is only in args[1]); jupyter 61117 (`~/Documents/development/…/.venv/bin/python3` (the old symlink path) `…/jupyter kernel`) → ipykernel 61907; pyright 61104 (Python.app) → node langserver 61269; Python.app scripts 538 (root), 76593; argless `(Python)` rows exist live but are transient. The fixture's argless rows are `(bash)`, `(node)`, `(bun)`, `(compile)`, `(asm)`, same rule.
- **bd / beads**: 72222 `bd linear sync` (pgid 71489 = launchd job `com.jurrejan.pimpelmees-theme-linear-sync`), 75800.
- **cargo / rustc**: 61084 `cargo run` → rustc 61225 → cc 61513 → `sh -c` 61522 (ucomm `bash`!) → xcodebuild 61524. Note `cargo run` *execs in place*: pid 61084 later became `sleepy` with the same lstart, so pid+start identity survives exec while the kind changes.
- **go**: 61082 `go run main.go` → `(compile)` 61265, `(asm)` 61289, compile 61526 → `/var/folders/…/go-build…/exe/main` 64171.
- **deno**: 61081 `deno eval …`.
- **language servers**: tsserver 61090 (+ typingsInstaller 61579), pyright 61104/61269, rust-analyzer 61100 (only the rustup proxy: ucomm `rustup`, args `rust-analyzer`, no toolchain component installed).
- **MCP servers**: Consult User MCP `node /Applications/Consult User MCP.app/…/mcp-server/dist/index.js` (28684, 66263, 73242), deckhand-mcp (uv + python), mcp-remote, channels (bun). All share their claude session's pgid.
- **Claude Code**: ucomm is the **version** (`2.1.284`/`2.1.285`/`2.1.286`), args `claude --name <n> …` / `claude --resume <uuid>`; Agent-SDK claude has ucomm `claude`. Chain iTermServer 94813 → `login` 67730 (uid 0) → `-zsh` 67732 → claude 25701. Bash-tool shells `/bin/zsh -c source …shell-snapshots…` get their **own** pgid (34699, 51367).
- **Codex**: 49106 `codex app-server daemon pid-update-loop` → 1775 `codex app-server --listen unix://`; 35032 `ChatGPT for Chrome` host from `~/.codex/plugins` inside Chrome's group. No interactive codex session was running.
- **onenv as node**: 48223 `node ~/.bun/bin/onenv run -- claude --name xenon-otter …` → 48367 claude (same pgid); 51375 `node …/onenv export wallgen -- bash …`.
- **Adobe `.node`**: 1445 ucomm `Creative Cloud C`, args `…/CCXProcess.app/Contents/MacOS/Creative Cloud Content Manager.node /App…`; also 1349, 1372, 786.
- **apps**: Chrome 34836 + helper 11387, Obsidian, iTerm2, iTermServer, ActivityWatch `aw-server-rust` (ppid 1, dead pgid leader, not launchd), `Raycast Backend` (retitled node).
- **system**: launchd, logd, dhcp6d (uid -2), distnoted, UserEventAgent, WindowServer (uid 88), Core Audio Driver (uid 202), mds_stores (uid 308), login (uid 0).
- **tools**: ssh (tunnel `-N -L`, mux-less), `op daemon` (ppid 1, dead pgid leader), caffeinate, git.

**Absent on this Mac today (no real row, so no fixture line):** docker / `com.docker.*` (Docker Desktop installed, not running; no socket), caddy and ollama (not installed), a `dolt sql-server` (bd 1.2.1 defaults to **embedded** dolt, so `bd dolt start` is "not supported in embedded mode"; only `--proxied-server` workspaces run one), gopls and svelte-language-server (not installed/running), `next dev` (Next retitles its server process to `next-server (vX.Y.Z)`), workerd (wrangler's runtime failed to start in the probe). Write synthetic test rows for these in the test file itself, marked as synthetic; keep the fixture real.

Expected kinds for the fixture, from the prototype classifier in §6a (0 mismatches against intent):

```
agent:            73102 49106 1775 25701 48367 25030 66184 19653 73159
mcp:              28684 28698 28686 66263 66265 66285 73242 73244 73275
dev-server:       67584 1223 1364 48894 72729 72732 61116 61117 61126 61250 61907
build:            34703 34392 61265 61289 61225 61099 61427 61513 61524 61526 62577
language-server:  61090 61100 61104 61269 61579
runner:           67570 981 986 993 994 48223 28685 66264 73243 34699 34702 33195 34365 51367 51375 94714 61082 61084 61101 61102 61522
program:          977 1116 1125 74329 1073 35032 34568 94721 76593 75718 77211 23074 61081 61743 61461 64171
tool:             73350 75800 51980 72222 1337 27009 95305 71835 63745 69902
shell:            75502 67732 23798
app:              1288 1349 1372 1445 786 26210 34836 11387 56371 94676 94813
system:           1 358 427 647 361 431 597 65258 538 67730
```

Expected app rows (multi-member process groups → primary):
`977→977` · `981→1223` · `986→1116` · `993→1125` · `994→1073` (not the transient SDK claude) · `25030→25030` · `33178→34392` (leader gone) · `34699→34703` · `34836→34836` (not the ChatGPT host) · `48223→48367` (onenv folded into claude) · `51367→51375` · `61082→64171` · `61084→61225` · `61101→61461` · `61102→61743` · `61126→61126` · `66184→66184` · `67570→67584` · `72708→72729` (leader gone, two dev-server roots, tie → larger RSS) · `73159→73159` · `94710→94721` (leader gone).

---

## 3. Timings (this Mac, 3 runs each, Bun `execFile` unless noted)

| Step | ms (3 runs) | Output | Load (1-min) |
|---|---|---|---|
| `ps -axww …` (the snapshot) | 223 / 227 / 521 | 257–278 KB, ~740–840 rows | 90 |
| same | 253 / 355 / 284 | 268 KB | 293 |
| same (inside the pipeline, parallel) | 43–71 for the whole parallel step | | 40 |
| column cost, shell timer: `pid=` only / `+args` / full | 65–96 / 151–176 / 160–185 (cold first run 1063) | | 90 |
| `lsof -b -w -a -d cwd,1 -Fpfn -p <candidates>` | 16 / 19 / 43 (~92–102 pids) | 4.5 KB | 90 |
| same | 29 / 23 / 19 | | 40 |
| `lsof … -u <me>` (no ps dependency) | 503 / 189 / 228 | 33 KB | 90 (rejected: walks every app helper) |
| `netstat -anv -p tcp` (ports.ts) | 53 / 31 / 27 | 107 KB | 293 |
| `launchctl list` | 14 / 24 / 11 | 20 KB | 293 |
| `sysctl -n kern.memorystatus_vm_pressure_level vm.swapusage hw.memsize` | 2 / 2 / 11 | | 90 |
| `docker ps` with the daemon down (listeners.ts runs it every scan) | 319 / 140 / 147 | 0 B | 293 |
| docker socket check, 3× `existsSync` in-process | 0.21 / 0.04 / 0.04 | | |
| `ps -Eww -o pid=,command= -U <me>` | 245 / 227 / 199 | **1.1 MB** of environment | 293 |
| `ps -Eww … -p <14 agent pids>` (cold) | 82 / 100 / 86 | | 40 |
| **Pipeline**: parallel(ps, netstat, launchctl, sysctl) → parse → lsof(candidates) | **101 / 67 / 75** | | 40 |
| parallel ps+lsof(-p)+netstat+launchctl, all at once | 182 / 320 / 110 | | 293 |

Conclusions:
- Serial `ps → lsof -p <candidates>` beats parallel `lsof -u`: candidates are known only after ps, but lsof on ~100 pids costs ~20–40 ms while `-u` costs 190–500 ms.
- The fresh snapshot fits the <150 ms target at normal load (67–101 ms at load 40). At load ≥ 90, ps alone costs 200–500 ms. Nothing in userland fixes that; the 2 s cache plus a shared in-flight promise is the defence.
- `ps -E` costs another full process walk (~80–100 ms), regardless of how many pids are passed. Run it **in parallel with lsof**, and only for pids not already in the cache (§4). Steady state adds 0 ms.
- Skipping `docker ps` when no socket exists saves 140–320 ms per listeners scan **today**.
- Docker sockets checked: `/var/run/docker.sock`, `~/.docker/run/docker.sock` (current context `desktop-linux`), `~/.colima/default/docker.sock` (colima context), `~/.orbstack/run/docker.sock`, `~/.rd/docker.sock`. All absent right now. Rule: run `docker ps` only if one of the first three exists (and is a socket). The others aren't installed, so YAGNI.

---

## 4. `CLD_SESSION_NAME`

Only counts and pid → token were ever printed; no environment was printed or stored.

- `ps -Eww -o pid=,command= -U "$USER" | grep -o 'CLD_SESSION_NAME=[A-Za-z0-9_.-]*' | sort | uniq -c` returned 15 distinct names (e.g. `dusk-shrike` ×42, `swift-ibis` ×41, `nimble-serval` ×19, …), plus `CLD_SESSION_NAME=` (empty) ×5. **Yes, `ps -E` exposes the initial environment of JJ's own processes.**
- The pid-mapped variant (`awk '{ if (match($0, /CLD_SESSION_NAME=[A-Za-z0-9_.-]*/)) print $1, substr($0, RSTART+17, RLENGTH-17) }'`), joined with a separate non-E `ps -o pid=,ppid=,ucomm=`, found **166 carriers**. Children inherit it: zsh, bun, node, uv, python3.13, caffeinate, tail, gtimeout, Chrome-for-Testing (54) and chrome_crashpad. The two **orphaned** `vite preview` processes (ppid 1) still carried `dusk-shrike`. So the token attributes leftovers to the session that started them, even after reparenting.
- The `claude` process itself carries it (13 × `2.1.286`), so it is set before claude starts (by JJ's launcher). Not every session has it: `claude --resume <uuid>` and the Agent-SDK claude had none.
- 12 of 14 agent processes were named.
- It is the initial environment at exec, so runtime `setenv` is invisible. Since it can never change for a given process, cache it by `pid@startedAt`.
- Cost: `-E -U me` 199–245 ms and 1.1 MB at load 293; `-E -p <14 agents>` 82–100 ms at load 40.

Safe server-side extraction (stream it, keep only the token, never buffer or log the output):

```ts
// `ps -E` appends each process's initial environment to its command. Only the session token
// survives: each line is dropped once the regex has run, stderr is ignored, nothing is logged,
// and the result is the only thing kept.
const SESSION = /(?:^|\s)CLD_SESSION_NAME=([A-Za-z0-9_.-]{1,64})(?=\s|$)/g

async function readSessionNames(pids: number[]): Promise<Map<number, string>> {
  const names = new Map<number, string>()
  if (!pids.length) return names
  const ps = spawn('/bin/ps', ['-Eww', '-o', 'pid=,command=', '-p', pids.join(',')], {
    env: { LC_ALL: 'C' },
    stdio: ['ignore', 'pipe', 'ignore'],
  })
  for await (const line of createInterface({ input: ps.stdout })) {
    let name: string | undefined
    for (const m of line.matchAll(SESSION)) name = m[1] // last match wins: the environment follows the args
    if (name) names.set(Number.parseInt(line, 10), name)
  }
  return names
}
```

Use `spawn` + `readline`, not `execFile`, which would hold all ~1 MB of environment in one string. Query only `pid@startedAt` keys not yet in a module-level `Map<string, string | null>`, and prune keys absent from the latest snapshot. Pass the dev-ish candidates (same list as lsof) plus agents. Never echo the line in an error, never add it to a log, never send anything but `session` to the client.

---

## 5. launchd-managed detection

`launchctl list` (as the user; 11–24 ms) prints `PID\tStatus\tLabel`: 205 jobs here with a live pid, 23 of them `application.*` (GUI apps started by LaunchServices: iTerm2, Obsidian, 1Password, …). The `com.jurrejan.*` daemons appear with their pids (977 atlas-api, 981 snail-mail, 986 reminders-bridge, 994 deckhand, …).

**Rule:** `label = jobs.get(pid) ?? jobs.get(pgid)`.
- launchd makes every job a process-group leader, so anything a job spawns without its own `setpgid` shares the job's pgid. Verified: deckhand job 994 ⊃ python 1073 ⊃ Agent-SDK claude 73102 (all pgid 994); `bd linear sync` 72222 has pgid 71489 = job `com.jurrejan.pimpelmees-theme-linear-sync`; atlas-api's in-flight `(bash)`/`git` children are in pgid 977.
- atlas-run dev servers are spawned `detached`, so they have their own pgid and are correctly **not** part of atlas-api's job.
- `ppid == 1` alone is worthless: 376 user processes have ppid 1 and only 214 are in a launchd job by pid or pgid. The rest are XPC services, app helpers and real orphans (vite preview with dead pgid leader 46368, `uv run … serve.py` with dead leader 94710). `op daemon` and `aw-server-rust` deliberately daemonize (dead pgid leader, no label) and are kind `tool`/`app`, so the orphan flag never touches them.
- Enrich the label with `shared/daemons.json` (`getDaemonByLabel`) for a display name; the registry is not needed for detection.

---

## 6. Proposal

### 6a. Kind taxonomy and classification rules

`ProcessKind` (stable strings, valid in the CLI `--kind`):

| kind | meaning |
|---|---|
| `agent` | Claude Code (ucomm is a version `^\d+\.\d+\.\d+$` and argv0 basename `claude`; or ucomm `claude` from the Agent SDK) and Codex (ucomm `codex`, or a runtime whose entry is `codex`). |
| `mcp` | MCP server (stdio child of an agent, or named `*-mcp`/`mcp-*`). |
| `dev-server` | Something serving a project: vite/next/next-server/nuxt/astro/wrangler/workerd/uvicorn/gunicorn/flask/`manage.py runserver`/`http.server`/jupyter/ipykernel/streamlit, any tool invoked with a `dev\|serve\|preview\|start\|runserver` verb, or (post-pass) a `program` that listens on TCP and is attributed to a project and isn't launchd-managed. |
| `build` | Compilers, bundlers, checkers and tests: tsc, esbuild, rollup, webpack, rustc, cc, clang, ld, xcodebuild, swiftc, go `compile`/`asm`/`link`, svelte-check, biome, eslint, prettier, vitest, jest, playwright, pytest, ruff, mypy, plus any tool with a `build\|check\|test\|lint\|typecheck\|clippy\|vet` verb. |
| `language-server` | tsserver, typingsInstaller, `*language-server*`, `*langserver*`, pyright, rust-analyzer (incl. rustup proxy), gopls, sourcekit-lsp, `lsp-proxy`. |
| `runner` | Wrappers that only start something else: uv/uvx, npm/npx (and retitled `npm exec`), pnpm, yarn, `bun run`/`bun x`/`bun <script-name>`, just, make, concurrently, turbo, nodemon, watchexec, env, nohup, timeout, tsx (CLI), **onenv**, `sh\|bash\|zsh -c`, `cargo run\|watch`, `go run`. |
| `program` | User code on a runtime (`node x.js`, `bun file.ts`, `python script`, `deno eval`, `node -e`), compiled project binaries (`target/debug/x`, `go-build…/exe/main`), and argless runtimes. |
| `infra` | docker / dockerd / `com.docker.*` / containerd / vpnkit / qemu / lima / colima, caddy, ollama, dolt (`sql-server`), postgres, mysqld, redis-server, mongod, nginx, OrbStack. |
| `tool` | Other CLIs in flight: bd, git, gh, ssh, rsync, op, curl, rg, jq, lsof, ps, tail, sleep, caffeinate, osascript, it2, atlas, … plus any binary under `/opt/homebrew`, `/usr/local`, `/usr/bin` not matched earlier. |
| `shell` | Interactive shells: `-zsh`, `zsh -l`, bash, fish, tmux, screen. |
| `app` | GUI apps and their helpers: a `*.app/Contents/` path not under `/System/`, `/Library/Application Support/…`, and retitled runtimes such as `Raycast Backend`. |
| `system` | uid ≠ JJ, or argv0 under `/System`, `/usr/libexec`, `/usr/sbin`, `/sbin`, `/Library/Apple`. |
| `other` | Fallback. |

Default ("dev") view = groups whose primary kind is one of `agent, mcp, dev-server, build, language-server, runner, program, infra`, **or** that have a project attribution.

**General rules (first match wins), on three inputs:**
- `exe` = ucomm, the kernel name (exact matches only, never `startsWith('node')`).
- `a0` = argv[0] basename, with a leading `-` stripped.
- `entry` = for a runtime (`exe` or `a0` ∈ `node|bun|deno|python*|Python|ruby|perl|php|java`), the first non-flag token after it, skipping the values of `--require -r --import --loader -X -W --cwd --config`. `-m mod` gives entry `mod`; `-e -c -p --eval --print eval` give `<inline>`. Its name `ename` = basename without `.js/.cjs/.mjs/.ts`. A generic name (`cli|index|main|server|run|start|bin|app`) is replaced by the package dir (the segment after the last `node_modules/`, else the nearest parent that isn't `dist|bin|lib|build|src|out`), so `…/wrangler/wrangler-dist/cli.js` names `wrangler` and `…/mcp-server/dist/index.js` names `mcp-server`.
- `verb` = the first `dev|serve|preview|start|runserver` or `build|check|test|lint|typecheck|clippy|vet` among the first two non-flag tokens after the entry (or after argv0 for binaries). This one rule covers `vite dev`, `vite build`, `next start`, `wrangler dev`, `shopify theme check`, `cargo test`, `go vet`, `bun test`, `.venv/bin/snail-mail serve`.

Order:
1. `uid !== self` → `system`.
2. agent (see table).
3. language-server by `ename`/`a0`/`exe` (also `exe === 'rustup' && a0 === 'rust-analyzer'`).
4. runner (see table; `/^npm( |$)/` on args catches the retitled `npm exec`).
5. mcp by `ename`/`a0` (`/(^|[\/_.-])mcp([\/_.@-]|$)/i`). This tests the **name**, never the whole path: `~/dev/mcp/mcp_agent_mail/.venv/bin/uvicorn` is a dev-server.
6. build (name list or build verb), then dev-server (name list or dev verb).
7. infra, tool (name lists), shell.
8. Runtime fallback. A retitled runtime (argv0 neither a path nor a runtime name: `Raycast Backend`) → `app`; otherwise → `program`.
9. Path rules: `/Library/Application Support/` or `*.app/Contents/` (not `/System`) → `app`; system dirs → `system`; `$HOME`, `/var/folders`, `/tmp` → `program`; `/opt/homebrew`, `/usr/local`, `/usr/bin` → `tool`; else `other`.
10. Post-pass (needs the tree):
    - A `program` whose parent is an `agent`, or whose entry dir has an `mcp`-named segment, becomes `mcp` (Consult User MCP, channels).
    - A `program` that listens on TCP, is attributed to a project and isn't launchd becomes `dev-server`.
    - An argless row (`(x)`) takes its kind from `exe` alone; a runtime one is `program` and folds into its group.

Pitfalls the rules encode (all seen live):
- **`.node` is not node**: Adobe's `Creative Cloud Content Manager.node` has ucomm `Creative Cloud C`, and runtime detection is an exact `exe`/`a0` match.
- **onenv appears as node**: `node ~/.bun/bin/onenv run -- claude …`. `ename === 'onenv'` makes it a runner, and its group folds into the claude it wraps (pgid 48223).
- **`sh -c` has ucomm `bash`** on macOS. Use `a0` (`sh`) plus `-c`.
- **Python's argv0 may be `Python.app/Contents/MacOS/Python`**, not the venv path (uvicorn 61116, pyright 61104). Classification uses `entry`, and attribution scans every arg.
- **`cargo run` execs in place** (same pid and lstart, kind changes from runner to program). Classify every snapshot afresh; never cache kind by pid.

Prototype: ~120 lines of TS, run against the fixture with the results in §2. Rebuild it in `src/lib/processes/classify.ts` as a pure function with a table-driven test over the fixture.

### 6b. Project attribution

Per process, first hit wins, against the in-memory local projects (`scan(DEV_FOLDER, { skipGit: true })`, `isLocal` only; reuse `projectFor()` from `listeners.ts`, deepest match):
1. **cwd** from the batched `lsof -b -w -a -d cwd,1 -Fpfn -p <candidates>`. lsof returns realpaths. Relative args (`node node_modules/.bin/vite preview`) are only attributable this way. Candidates are uid = self, not zombie, kind not in `app|system`, plus every netstat listener pid: ~100 pids here.
2. **A path in args**: every token starting with `$HOME/`. **realpath its directory, not the file** (`realpath(…/.venv/bin/python3)` escapes to `~/.local/share/uv/python/…`; `realpath(…/.venv/bin)` gives `~/dev/python/gokova-flights/.venv/bin`). Cache per directory (~0.03 ms each). This also normalises `~/Documents/development/…` (seen in jupyter args) to `~/dev`. Covers `<project>/.venv/bin/python`, `<project>/node_modules/.bin/vite`, `uv run --directory <project>`, `--project <project>`.
3. **Group**: a member with no attribution inherits its group primary's project.

Record `via: 'cwd' | 'args' | 'group'`. Also compute `checkout`: the cwd up to and including `/.claude/worktrees/<name>` when present, else the project path. A worktree build (`kunstuitleen-gallery/.claude/worktrees/wf_…/node_modules/.bin/vite build`) must not count as a duplicate of the main checkout's dev server.

fd 1 from the same lsof call:
- Under `~/dev/.atlas-logs/` (`/Users/jurrejan/dev/.atlas-logs/web-kunstuitleen-gallery.log` for 67570/67584), the row is an **atlas-run** server: set `atlasRun: { log }`. That enables restart/open-log and survives atlas-api restarts.
- Any other regular file (not `/dev/…`, not a pipe) becomes `stdout`, e.g. `/private/tmp/serve-8936.log`, so agents can find logs too.

### 6c. App rows: fold by process group

**An app row is one process group (pgid).** Every wrapper chain in the brief already shares a pgid: `uv run`→`.venv` python (981/1223), `bun run build`→vite (34702/34703, under the agent's `zsh -c` 34699), `bun dev`→vite (67570/67584), `npm exec`→`node -e` (61102/61743), `sh -c`→xcodebuild inside cargo (61084), `onenv run`→claude (48223/48367), wrangler→cli.js→esbuild (61126). A claude session's MCP servers share its pgid and fold into the session row; its Bash-tool shells get their own pgid and form their own rows. Process groups are also exactly what `stopProjectListeners` already kills (`kill(-pgid)`).

Primary member (names the row):
1. root = the group leader (pid == pgid) if alive, else the member whose ppid is outside the group (several: highest rank, then RSS).
2. While root is a `runner` or `shell` with children in the group, step to its highest-ranked child. Rank: `agent > dev-server > mcp > language-server > program > build > infra > tool > app > runner > shell > system > other`.
3. Row `kind`/`name` = primary's. A `program` with a generic name and a project uses the project name (atlas-api's `index` → `atlas-api`).

Row aggregates: `cpu` = Σ %cpu, `rss` = Σ bytes, `cpuTime` = Σ, `uptime` = oldest member, `ports` = ∪, `session` = primary's (else any member's), `launchd` = label of pgid, `atlasRun` = primary's.
Ceiling: a wrapper that `setsid`s its children splits into two rows. Not seen in the fixture; link via ppid if it ever matters.

### 6d. Flags (on rows; thresholds as named constants)

| flag | rule | live calibration |
|---|---|---|
| `orphan` | Primary kind ∈ `dev-server, build, program, mcp, language-server, runner`, no launchd label, not `atlasRun`, and **either** `orphanReason: 'parent-exited'` (root's ppid is 1: terminal closed, agent's Bash tool exited, agent died) **or** `'folder-gone'` (cwd no longer exists). | Live: 1 hit, `preview_server.py` 76593 (started by hand, not via its launchd job). Earlier: vite preview 48894/72729/72732 and `uv run … serve.py` 94714. 0 false hits among 376 ppid-1 user processes. |
| `duplicate` | ≥2 rows of kind `dev-server` with the same `checkout` **and** the same `name` (vite+vite, not vite+uvicorn). `duplicateOf: number[]` = the other pgids. The UI suggests stopping the one not on the project's `.atlas` port. | |
| `idle` | Primary kind ∈ `dev-server, program, build`, no launchd label, uptime ≥ 24 h, Σ cpuTime / uptime < 0.1 %, Σ %cpu < 1. | Row-level matters: the MCP servers of a 1.8-day-old session match per process but fold into their agent row, which is exempt. |
| `heavy` | Σ rss ≥ 1 GiB **or** Σ %cpu ≥ 90; any kind. `heavyBy: ('rss'|'cpu')[]`. | Chrome group 1.59 GiB (34 procs); an agent's `timeout` test run 1.46 GiB. |

### 6e. Kill safety (server-side, every caller: UI, CLI, Raycast)

`POST /api/processes/stop` never uses the cached snapshot. It takes a fresh `ps` plus `launchctl list` in parallel (~50–100 ms), then for every target, and for every tree member when `tree`:

| check | result |
|---|---|
| pid not in fresh snapshot | `status: 'gone'` (goal met) |
| `startedAt` ≠ fresh lstart (ISO) | refuse `pid-reused` |
| pid ≤ 1 | refuse `protected-pid` |
| uid ≠ `process.getuid()` | refuse `other-user` (root `login`, WindowServer …) |
| pid = `process.pid`, or pgid = atlas-api's pgid (its in-flight git/bash) | refuse `atlas-api` |
| `jobs.get(pid) ?? jobs.get(pgid)` has a label (incl. `application.*`) | refuse `launchd-job` + `label` (hint: `atlas daemons restart <label>`). GUI apps and their helpers are out of scope: SIGTERM quits without a save prompt. |
| args `<defunct>` | refuse `zombie` (stop its parent instead) |

Signals:
1. SIGTERM to every accepted pid, top-down in the same tick (parent first, so supervisors such as nodemon/concurrently can't respawn the children).
2. Poll `kill(pid, 0)` up to 3 s, or 5 s with `force`.
3. With `force`, re-verify `pid+lstart` for the survivors with one `ps -o pid=,lstart= -p …`, then SIGKILL. SIGKILL is never sent without `force`, and never before 5 s.

`tree` = the ppid closure in the fresh snapshot. Tree members that fail a check are listed in `skipped` and not signalled.
Ceiling: a child forked between the snapshot and the signal survives and is reported as `still-running` on its parent's line. Upgrade path: also `kill(-pgid)` when the target leads a group whose members all passed.

`/api/ports/kill` (SIGKILL from a 10 s cache) and `killListeners()` are removed. The ports page sends `{ pid, startedAt }` from its listener rows to `/api/processes/stop`. It is the only consumer (grep across atlas-cli, atlas-browser, atlas-picker and atlas-api).

### 6f. Contract

Shared types live in `atlas-api/src/lib/processes/types.ts`, and the CLI copies them, as it does today for `PortAudit`. Units are fixed: bytes, seconds, `%` of one core (can exceed 100), ISO 8601 timestamps. No UI-only fields.

```ts
type ProcessKind = 'agent' | 'mcp' | 'dev-server' | 'build' | 'language-server' | 'runner'
  | 'program' | 'infra' | 'tool' | 'shell' | 'app' | 'system' | 'other'
type ProcessFlag = 'orphan' | 'duplicate' | 'idle' | 'heavy'

interface ProcessProject { name: string; path: string; slug?: string }

interface ProcessInfo {
  pid: number
  ppid: number
  pgid: number
  uid: number
  startedAt: string          // ISO from lstart (1 s resolution); identity is pid + startedAt
  kind: ProcessKind
  name: string               // 'vite', 'uvicorn', 'claude', 'deckhand-mcp', 'Google Chrome'
  exe: string                // kernel name (ucomm), ≤16 bytes, may be clipped
  command: string            // args as ps prints them (vis-encoded), secrets redacted; '' when argsUnavailable
  argsUnavailable?: true     // ps printed "(exe)"
  zombie?: true              // <defunct>
  cpu: number                // %CPU, ps's decaying average
  cpuTime: number            // CPU seconds since start (delta between samples = exact CPU%)
  rss: number                // bytes
  uptime: number             // seconds at generatedAt
  cwd?: string               // dev-ish candidates and listeners only
  stdout?: string            // regular file on fd 1 (logs)
  project?: ProcessProject
  via?: 'cwd' | 'args' | 'group'
  checkout?: string          // project path or its .claude/worktrees/<name>
  ports?: number[]           // TCP LISTEN (netstat)
  launchd?: string           // label when pid or pgid is a launchd job
  atlasRun?: { log: string } // started by atlas /api/run (stdout in ~/dev/.atlas-logs)
  session?: string           // CLD_SESSION_NAME, server-side only (§4)
}

interface ProcessGroup {     // "app row": one process group
  pgid: number
  primary: number            // pid naming the row
  kind: ProcessKind
  name: string
  project?: ProcessProject
  pids: number[]             // primary first, then the rest in tree order
  cpu: number                // Σ
  cpuTime: number            // Σ
  rss: number                // Σ bytes
  uptime: number             // oldest member
  ports: number[]            // ∪
  session?: string
  launchd?: string
  launchdName?: string       // shared/daemons.json name, when registered
  atlasRun?: { log: string; hostname?: string }
  flags: ProcessFlag[]
  orphanReason?: 'parent-exited' | 'folder-gone'
  duplicateOf?: number[]     // other pgids
  heavyBy?: ('rss' | 'cpu')[]
}

interface ConsumerEntry { pgid: number; name: string; kind: ProcessKind; rss: number; cpu: number }

interface SystemMemory {
  memTotal: number                              // hw.memsize
  pressure: 'normal' | 'warn' | 'critical'      // kern.memorystatus_vm_pressure_level 1 | 2 | 4
  freePercent: number                           // kern.memorystatus_level
  swapTotal: number                             // vm.swapusage (LC_ALL=C), bytes
  swapUsed: number
  loadAvg: [number, number, number]             // os.loadavg()
  topByRss: ConsumerEntry[]                     // 5, over ALL groups regardless of filters
  topByCpu: ConsumerEntry[]
}
```

**`GET /api/processes`**

Query (all optional):
- `all=1`: every group (apps, system, other users); default is the dev view (§6a).
- `project=<abs path | name | slug>[,…]`: groups attributed to it.
- `kind=<kind>[,…]`: group kind. An unknown kind gives 400 `{ error, kinds: ProcessKind[] }`.
- `fresh=1`: bypass the 2 s cache.

Filters apply to **groups**; `processes` holds exactly the members of the returned groups.

```ts
interface ProcessesResponse {
  generatedAt: string
  host: string                // 'm2': this Mac only, never remote hosts
  self: { pid: number; pgid: number }   // atlas-api, so clients can mark it
  system: SystemMemory
  groups: ProcessGroup[]      // sorted: flagged first, then project, then rss desc
  processes: ProcessInfo[]
}
```

**`POST /api/processes/stop`**

```ts
interface StopRequest {
  targets: { pid: number; startedAt: string }[]   // 1..200, from any snapshot
  tree?: boolean      // include every descendant (ppid closure) in the fresh snapshot
  force?: boolean     // SIGKILL survivors 5 s after SIGTERM (identity re-checked first)
  dryRun?: boolean    // resolve + check only, no signal
}
type StopRefusal = 'pid-reused' | 'protected-pid' | 'other-user' | 'atlas-api' | 'launchd-job' | 'zombie'
interface StopResult {
  pid: number
  startedAt: string
  status: 'would-stop' | 'stopped' | 'killed' | 'still-running' | 'gone' | 'refused'
  refusal?: StopRefusal
  label?: string      // launchd label for 'launchd-job'
  tree?: number[]     // descendants pulled in by this target
}
interface EndingProcess { pid: number; ppid: number; pgid: number; startedAt: string; kind: ProcessKind; name: string; command: string }
interface StopResponse {
  dryRun: boolean
  generatedAt: string
  results: StopResult[]                 // one per target, request order
  wouldEnd: EndingProcess[]             // every pid that gets (or would get) SIGTERM: targets + tree, after checks
  skipped: { pid: number; name: string; refusal: StopRefusal; label?: string }[]   // tree members not signalled
}
```

Errors: malformed body gives 400 `{ error }`. A request where every target is refused still returns 200 with per-target results, so the CLI exits non-zero by inspecting `results`. The write guard from workstream 2 (`hooks.server.ts`) covers this route like every other non-GET `/api/*`.

**Snapshot module and `/api/ports/listeners` on top of it**

```
getSnapshot(fresh = false): Promise<Snapshot>     // 2 s TTL, one shared in-flight promise
  parallel: ps · netstat (listSockets) · launchctl list · sysctl
  → parse + classify
  → parallel: lsof cwd,1 on candidates ∪ listener pids · session names for new pid@start keys
                · docker ps only if a docker socket exists
  → attribute, group, flag
Snapshot = { generatedAt, procs: Map<pid, ProcessInfo>, groups, sockets: Socket[], docker: Map<port, container>, system }
```

`getListeners(fresh)` becomes a pure projection of the same snapshot:
- `ownersByPort(snap.sockets, process.pid)`, then per row `proc = snap.procs.get(pid)`: `command`, `cwd`, `project` come from the snapshot, replacing `processDetails()`'s extra lsof + ps.
- Group logic unchanged: service, then project, then docker, then system.
- Each `Listener` additionally carries `startedAt`, `pgid` and `kind`, so its row can link to its process row and send a safe stop.
- `/api/ports/listeners` keeps its `{ listeners, updatedAt }` shape (`updatedAt` = `generatedAt`).
- The 10 s listener cache is gone; the snapshot's 2 s cache serves both pages and the CLI.

**Secret redaction (same module, before anything leaves the server).** Args carry secrets on this Mac today: `mcp-remote … --header Authorization: Bearer <token>`, and deckhand's ssh remote command `DECKHAND_TOKEN=<token>`. `/api/ports/listeners` already returns full args, and decision 1 opens the console read-only off-LAN. Redact in `command` before caching:

```ts
// Values that are credentials, wherever they appear in a command line.
const SECRETS: [RegExp, string][] = [
  [/(\bBearer\s+)\S+/gi, '$1REDACTED'],
  [/(--?(?:api[-_]?key|token|secret|password|passwd|access[-_]?token|client[-_]?secret)[= ])\S+/gi, '$1REDACTED'],
  [/\b([A-Z][A-Z0-9_]*(?:TOKEN|SECRET|PASSWORD|API_KEY)=)\S+/g, '$1REDACTED'],
  [/(\w+:\/\/)[^/\s:@]+:[^/\s@]+@/g, '$1REDACTED@'],
]
```

**CLI mapping (workstream 6):**
- `atlas ps [--project P] [--kind K] [--all] [--json]` calls `GET /api/processes?project=&kind=&all=1`. The table columns are `PGID KIND NAME PROJECT PORTS CPU RSS UP FLAGS`, one row per group. `--json` prints the response verbatim.
- `atlas kill <pid | :port | project> [--tree] [--force] [--dry-run] [--yes]`:
  1. Resolve targets client-side from `GET /api/processes?all=1`: a pid gives itself; `:port` gives the processes whose `ports` include it; a project gives the primaries of its groups with `tree`.
  2. `POST …/stop {dryRun:true}` and print `wouldEnd` + refusals.
  3. Confirm on a TTY, or require `--yes` without one.
  4. Post again without `dryRun`.
  5. Exit 1 if any result is `refused` or `still-running`.
- `atlas stop [path]` stays `DELETE /api/run`.

**Files (atlas-api):** `src/lib/processes/{snapshot,classify,groups,stop,session,types}.ts` (6 files, at the dir-check limit), tests `classify.test.ts` and `groups.test.ts`. Copy the fixture into `src/lib/processes/ps-fixture.txt`, because atlas-api is its own repo and can't read `.orchestrate/`.

---

## 7. Found along the way

- `listeners.ts` runs `/opt/homebrew/bin/docker ps` on every scan; with Docker down it costs 140–320 ms of the ~240–280 ms `listeners-fresh` baseline. A socket check removes it today.
- atlas-api (pgid 977) spawned 15 short-lived `(bash)` children in 15 s (13:02:13–13:02:28; caught by a 75-sample poll, so a lower bound), while `bun /tmp/perfbench/series.ts http://127.0.0.1:47891/ 40 2000` (another agent's baseline run) was hitting `/`. Worth checking which route shells out per request; it may be the bench rather than steady state.
- Swap: 7.9 GB of 9.2 GB used, pressure level 1 (normal). Load average peaked at 334 on 10 cores during this run.
- The `com.jurrejan.suno-preview` server (`preview_server.py`, port 47895 per `daemons.json`) runs **outside** launchd (ppid 1, own pgid, no label), so the daemons page will show the job stopped while the port is held.
- Every Claude session spawns its own Consult-User-MCP node, `uv run` deckhand-mcp (uv + python) and often mcp-remote/channels: 4–6 processes per session, ~13 sessions alive. This is real memory, and the agent rows will show it.
- `bd init` (1.2.1) in a scratch repo writes AGENTS.md, CLAUDE.md, `.claude/settings.json`, `.codex`, `.cursor` and a local `core.hooksPath` (copied from `~/.git-hooks`). Global files were untouched (checked mtimes). Worth knowing before anyone runs it in a real project.
