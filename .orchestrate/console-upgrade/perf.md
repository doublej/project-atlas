# Page weight and server latency (read-only research, 2026-10-01)

Measured against the live daemon (pid 977, build of atlas-api ~70a2bd1+, bun 1.3.8) on 127.0.0.1:47891.
**The Mac was saturated by other agents during these measurements (load average 50-280 on 10
cores, playwright and python jobs).** Wall times swing 10x. The notes therefore quote the
quiet minimum and, where possible, CPU time (`ps -o time` delta or `/usr/bin/time` user+sys),
which does not depend on load. Scratch scripts are in `/tmp/perfbench/`, and the saved HTML is in `/tmp/perf-root.html`.

## 0. Target check today

| target | today | after the plan (estimate) |
|---|---|---|
| `/` < 300ms | quiet min 126-136ms; p50 under load 0.25-0.5s; stale window 1-30s | ~40-60ms quiet; no stale storms |
| `/` < 500KB | **1,453,663 B** | ~390-445KB |
| listeners fresh < 150ms | 0.24-0.55s | ~70-90ms |
| listeners warm < 30ms | 11-40ms, with outliers up to 0.57s when the event loop is blocked | ~1-5ms server, <30ms wall once `/` stops blocking the loop |

## 1. `/`: where the 1.45MB comes from

| part | bytes | share |
|---|---|---|
| `<head>` (theme bootstrap, 7 CSS links, fonts) | 3.7K | 0.3% |
| non-row markup (nav, toolbar, dialogs) | 49.7K | 3.4% |
| **SSR table rows**: 611 `<tr>` × ~1,326 B | **810K** | 56% |
| **hydration data script** (`devalue.uneval` of the full ScanResult) | **589K** | 41% |
| linked assets (not part of the curl size, immutable-cached) | CSS 29K + JS 163K | n/a |

The daemon serves no compression (adapter-node). gzip would give 137KB and brotli 86KB on the wire,
but the target is measured without Accept-Encoding, so compression cannot meet it.

**Rows: 611**. That is every project, including 28 `archived` and 113 remote ones (m2 498, fractal + ubuntu 113).
`/api/projects` hides archived projects by default. The page does not.

### What a row's 1,326 B is made of (sums over 611 rows)
svelte scope-class tokens 159K (19.6%), run button incl. svg 98K (12.2%), hydration comments 86K (10.6%),
inline svg icons 81K (10%), path cell 74K, title attrs 66K, description span 60K, git dot 48K, `<time>` attrs 44K.
None of these is waste on its own. The per-row cost is what Svelte SSR produces. **The lever is the row count, not the row.**

### Which Project fields dominate the data script (cache JSON, 612K of projects)
justRecipes **172K (28%)**, scripts **96K (16%)**, description 46K, path 34K, relativePath 27K,
modifiedAt 24K, flow 22K, slug 22K, agentFiles 17K, claudeSessions 14K, claudeSetup 13K,
readme 13K (a `__HAS_README__` marker, not the text), deploy 5K, umami 4K, domains 1K.
`readme`, `claudeSetup`, `deploy` and `domains` are small. **justRecipes and scripts are 44% and are used only by the
opened row's action menus** (`ProjectActions` → `getDynamicActions('run-script'|'run-just')`).

What the collapsed table line plus the filters/search actually read:
`name description path relativePath framework type runner host isLocal domains agentFiles.claude.tokens
modifiedAt devCommand slug git gitBranch` + filters `hasJustfile readme promotion`.
Serialized with devalue (measured):

| projection | uneval bytes |
|---|---|
| full (today) | 588,851 |
| row + filter fields (B) | **257,330** (−331K) |
| B + template/alsoOn/port/archived | 266,185 |
| B without `path` (derive from host root + relativePath) | 224,954 (fragile, not recommended) |

### Server cost of `/` (quiet)
- `scan()`: readFile + JSON.parse of the 605K cache: **8-20ms on every call**.
- `discoverTemplates(ATLAS_TEMPLATES_DIR)`: **65-395ms on every `/`**. It reads all ~1,200 template files to build
  variable references, but the page only needs `{family/name: _version}`. A versions-only read
  (findCookiecutters + parse 20 `cookiecutter.json`) takes **1-17ms**.
- `devalue.uneval` of the full data: 50-90ms (stringify for `__data.json`: 38-60ms).
- SSR of 611 rows: `/` minus `/__data.json` ≈ 75ms quiet. Under load the daemon spent 370-830ms CPU per `/`
  vs 80-170ms per `/__data.json`. **SSR plus uneval is synchronous**, so it blocks the event loop: `/api/health` (an empty
  handler) stalled up to 13.9s, always in the same second as a `/` render.

