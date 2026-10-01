# Console upgrade — contracts (fixed before the fan-out)

Binding for the build agents. Change one only by reporting it; the orchestrator reconciles.

## C.1 Processes — `atlas-api/src/lib/processes/types.ts`

The TypeScript file is the contract (ProcessSnapshot, AppRow, ProcessInfo, StopRequest, StopResponse).
Design notes: `.orchestrate/console-upgrade/processes.md` (research), fixtures `ps-fixture.txt`.

- `GET /api/processes` — `all=1`, `project=`, `kind=` (comma lists), `fresh=1`, `history=1`. Default = rows with `dev: true`.
  ~2s TTL, one in-flight promise. No background timer: history gets one sample per fresh snapshot, so
  sampling happens only while a client polls.
- `POST /api/processes/stop` — `{ targets: [{pid, startedAt}], tree?, force?, dryRun? }`. Fresh `ps` every
  call, never the cache. Refusals: pid-reused, protected-pid (≤1), other-user, atlas-api (itself or its
  group), launchd-job (pid or pgid in `launchctl list`, incl. application.*; carries `label`), zombie.
  Without force: SIGTERM, wait ≤5s, report stopped / still-running. With force: SIGTERM, wait 5s,
  re-check pid+start, SIGKILL → killed. Never SIGKILL before 5s.
- `POST /api/ports/kill` and `killListeners` are removed; `/api/ports/listeners` keeps its URL and
  `{ listeners, updatedAt }` shape but is built from the snapshot (each listener gains `startedAt`,
  `pgid`, `kind`).
- Secrets: `command` is redacted server-side everywhere (Bearer …, --token/--api-key/--password/
  --secret/--access-token/--client-secret values, `*TOKEN=`/`*SECRET=`/`*PASSWORD=`/`*API_KEY=` values,
  URL credentials). With that in place `/api/processes` and `/api/ports/listeners` are readable
  off-LAN (read-only tier) — remove `ports/listeners` from the guard's LOCAL_ONLY then, and add a test
  that a DECKHAND_TOKEN-style value never appears in either response.
- `CLD_SESSION_NAME`: `ps -Eww -o pid=,command= -p <new pids>`, keep only the token per line, cache by
  pid@startedAt, never log or return anything else from that output.

## C.2 Hostnames — atlas-api (workstream 3+4 implements, atlas-cli consumes)

```ts
type HostnameState = {
  slug: string
  local: string            // https://<slug>.atlas.local.jurrejan.com
  remote: string | null    // null when no remote block exists (devPublic off or CADDY_DEV_AUTH_HASH unset)
  state: 'none' | 'syncing' | 'issuing' | 'live' | 'failed'
  nasSynced: boolean
  error?: string
}
type Holder = { kind: 'project' | 'service'; name: string; path?: string }
type DriftItem = {
  id: string               // stable across runs (kind + slug/path/file)
  kind: string             // orphan-row | slug-drift | unsynced | orphan-site-file | stale-path | port-mismatch | remote-missing | wan-drift | …
  slug?: string
  path?: string
  detail: string
  fix: { label: string } | null   // null = report only (e.g. needs JJ: NAS file not ours)
}
```

- `GET /api/hostnames/check?slug=&path=` → `{ slug, status: 'free'|'current'|'taken'|'invalid', reason?, holder?: Holder, local, remote }`.
  `current` = the slug already belongs to `path`. 200 with the verdict in `status`; 400 for a `path` outside the catalog.
- `PATCH /api/atlas` (existing, `null` clears) — `slug` must be a DNS label (1–63 of [a-z0-9-], no edge
  hyphen) → 400 `{error}`; a taken slug → 409 `{ error: 'slug "x" is taken by <project|service> <name> (<path>)', holder }`;
  `port` must be an integer 1024–65535 → 400. A slug/port/devPublic change on a project that has a
  route calls `moveRoute`/`ensureRoute`; the response is `{ atlas, hostname?: HostnameState }`.
- `GET /api/hostnames` (existing rows) gains `nasSynced` and `state`, and lists only rows the NAS serves; `?all=1` adds failed and release-pending ones (the settings dialog asks for them).
- `POST /api/hostnames { path }` (existing assign) → `HostnameState` (+ existing fields); 409 with holder on a clash (never "NAS push failed" for a clash).
- `DELETE /api/hostnames { path }` → release; if the NAS removal fails the row stays with `nasSynced:false` and the call answers 502 `{error}`.
- `GET /api/hostnames/status?slug=` → `HostnameState` (server-side tracker that polls `https://<local>` after an assign / slug change: syncing → issuing → live | failed).
- `POST /api/hostnames/retry { slug }` → re-push an unsynced row → `HostnameState`.
- `GET /api/hostnames/doctor` → `{ checkedAt, items: DriftItem[] }`; `POST /api/hostnames/doctor { ids?: string[] }` (all fixable when omitted) → `{ results: { id, ok, error? }[], items: DriftItem[] }` (items = what remains).

## C.3 CLI (workstream 6)

- `apiGet/apiPost/apiDelete/apiPatch` throw the body's `error` (else `message`) text; `atlas.ts` prints it on stderr, exit 1. disk keeps 0/1/2/3/4. `kill` reuses disk's exit table (0 ok · 1 error · 2 nothing to do · 3 partly failed · 4 refused / needs --yes).
- `atlas ps` → GET /api/processes; `atlas kill` → resolve targets (pid · `:port` via /api/ports/listeners · project query) → POST stop `dryRun:true`, print `wouldEnd` + refusals → TTY confirm or `--yes` → POST for real.
- `atlas stop [path]` → DELETE /api/run. `atlas set` → PATCH /api/atlas (prints `hostname` when present).
- `atlas hostnames check <slug> [path]` (exit 0 only when free/current), `atlas hostnames doctor [--fix] [--json]` (exit 1 while drift remains).
- `atlas daemons [--json]` → GET /api/daemons; `atlas daemons restart <label>` → POST /api/daemons/<label> `{action:'restart'}`.

## File ownership during the fan-out

| Agent | Owns | May touch minimally |
|---|---|---|
| W1a claude-tree/templates | routes/claude-tree/**, lib/claude-tree*.ts, routes/templates/** (not lib/templates.ts), .quality.json + Justfile loc check | — |
| W1b console/perf | routes/+page.*, components/table/**, components/project/**, components/browser/**, lib/browser/**, routes/system/** (not PortsSection, not the new doctor section), routes/disk/**, routes/api/daemons/**, lib/launchctl.ts, routes/api/projects/**, lib/templates.ts (versions-only reader) | — |
| W34 hostnames | lib/caddyDev.ts, lib/services.ts, routes/api/hostnames/**, routes/api/atlas/**, rename/**, move/**, run/**, components/dialogs/ProjectSettings.svelte (+ new dialogs/hostname/*), new system/HostnameDoctorSection.svelte, scanner.ts slugify only, shared/services.json (atlas `remote: true`), NAS wildcard file, ~/dev/.atlas-hostnames.json migration | system/+page.svelte (one tab entry), one chip line in the project row, +page.server.ts (hostname map in page data) |
| W5 processes/ports | lib/processes/**, lib/listeners.ts, lib/ports.ts, routes/api/ports/**, routes/api/processes/**, routes/ports/**, routes/processes/**, system/PortsSection.svelte, lib/guard.ts (LOCAL_ONLY for listeners/processes) | components/Nav.svelte (one link) |
| W6 CLI | atlas-cli worktree | — |
