# Dev hostname assignment mechanism

## 1. POST /api/run path
File: `atlas-api/src/routes/api/run/+server.ts`

1. Body: `{ path, command, runner, type }` (L12). 400 if `path`/`command` missing.
2. `resolveLocal(path)` guard (L21-23) — refuses any path not in this machine's catalog *before* port allocation or spawn, so a remote-host project can never get here.
3. Kills any prior process for that path via process-group kill (L29-37).
4. `scan(DEV_FOLDER)` (L39) — cached read, no fs walk. Finds `project` by exact `path` match.
5. Port: `project.port ?? allocatePort(atlas)` (L41). If the project had no `.atlas` port yet, `setPort(path, port)` (writes `.atlas`) + `updateCachedPort` (patches `.atlas-cache.json`) run (L42-45), then the in-process allocation hold is released.
6. Command/args built from `type`/`runner` (L48-66): `just`, `uv run`, or npm/bun/yarn/pnpm with `--port <port> --host 0.0.0.0` appended (npm needs `--` first). No runner branch exists for anything else (no python/uv without `uv`, no rust/go/swift `devCommand='build'` case — those never reach a spawnable branch usefully).
7. `spawn()` wrapped in try/catch (sync ENOENT) + `.on('error')` (async) so a bad runner never crashes the daemon (L68-91).
8. `runningProcesses.set(path, {port, pid})`.
9. `ensureRoute({slug: project.slug, path, port, devPublic: project.devPublic})` is called **only if `project` was found** in the cached scan (L95-97) — a path not yet in the cache gets no hostname at all, just `{port, pid, url: localhost:<port>}`.
10. Response merges `{port, pid, url}` with whatever `ensureRoute` returned (`{local, remote}` or `null`).

`ensureRoute` (`atlas-api/src/lib/caddyDev.ts:177-210`):
- Skips the NAS push entirely if `existing.port === port && existing.devPublic === devPublic && existing.nasSynced` (L188-194) — idempotent, so repeat `atlas run` calls are free.
- Otherwise renders a Caddyfile block (`renderSiteBlock`, L71-106: local block gated by `admin_ip_check`, remote block gated by `basic_auth` unless `devPublic`) and calls `pushToNas` (L140-151): SSH (`ssh nas bash -s`, 8s timeout, L108-134) writes `<slug>-atlas.caddy` into `/share/CACHEDEV1_DATA/Container/caddy/etc/sites`, then `caddy validate` + `caddy reload` on the `caddy-porkbun` container.
- Registry entry is written **regardless of SSH success** (`nasSynced: synced`, L199-206) — so a project always gets a `.atlas-hostnames.json` row on first run, but `local`/`remote` URLs are only returned (and only listed by `GET /api/hostnames`, which filters `nasSynced`) when the push actually succeeded.
- **NAS unreachable**: `pushToNas`/`removeFromNas` return `ok:false`, a `console.warn` is logged, `ensureRoute` returns `null`, `/api/run`'s response has no `local`/`remote` fields — caller falls back to `http://localhost:<port>`. The registry entry persists with `nasSynced:false`, so a later successful run for the *same port/devPublic* will still re-push (the port-changed-or-not-synced check at L188-194 catches it) — it is not silently stuck.
- Writes are serialized by `withRegistryLock` (a mutex, `createMutex()` in `mutex.ts`) because the registry file read-modify-write is not atomic.

## 2. Slug derivation
`slugify()` (`scanner.ts:184-195`): lowercase, non-alnum→`-`, trim dashes.

Default slug source is **`relativePath`**, not the bare folder name (`scanner.ts:863`, `slug: info.slug ?? slugify(relPath)`) — comment at L184-189 explains why: two projects both named `frontend` in different categories would otherwise collide on the same hostname and steal each other's Caddy route. This is why the two current registry keys are `web-eink` and `games-spplx` — the category prefix is baked into the slug, not decoration.