### The stale storm (the p90/p99 killer, not page weight)
Once the cache is older than 60s, one page view does **all** of this:
1. server `scan()` → `revalidate()` → `performScan` + `enrichCacheWithGit` (≈400 repos × `sh` + 4 `git` = ~2,000 spawns), and
2. client `onMount` → `if (data.stale) refreshInBackground()` → `POST /api/refresh`, which runs a **second, unguarded,
   forced** `performScan`, `refreshHosts({ force: true })` (SSH to fractal + ubuntu), and **another** `enrichCacheWithGit`.

During those windows `/` took 1-30s (series in §5). Every client that polls (Raycast, picker Ctrl+R, CLI) re-arms this every 60s.

### What 70a2bd1 ("projects page renders rows in SSR") was for
Before it, every `/` probed git for all ~560 projects (28 concurrent `/api/git` batches, ~560 spawns), which held browser
connections for ~40s (load event at 102s). Rows came from `$state` filled by an `$effect`, so the page painted "No projects" and then
re-rendered 500+ rows. The fix: `projects` is a writable `$derived(data.projects)`, so rows are in the SSR HTML and hydrate
in place, and git state comes from the cache (`p.git`/`p.gitBranch`). **Keep both properties**: the first screen must be in the SSR
HTML and identical after hydration, and nothing may probe git per load.
Side note: the SSR git dots still say `loading` because `gitStatus` is seeded in `onMount`. Seeding it from `data` would make the SSR
dot real (free, no weight effect).

## 2. `/system` (~0.8s) and `/disk` (~0.36s)

**/system** awaits `Promise.all([scan(), readConfig(), fetch('/api/daemons')])`. scan is 8-20ms and readConfig is trivial.
**`/api/daemons` is the whole cost**: for each of 31 registry daemons it does readFile(plist), then in parallel
`launchctl print gui/501/<label>` (31 spawns) and, for the 8 with a port, `lsof -i :<port>` (8 spawns, without `-nP`, so
it resolves names and walks every process). That is 39 concurrent child spawns from the daemon. Measured: `/api/daemons` 714-2,228ms
in-daemon (min 141ms quiet). The same 31 `launchctl print` take 66-157ms from a shell, the 8 `lsof -i` 145-215ms. `/system` CPU is only
30-80ms, so it is spawn and wait time.
Replacements, both already available:
- `launchctl list` (one call, ~0-10ms) gives `PID Status Label` for every loaded job, which is the pid and last exit that `printLabel` parses.
  An absent label means stopped, the same as print's non-zero exit. "Never exited" reads 0 instead of null (minor).
- `listSockets()` in `ports.ts` (one `netstat -anv -p tcp`, 0-30ms) → a `Set` of listening ports → `portInUse = set.has(port)`.
Expected: `/system` ≈ 30-50ms.

**/disk** awaits 7 `atlas disk … --json` spawns (each a bun process, ~50ms startup). Per command (warm): analyze 83-272,
scan 87-277, config 52-111, schedule 76-101, doctor 78-88, recover 55-68, **archives list 374-560ms, cold 19.4s**
(it lists the iCloud Drive `Dev Archive/`; fileproviderd was at 59% CPU). All 7 in parallel take 385ms, so the page waits on
`archives list`. Fix: return `archives` as an un-awaited promise from `load` (SvelteKit streams it), so the TTFB drops to ~100-150ms
and the archives card fills in. Or cache it in-process until a disk job ends. Page weight is 187K (fine).

## 3. `scan()` re-parses the cache on every call

There is **no in-memory index today**. Every caller does readFile + JSON.parse of 605K (8-20ms + ~3MB garbage):
`/` (+page.server), `/system`, `/templates`, `/api/projects`, `/api/run` (POST + DELETE), `/api/ports/allocate`,
`/api/ports/audit`, `/api/categories`, `/api/hostnames`, `listeners.ts` (each fresh snapshot). `updateCachedPort` parses
its own copy (it writes, so it must). Writers: `scan()` cold path, `enrichCacheWithGit` (revalidate, /api/refresh),
`updateCachedPort`, all through `writeJsonAtomic` (tmp + rename).

