# Pragmatist's brainstorm

## Minimum viable shape

A flat `shared/daemons.json` registry that mirrors the proven `shared/actions.json` pattern: hand-edited JSON, three UI consumers, no codegen on first run. Plists already exist in `~/Library/LaunchAgents/com.jurrejan.*.plist` and `KeepAlive` is doing its job — Atlas just teaches itself their names and exposes `launchctl` over HTTP. atlas-watchdog already nails the polling loop with `launchctl kickstart -k gui/$(id -u)/com.jurrejan.atlas-api`; v1 is "atlas-watchdog, generalized." No new supervisor, no plist generation, no health-check DSL. The browser gets a "Daemons" view first because Raycast is where the user already lives.

## Concrete answers to the 10 questions

1. **Source of truth:** `shared/daemons.json` — plists stay where launchd expects them; the JSON is just a directory listing with labels + ports.
2. **Plist storage:** Stay in `~/Library/LaunchAgents/`. v1 does not write plists. Add a `plists/` folder later for version-controlled copies if needed.
3. **Lifecycle UI:** atlas-browser only (new "Daemons" command). Picker and api UI come in v2.
4. **Watchdog:** Defer to launchd `KeepAlive`. atlas-watchdog stays exactly as-is for atlas-api itself. One pass-through "status of all" endpoint is enough.
5. **Project↔daemon link:** Central — `daemons[].project` is an optional path string. No project-side manifest scanning. Auto-detect = never.
6. **Logs:** Wherever the plist already writes them (`/tmp/atlas-api.log` pattern). Endpoint returns last N lines via `tail`.
7. **Boundary with launchd:** Wrap, don't replicate. Atlas shells out to `launchctl bootstrap/bootout/kickstart/print gui/<uid>/<label>`.
8. **Port conflict detection:** Reuse the existing `lsof -i :PORT` check from `run-atlas-watchdog.sh`. Show port + occupied flag in the list. No resolution logic in v1.
9. **Naming:** `com.jurrejan.<slug>` (existing convention — `atlas-api`, `dlwatcher`, `beads-bridge`, `vpn-subnet-fix` all already match).
10. **Bootstrap integration:** None in v1. Don't touch `apps.manifest`. Daemon registration is "edit the JSON, write a plist, run `launchctl bootstrap` once."

## File-level plan

- `shared/daemons.json` — new, hand-edited registry (seed with the 4 existing plists).
- `shared/daemons.ts` — types + `getDaemons()` helper, mirrors `shared/actions.ts`.
- `atlas-api/src/routes/api/daemons/+server.ts` — `GET` list + status.
- `atlas-api/src/routes/api/daemons/[label]/+server.ts` — `POST` action (start/stop/restart), `GET` logs.
- `atlas-api/src/lib/launchctl.ts` — thin `spawn('launchctl', [...])` wrapper, parses `print` output.
- `atlas-browser/src/daemons.tsx` — new Raycast command, list view + actions.
- `atlas-browser/package.json` — register the command in `commands[]`.
- `atlas-browser/src/scanner.ts` — leave untouched.
- `atlas-watchdog/run-atlas-watchdog.sh` — leave untouched.
- `CLAUDE.md` — add 4-line "Daemons" section pointing at `shared/daemons.json`.

## Schema sketch

```json
{
  "version": 1,
  "daemons": [
    {
      "label": "com.jurrejan.atlas-api",
      "name": "Atlas API",
      "port": 47891,
      "project": "/Users/jurrejan/Documents/development/multi-stack/project-atlas/atlas-api",
      "logs": { "stdout": "/tmp/atlas-api.log", "stderr": "/tmp/atlas-api.error.log" }
    },
    {
      "label": "com.jurrejan.beads-bridge",
      "name": "Beads Bridge",
      "project": "/Users/jurrejan/Documents/development/..."
    }
  ]
}
```

Three required fields: `label`, `name`, optional `port`, optional `project`, optional `logs`. That's it. No env, no schedule, no health URL, no dependencies array.

## The 3 API endpoints that actually matter

- `GET /api/daemons` — registry joined with `launchctl print` state + `lsof` port check.
- `POST /api/daemons/:label` — body `{ action: "start" | "stop" | "restart" }`, shells to `launchctl bootstrap/bootout/kickstart -k gui/<uid>/<label>`.
- `GET /api/daemons/:label/logs?lines=200` — `tail -n` on the stdout/stderr paths from the registry.

## Out of scope for v1

1. **Plist generation / templating.** User writes plists by hand (he already does).
2. **Health-check protocol** beyond "is the port open" and "does launchctl say it's running."
3. **Auto-registration from project manifests.**
4. **Picker + api-ui surfaces** — browser only.
5. **Dependency graphs / startup ordering** — launchd doesn't really do this; don't pretend Atlas does.

## Risks I see being overcomplicated

- **Reinventing launchd.** The moment someone proposes a `restart-policy` field in daemons.json, kill it — that's literally `KeepAlive`. Wrap launchctl, don't shadow its config.
- **Plist codegen.** Tempting and wrong for v1. The 4 existing plists were hand-written and work fine. Generating them means owning a schema that has to track every plist key Apple ships.
- **A "daemons" tab in atlas-api's web UI.** The user lives in Raycast. Shipping three UIs at once triples the surface area for the same value. Browser first, measure usage, then maybe picker. The atlas-api web UI may never need it.