`.atlas` `slug` override (`scanner.ts:725`): `if (typeof meta.slug === 'string' && meta.slug) info.slug = slugify(meta.slug)` — lets a project claim a shorter/cleaner hostname than its category/path would generate, still run through `slugify` so it can't inject anything the DNS label can't hold.

**Migration hazard**: the default is a function of *directory position*, not identity. Renaming/moving a project's folder (or a category) silently changes its slug on the next scan, orphaning its old NAS `.caddy` file (nothing removes it — see §6) and creating a fresh registry entry with a different hostname on next run.

## 3. Every `.atlas` field the scanner/run route understand
Read in `getProjectInfo` (`scanner.ts:718-741`) and the branch-flow reader (`scanner.ts` around L555-558) and umami (`scanner.ts:627-628`):

| Field | Type | Effect | Default |
|---|---|---|---|
| `archived` | bool | `info.archived = true` | unset |
| `port` | number | `info.port` — pins the dev port; skips `allocatePort` in `/api/run` | none — allocated from 4100-4999 on first run |
| `devPublic` | bool (must be `=== true`) | `info.devPublic = true` → NAS `atlas.remote` block skips `basic_auth` | `false` |
| `slug` | string | overrides default `slugify(relativePath)` | derived from `relativePath` |
| `domain` / `domains` | string / string[] | merged into `info.domains` (manual override, listed *before* detected domains) | detected from project files |
| `umami` | string / string[] / `{websiteIds, instance}` | overrides detected `UmamiInfo` | detected via ripgrep |
| `type`, `description`, `framework` | strings | only applied as a **fallback** when nothing was detected (`if (!info.type) {...}`, L733-738) | detected |
| `flow` | `{policy, trunk, integration}` | overrides the derived `FlowPolicy` | derived from git remote owner / `develop` branch presence |

Not in `.atlas`: runner, devCommand — always detected from lockfiles/package.json scripts (`devCommand` picks `dev` > `start` > `serve`, `scanner.ts:660-662`), never overridable.

## 4. Callers of POST /api/run, and who bypasses it
- **`atlas run [path]`** (`atlas-cli/src/commands/run.ts:24-28`) — the only CLI path that calls `POST /api/run`. Dies if `project.devCommand` is unset (L22) — a project whose scripts detector didn't find `dev`/`start`/`serve` gets nothing.
- **Web UI** `runDev`/`runScript`/`runJust` (`atlas-api/src/routes/+page.svelte:126-140`) all go through `api.runDevServer`/`runScript`/`runJustRecipe`, which POST `/api/run` — these register hostnames.
- **`atlas jump --run <cmd>`** (`atlas-cli/src/commands/search.ts:71-93`) — does **not** call the API at all. It hands the parent zsh shell a literal `cd <path> && <cmd>` line via `shellExec` (evaluated by the `atlas()` zsh wrapper). This runs in the user's own shell, on whatever port the command happens to bind, with **no hostname registration**.
- **Raycast "Run Dev Server" action** (`atlas-browser/src/list-projects.tsx:168-177`, wired at L294 `case "run-dev"`) — also bypasses the API: `openInITerm(project.path, \`${runner} ${devCommand}\`)`. Same for the per-script and per-just-recipe submenus (L513-556) — all `openInITerm`, none call `/api/run`.
- **Manual `bun run dev` / `just dev`** — obviously bypasses everything.

**Conclusion for the migration plan: only `atlas run` (CLI) and the atlas-api web UI's run buttons register a dev hostname today.** Raycast's run action and `atlas jump --run` are iTerm/shell passthroughs and never touch `ensureRoute`. A bulk migration driving 100 projects through Raycast or `jump --run` would register **zero** hostnames; it must go through `POST /api/run` directly or via `atlas run`.