**One accessor, in scanner.ts next to `scan()`** (minimal sketch):
```ts
/** The parsed cache, shared by every reader until the file changes. Read-only: never mutate it. */
let memo: { key: string; atlas: CachedIndex; byPath?: Map<string, Project> } | null = null

export async function readCachedAtlas(baseDir: string): Promise<CachedIndex> {
  const cachePath = join(baseDir, CACHE_FILE)
  const { mtimeMs, size } = await stat(cachePath)
  const key = `${cachePath}:${mtimeMs}:${size}`
  if (memo?.key !== key) memo = { key, atlas: JSON.parse(await readFile(cachePath, 'utf-8')) }
  return memo.atlas
}

/** The deepest catalogued local project containing `dir`: a walk up the path, O(depth) not O(projects). */
export function projectAt(atlas: CachedIndex, dir: string): Project | undefined {
  if (memo?.atlas !== atlas) return undefined // only the memoized atlas carries the index
  memo.byPath ??= new Map(atlas.projects.filter((p) => p.isLocal).map((p) => [p.path, p]))
  for (let d = dir; d.length > 1; d = dirname(d)) {
    const hit = memo.byPath.get(d)
    if (hit) return hit
  }
}
```
`scan()` swaps its `JSON.parse(await readFile(cachePath))` for `await readCachedAtlas(baseDir)`, so all callers benefit with no
call-site changes. stat-based invalidation (~0.1ms) also catches external writers (a second test instance, `bun run scan`).
Every write is a rename, so mtime changes. Building the Map costs 0.1-2ms, once per cache write.
**Risk**: the memo is shared, so a caller that mutates it corrupts every later reader. Today's `scan()` consumers only read
(`/api/projects` reassigns `index.projects` on its spread copy, which is fine). `enrichCacheWithGit`/`finalizeAtlas` mutate, but only on
fresh `performScan` results. Keep it that way (or `structuredClone` before mutating). `projectAt` replaces `listeners.ts`'
O(n) `projectFor` and is what the process-snapshot module should use (~800 procs × ~6 Map lookups).

## 4. Fresh `/api/ports/listeners` (0.24-0.55s), step by step

`scanListeners`: `netstat` → then in parallel [`lsof cwd -p LIST` **then** `ps -ww -o pid=,args= -p LIST` (serial)] ‖ `docker ps` ‖
`scan()` ‖ `listHostnames()`. 34 ports, 27 pids.

| step (3 runs each, from bun) | ms | /usr/bin/time real (user+sys) |
|---|---|---|
| `netstat -anv -p tcp` | 22-64 | 0.00-0.01s |
| `lsof -b -w -a -d cwd -p LIST -Fpn` | 45-59 | 0.02s |
| **`ps -ww -o pid=,args= -p LIST`** | **330-1,439** | **0.11-0.13s (sys 0.09-0.11)** |
| `ps -axww -o pid=,args=` (all ~800 procs) | 98-206 under load | **0.05-0.07s (0.04s CPU)**, so ~0.04s is confirmed |
| `ps -axww -o pid=,ppid=,pgid=,%cpu=,rss=,args=` | 83-163 | 0.05-0.06s |
| **`docker ps`** (daemon not running) | **150-540** | 0.12-0.40s, just to fail |
| scan() cache parse | 8-16 | n/a |
| `.atlas-hostnames.json` read | 0-1 | n/a |
| `lsof -d cwd` over ALL procs | 631-1,365 | 0.15s (0.13 sys) |
| `lsof -d cwd -p <160 non-system pids>` | n/a | 0.02s (catches all 114 cwds under ~/dev) |

Counter-intuitive: on macOS `ps -p <list>` is **2x slower than `ps -ax`** (sys time per pid). The critical path today is
netstat + max(lsof+ps ≈ 150, docker ≈ 120-400).

