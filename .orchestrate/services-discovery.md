# Services discovery — plan (not built)

Phase 1 (2026-09-21) shipped a hand-curated `shared/services.json` that atlas-api routes to
`<slug>.atlas.local.jurrejan.com`. This is the plan for finding candidates automatically.

## 1. Enumerate
`lsof -nP -iTCP -sTCP:LISTEN -Fpcn` → `(pid, command, port, bind)` for every listener on the Mac.

## 2. Drop known noise
- Ports already in `services.json`.
- Ports of catalogued projects whose listener cwd is inside the project: dev servers, already
  covered by `/api/run`.
- Denylist of OS/app processes: `rapportd`, `ControlCe`, `ARDAgent`, `adb`, `jetbrains*`,
  `Adobe*`, `workerd` inspector ports, and anything ephemeral (> 49152).
- atlas's own bridge binds (`<lanIp>:<port>` held by the atlas-api pid).

## 3. Probe
`GET http://127.0.0.1:<port>/`, 1s timeout. Keep `2xx`/`3xx` with `content-type: text/html` — a
web UI, not a bare API or MCP socket. Record `<title>` as the suggested name.

## 4. Identify the owner
- pid → cwd (`lsof -a -p <pid> -d cwd -Fn`) → deepest catalogued project.
- port → `daemons.json` entry (gives `daemon`).
- Process path under `Application Support/com.raycast.macos` → "Raycast extension".
- Suggested slug: daemon name, else project slug, else kebab-cased title. Must not collide with a
  registered hostname slug.

## 5. Surface, never auto-assign
- `GET /api/services/discover` → candidates `{ port, pid, command, bind, title, owner, slug }`.
- A "Candidates" list in the system console's Services tab with an **Adopt** button →
  `PUT /api/services` appends the entry to `services.json`, then syncs.
- Human in the loop because each hostname costs two Let's Encrypt certificates (50/week cap on
  `jurrejan.com`) and exposing a UI on the LAN is a judgement call.

## Candidates seen on 2026-09-21
suno-preview 47895, suno-feedback 47894, aw-server 5600 (ActivityWatch), consult-user
19876/19877, Python 8931/8813/47900, bun 42000/42250/42480/9347.

## Known limits of Phase 1 to keep in mind
- A bridge dials `localhost`, which reaches a loopback bind on `127.0.0.1` or `[::1]` (Vite 8's
  default) alike (`dialLoopback` in `services.ts`).
- A `down` service keeps whatever route it had; the hostname 502s until it returns.