## 5. Preconditions and failure modes
To get a hostname a project must, at scan time:
- Be `isLocal` (on `m2`, resolves under `resolveLocal`) — `/api/run` 400s otherwise (L21-23).
- Be present in the **cached** scan atlas by exact `path` (`atlas.projects.find(p => p.path === path)`, L40) — a brand-new project not yet scanned gets `project === undefined`, so `/api/run` still spawns something (port allocated ad hoc) but **skips `ensureRoute` entirely** (L95-97 ternary) — no error, no hostname, silent.
- Have a `devCommand` (npm/bun/yarn/pnpm scripts `dev`/`start`/`serve`, or be spawned via `just`/`uv`) — the CLI (`run.ts:22`) refuses without one; the raw API doesn't enforce this (caller supplies `command`), so a wrong/empty `command` just spawns something that likely errors, and the port+registry entry still get written first.
- Have a resolvable `slug` — always true (derived or `.atlas`-overridden), never blocks.

Failure modes:
- **No runner detected** — falls through to the `npm` default (`runner === 'bun' ? ... : ... : 'npm'`, L58) even if the project isn't Node — wrong binary, `spawn` ENOENT, caught and returned as a 500. `ensureRoute` runs regardless of whether the child process actually bound the port (fire-and-forget spawn, no health check) — **a hostname can be registered and pushed to the NAS pointing at a port nothing is listening on.**
- **No port and range exhausted** — `allocatePort` throws `No available port in range 4100-4999` (`ports.ts:93`), unhandled in `+server.ts` (no try/catch around the `await allocatePort` call) → unhandled rejection → SvelteKit 500.
- **Hardcoded port in the dev script differing from `.atlas`** — `/api/run` always appends `--port <port> --host 0.0.0.0` from the allocated/`.atlas` port (L62-65) for the npm/bun/yarn/pnpm branch, so the CLI flag wins over any hardcoded `vite.config` port. But for `just`/`uv` (L51-56), **no port flag is ever injected** — the underlying command's own hardcoded/absent port is what actually binds, while the registry/Caddy route point at the allocated port regardless. Silent mismatch → 502 at the reverse-proxy hop.