**Docker detection** is "run `/opt/homebrew/bin/docker ps` and treat empty stdout as no docker". The CLI is installed (Homebrew 28.5.1,
plus `/usr/local/bin/docker`). Contexts: `desktop-linux` (current) → `~/.docker/run/docker.sock`, `colima` →
`~/.colima/default/docker.sock`, `default` → `/var/run/docker.sock`. **None of these sockets exists** (also checked
`~/.orbstack/run/docker.sock`, `~/.rd/docker.sock`, Docker Desktop's `docker.raw.sock`). Docker is not running, so every fresh snapshot pays
120-540ms to learn that. Fix: `existsSync` over those socket paths (or `DOCKER_HOST`) before spawning, which costs ~0ms when absent.

After: netstat ‖ `ps -axww` in parallel (~50ms) → `lsof cwd -p` (~20ms) → memo cache + `projectAt` (~0ms) → **~70-90ms fresh**.
Warm stays the existing 10s TTL promise (~1ms server). It only reaches <30ms wall once `/` stops blocking the event loop (§1).

**Process snapshot module** (same recipe): `ps -axww -o pid=,ppid=,pgid=,%cpu=,rss=,args=` (~50ms, 0.04s CPU) ‖ netstat; cwd only
for non-system pids (args not under `/System /usr /sbin /Library/Apple /Applications`, ~160 pids, 0.02s), with a pid→cwd map
keyed by `pid+args` so a warm refresh only lsofs new pids; path → project via `projectAt`; a module-level TTL promise like
`getListeners`. Expect ~70-80ms fresh and ~1ms warm.

## 5. Raw series (for the record)
- `/` every 2s for 80s: stale window 4.4s / **29.6s** / 10.3s / 9.6s, fresh window 126-1,800ms (`/tmp/perfseries.log`).
- health vs page: `/api/health` p50 12ms, p90 851ms, p99 2.9s, max **13.9s**, with spikes aligned to `/` renders (`/tmp/perfdual.log`).
- CPU per request (ms, 8 runs): `/` 370-4,570 (median 830), `/__data.json` 80-450 (170), `/system` 30-80, `/disk` 30-560,
  `/api/health` 0-20 (`/tmp/perfcpu.log`).
- Quiet minimums: `/` 136, `/__data.json` 60, `/api/projects` 14, `/system/__data.json` 133, `/api/daemons` 141 (`/tmp/perfmin.log`).
- Final 3× curl (load ~80): `/` 0.19-0.38s 1,453,835B; listeners fresh 0.29-0.55s, warm 0.026/0.57/0.040s; `/system` 0.31-0.46s;
  `/disk` 0.79-1.49s 186,746B.

## 6. Ranked plan (by saving)

1. **Cap SSR rows** in `ProjectTable`: `let limit = $state(100)`, `onMount(() => (limit = Infinity))`, `{#each sorted.slice(0, limit)}`.
   **−680K** (810K → ~133K) and ~−80% SSR CPU and event-loop block. The first ~3 screens are SSR'd and hydrate in place, so
   70a2bd1's first paint is kept. Rows below the fold are appended after mount (never a replace). Header counts still use `filtered.length`.
   N=60 gives −730K. *(~30 min)*
2. **Slim the page data** to the row+filter projection (B) in `+page.server.ts`. **−331K** (589K → 257K) and ~−40ms uneval.
   The full record loads lazily from the existing `GET /api/projects?includeArchived=true` (one 620K fetch, `max-age=60`) the
   first time a row opens or the view switches to flat/nested (those render `ProjectRow` for every row). The `Project`
   type needs a `ProjectSummary` pick (or the detail snippet awaits the full record). *(~1h)*
   → 1+2 together: **~445K at N=100, ~390K at N=60**. Neither alone meets 500K.
3. **Stop the stale storm**: drop `if (data.stale) refreshInBackground()` in `+page.svelte` onMount (the server already
   revalidates, one at a time), or route it through the same `revalidating` guard instead of `forceRefresh` + forced SSH sweep.
   Removes a second full walk, a forced SSH sweep and ~2,000 git/sh spawns per stale view. This is the biggest p90/p99 latency win. *(~15 min)*
4. **Versions-only template read** for `/` (export `findCookiecutters`, read `_version` only): **−60…390ms per `/`**. `/templates`
   keeps the full `discoverTemplates`. *(~15 min)*
5. **`readCachedAtlas` + `projectAt` memo** (§3): −8-20ms and ~3MB garbage per `scan()` caller, O(depth) path→project for listeners and
   the process snapshot. *(~30 min + a vitest for invalidation and walk-up)*
6. **/api/daemons**: one `launchctl list` + one `listSockets()` instead of 31 + 8 spawns: `/system` 0.8s → ~50ms. *(~30 min)*
7. **listeners**: socket-exists docker gate (−120-540ms), `ps -axww` instead of `ps -p LIST`, run in parallel with `lsof`/netstat
   (−80-130ms): fresh 0.24-0.55s → ~70-90ms. *(~20 min)*
8. **/disk**: stream `archives list` (un-awaited promise in `load`): TTFB 0.36s → ~0.1-0.15s, and no more 19s cold iCloud stalls on
   first paint. *(~20 min)*

Expected `/` after 1-5: ~40-60ms quiet, ~390-445KB.