## 6. GET /api/hostnames and unregister
`atlas-api/src/routes/api/hostnames/+server.ts:5-7` → `listHostnames()` (`caddyDev.ts:231-242`): reads the registry, **filters to `entry.nasSynced` only** (a failed-push entry is invisible here even though it's on disk), returns `{slug, path, local, remote}[]`.

Unregister paths exist but nothing in the run/hostnames routes calls them:
- `removeRoute(slug)` (`caddyDev.ts:213-222`) — SSHes `rm -f <slug>-atlas.caddy` + validate/reload, then deletes the registry entry. Per its doc comment it's used by the **archive route**, confirming archiving a project cleans up its NAS `.caddy` file and registry row.
- `removeRouteByPath(path)` (`caddyDev.ts:225-229`) — same, keyed by path.
- **No cleanup on rename/move/slug-change** — `POST /api/rename`/`/api/move` were not found calling `removeRoute*`. Renaming a project (which can change its default slug, §2) leaves the old `<old-slug>-atlas.caddy` file on the NAS and the old registry row behind as orphans.

## 7. Bulk-migration constraints
- **Mutex, not a rate limit**: `withRegistryLock` (`caddyDev.ts:167-168`) serializes `ensureRoute`/`removeRoute` calls *within this daemon process* — it does not throttle SSH/NAS load. Each first-time `ensureRoute` opens a fresh `ssh nas bash -s` (8s timeout) and reloads the shared production Caddy container. 100 sequential first-runs = 100 SSH round-trips + 100 `caddy reload`s with no batching — the risk is hammering a shared production Caddy instance with reloads, not concurrency corruption (the mutex already prevents that).
- **Port range 4100-4999 (900 slots)** (`ports.ts:9`) — plenty for ~100 projects. `allocatePort` (`ports.ts:78-93`) does a live `lsof` probe per untested candidate, serialized by its own mutex; reserved ports are skipped without a probe, so in practice this is fast.
- **Collision surface**: `reservedPorts()` (`ports.ts:45-51`) unions daemon ports (`shared/daemons.json`) + every already-scanned project's `.atlas` port + this-process's in-flight allocations. A project with a hardcoded `.atlas` port *outside* 4100-4999 (or colliding with a daemon) isn't caught by `allocatePort` (which only walks the atlas range) but will surface in `/api/ports/audit`'s `collisions` (`ports.ts:124-151`) — run `atlas ports` before and after a bulk migration.
- **Cache staleness**: `/api/run` reads a *cached* atlas (60s TTL). A project scaffolded/renamed moments before migration may not appear yet → `project === undefined` → silently skips `ensureRoute` (§5). Force `POST /api/refresh` (or wait out the TTL) before driving `/api/run` for newly-added/renamed projects.
- **No batch/bulk endpoint, and `/api/run` spawns a live dev server** — not just hostname registration. Migrating ~100 projects through it means ~100 concurrently running dev server processes on this Mac unless something stops them after (`DELETE /api/run` exists per-path). `ensureRoute` has no HTTP entry point independent of `/api/run` — a hostname-only bulk migration would need a new route, or accept the standing dev-server cost and clean up with `DELETE /api/run` per project afterward.

## 8. Follow-up: runner/port detection, hostname-only path, pacing

### 8.1 Runner and port detection
- `runner` never becomes `'just'`. `detectRunner()` (`scanner.ts:196-215`) only checks lockfiles (`bun.lock(b)`→bun, `yarn.lock`→yarn, `pnpm-lock.yaml`→pnpm, `package-lock.json`→npm, `uv.lock`→uv) and is fully independent of justfile presence — `info.runner = runner` at `scanner.ts:786`.
- `hasJustfile`/`justRecipes` (`detectJustfile`, `scanner.ts:217-236`, applied `scanner.ts:793-796`) is a **separate, additive** field, never overriding `devCommand`. `devCommand` only comes from `pkg.scripts.dev > .start > .serve` (`scanner.ts:660-662`) or `'build'` for Go/Swift (`scanner.ts:712`ish). A project can have both a `devCommand` and `justRecipes` simultaneously; the caller picks which to run by setting `type: 'just'` in the `/api/run` body (only the web UI's `runJustRecipe`, `atlas-api/src/lib/browser/api.ts:76-83`, ever does this — it also omits `runner` entirely for that call, L77-81). No code path lets a justfile recipe silently supersede `pkg.scripts.dev`.
- `Project.port` has exactly two writers: `.atlas` `meta.port` at scan time (`scanner.ts:723`), or `setPort`/`updateCachedPort` after `/api/run` allocates one (`scanner.ts:1223`, `:1242`, called from `+server.ts:42-45`). There is no third source — this is why only 17/458 projects show a port: only projects that have already been `atlas run`/web-UI-run at least once, or that hand-declare `.atlas` `port`, have one. An unrun project has `port: undefined` until first run.

### 8.2 Smallest hostname-only assignment path (no spawn)
Sketch for `POST /api/hostnames` (assign) reusing existing pieces, none of which need to change:
1. Body `{ path }`. Guard with `resolveLocal(path)` — same check as `+server.ts:21-23`.
2. `scan(DEV_FOLDER)` (cached) → find `project` by `path` (`+server.ts:39-40`). Unlike `/api/run`, **404 if not found** instead of silently skipping — this route's whole job is the registration, so a missing project must be an error, not a no-op.
3. `port = project.port ?? await allocatePort(atlas)` (`ports.ts:74`). If newly allocated: `await setPort(path, port)` + `await updateCachedPort(DEV_FOLDER, path, port)` + `releaseAllocatedPort(port)` — the exact three calls at `+server.ts:42-45`, lifted verbatim (no spawn step in between needed).
4. `const hostnames = await ensureRoute({ slug: project.slug, path, port, devPublic: project.devPublic })` — reused as-is from `caddyDev.ts:177-210`, zero changes.
5. Return `{ slug: project.slug, port, ...(hostnames ?? {}) }`, 502 (or `{ registered: false }`) if `hostnames === null` (NAS push failed) so the caller can distinguish "port reserved, NAS not synced" from success.

Matching `DELETE /api/hostnames` (or `atlas hostnames unassign <path>`), for cleanup after rename/move:
1. Body `{ path }` (old path, captured *before* the rename/move completes).
2. `await removeRouteByPath(path)` — reused as-is from `caddyDev.ts:225-229` (already used by the archive route per its own doc comment).
3. Wire this call into `POST /api/rename` and `POST /api/move` (today neither calls it — this is the gap noted in §6) so a slug change from a path change doesn't orphan the old NAS `.caddy` file and registry row.

This is the minimum: no new mutex, no new registry shape, no new Caddy logic — steps 3-4 of assign and step 2 of unassign are the exact same functions `/api/run` and `/api/archive` already call, just invoked without spawning a process.

### 8.3 Pacing
- One `ensureRoute` call that actually needs to push (`caddyDev.ts:177-210`) does: 1 SSH connection (`ssh nas bash -s`) that writes the file, then runs **two sequential `docker exec` calls** inside the same script — `caddy validate` then `caddy reload` (`caddyDev.ts:136-137`, `:108-134`). The whole thing is capped by `SSH_TIMEOUT_MS = 8000` (`caddyDev.ts:13`) — no measured wall-clock number exists in the code (never instrumented), so treat 8s as the worst case per call and budget realistically ~1-3s for a healthy NAS (SSH handshake + two docker execs).
- The reload is **global, not per-file**: `caddy reload --config /etc/caddy/Caddyfile` reloads the whole Caddyfile, which auto-imports everything in `etc/sites/` (per the comment at `caddyDev.ts:139`). Every single `ensureRoute` push reloads *all* currently-registered sites on the shared production Caddy instance, not just the one being added. `validate` runs first and is a separate `docker exec`, so a malformed block written by a bad slug would fail validation and abort before reload — but a `set -eu` script means the whole SSH round-trip fails, `ok:false`, and the *newly written* file is left in place on the NAS regardless (no rollback of the `cat >` step) until the next successful push overwrites or removes it.
- Sizing ~100 registrations: idempotent skip (`caddyDev.ts:188-194`) doesn't help here since these are first-time registrations — expect ~100 real SSH+validate+reload round-trips, serialized already by `withRegistryLock` (no concurrency to worry about), but each one reloads production Caddy. Pace with a deliberate delay (seconds, not milliseconds) between calls rather than firing them back-to-back — the risk is reload churn on a shared instance during the migration window, not a rate limit enforced anywhere in code (there isn't one).

## 9. Follow-up: TLS certs, CA rate limits, site count, DNS

Read-only over `ssh nas`: catted the main Caddyfile, `snippets/common.caddy`, listed `etc/sites/`, tailed `docker logs caddy-porkbun`. Nothing changed on the NAS.

### 9.1 No wildcard covers the atlas hostnames — per-hostname ACME certs
`caddyDev.ts`'s `renderSiteBlock()` (L71-106) emits no `tls` block, so certs come from Caddy's default automatic HTTPS (on-demand per-hostname ACME), same as the main Caddyfile confirms. The **only** wildcard `tls` block on the NAS is in `sites/coolify.caddy`:
```
*.jurrejan.com {
	tls {
		dns porkbun { api_key {env.PORKBUN_API_KEY} ... }
	}
	...
}
```
This is a **single-label** wildcard (`*.jurrejan.com`) — it matches `foo.jurrejan.com`, not `foo.atlas.local.jurrejan.com` (two extra labels deep) or `foo.atlas.remote.jurrejan.com`. Caddy's own routing confirms it: `docker logs caddy-porkbun` shows `games-spplx.atlas.local.jurrejan.com` and `...remote...` each going through a full individual ACME flow — `tls.obtain` → `trying to solve challenge` (`http-01`, `served key authentication`) → `authorization finalized` → `certificate obtained successfully` (two separate certs, one per hostname, ~6s total for the pair, timestamps 1788443376.35→1788443382.53). **No `on_demand_tls` block or dns challenge covers `*.atlas.local.jurrejan.com`/`*.atlas.remote.jurrejan.com` — every new slug × {local,remote} = 2 fresh individual certificates.**

### 9.2 CA and rate limit
`account_id` in the logs is `https://acme-staging-v0X...` — **the NAS is currently pointed at Let's Encrypt's staging environment**, not production (staging certs aren't browser-trusted but have no meaningful rate limit). This is worth flagging on its own — if that's unintentional, `web-eink`/`games-spplx` hostnames today are serving staging (untrusted) certs. Assuming this is deliberate or gets switched to LE production before/for a migration: LE's practical cap is **Certificates per Registered Domain: 50 per rolling 7 days**, keyed on `jurrejan.com` (the registered/eTLD+1 domain — every subdomain depth counts against the same bucket, including the existing production sites already on this Caddyfile). 230 projects × 2 hostnames = 460 certs — at 50/week that's **≥10 weeks** of pure atlas-cert issuance even if nothing else on `jurrejan.com` needed a cert that week, and this Caddyfile issues certs for ~40 other unrelated sites already sharing the same weekly budget. A wildcard cert (`dns porkbun` challenge, matching the existing `coolify.caddy` pattern but for `*.atlas.local.jurrejan.com` + `*.atlas.remote.jurrejan.com`) would remove this constraint entirely and is the same mechanism already proven working on this NAS.

### 9.3 Site file count and reload timing
`etc/sites/` holds **45** `.caddy` files total; exactly **2** are atlas-managed (`web-eink-atlas.caddy`, `games-spplx-atlas.caddy`) — matches the two `.atlas-hostnames.json` entries. `docker logs --tail 400 caddy-porkbun` has no explicit "reload took Nms" line (Caddy doesn't log reload duration by default) — no measured number exists. The closest proxy: the games-spplx registration's full ACME round-trip (both hostnames) spans **~6.2s** wall-clock (first `obtaining certificate` to last `certificate obtained successfully`), which happens synchronously inside the `caddy reload` triggered by `ensureRoute`'s SSH script (`caddyDev.ts:136-137`) — the reload itself doesn't return/settle until new certs for any newly-added hostname are obtained, since Caddy's automatic HTTPS blocks startup-of-new-site until it has a cert. **This means §8.3's 8-second `SSH_TIMEOUT_MS` cap is tight**: a first-time registration's `caddy reload` can itself take several seconds for ACME alone, on top of SSH connect + `validate` + the reload command dispatch — a slow ACME responder (LE under load, or a DNS challenge propagation delay if migrated to wildcard/DNS-01) could realistically exceed the current 8s timeout and get logged as `ok:false` even though the reload eventually succeeds server-side.

### 9.4 DNS
No literal `*.atlas.local` / `*.atlas.remote` records were found or needed — `dig` from this Mac confirms a **single wildcard `*.jurrejan.com` A record** (Porkbun) resolves every subdomain depth to `94.214.125.115`, unconditionally:
```
web-eink.atlas.local.jurrejan.com     → 94.214.125.115
web-eink.atlas.remote.jurrejan.com    → 94.214.125.115
foo.bar.baz.qux.jurrejan.com          → 94.214.125.115  (arbitrary depth, never registered)
```
DNS resolution is a non-issue for the migration — every hostname atlas could ever mint already resolves before any registration happens. The bottleneck is entirely TLS issuance (§9.1-9.2) and the reload/timeout interaction (§9.3), not DNS.
