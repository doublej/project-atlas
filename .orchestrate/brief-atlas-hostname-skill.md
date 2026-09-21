# Brief: build the `atlas-hostname` skill

Build one Claude Code skill, global (`~/.claude/skills/atlas-hostname/SKILL.md`), invoked from
inside any project. It does two things and nothing else:

1. **Make this project reachable on its atlas dev hostname** — check the handful of things that
   must be true, fix the ones that aren't, verify with a real request.
2. **Change how the agent talks about running servers** — once a project has a hostname, the
   agent hands out `https://<slug>.atlas.local.jurrejan.com`, never `http://localhost:<port>`.

Use `/skill-creator` to scaffold it. Keep it one `SKILL.md` — no scripts directory unless the
verification step genuinely needs one.

---

## Ground truth (verified in project-atlas this session — cite, don't re-derive)

**Hostname shape.** `<slug>.atlas.local.jurrejan.com` (LAN) and `<slug>.atlas.remote.jurrejan.com`
(WAN, basic-auth). The label is **`atlas`**, not `dev` — `atlas-api/src/lib/caddyDev.ts:12`
(`SUBDOMAIN_LABEL`), confirmed live against `GET /api/hostnames`. project-atlas's own CLAUDE.md
vocabulary entry still says `.dev.` and is stale; the code and the live registry win.

**Who registers a hostname.** Only `POST /api/run` and `POST /api/hostnames` call `ensureRoute`.
That means `atlas run`, the web console's run buttons, and `atlas hostnames assign`. Raycast's run
action and `atlas jump --run` are shell passthroughs and register **nothing**
(`.orchestrate/findings/mechanism.md` §5).

**What `ensureRoute` does** (`caddyDev.ts:186`): writes `<slug>-atlas.caddy` into the NAS's
`etc/sites/` over SSH, validates, reloads Caddy, records the entry in `~/dev/.atlas-hostnames.json`.
It is a no-op when slug + port + `devPublic` are unchanged and the last push succeeded. It fails
soft: an unreachable NAS returns `null` and the caller falls back to the localhost URL.

**The four conditions for a working hostname.**
- The project is in the **cached** scan, matched by exact `path`. Not in it → `/api/run` spawns the
  server and silently skips `ensureRoute` (`run/+server.ts`, the `project ? … : null` ternary).
  Fix: `atlas scan`.
- It has a **port in the atlas range 4100–4999** (`ports.ts:ATLAS_PORT_RANGE`), stored in `.atlas`.
  Absent → one is allocated and written back. Never 3000/5173/8000.
- The dev server **binds all interfaces**. Caddy proxies from the NAS to this Mac's LAN IP; a
  loopback bind resolves, passes auth, then 502s. `devFlags()` injects `--host 0.0.0.0` (and
  `--port` when the script doesn't pin one) but only for a single-process script — a script that
  fans out through `concurrently`/`turbo`/`npm-run-all` gets **no flags at all** and must carry the
  bind itself. `/api/run` returns `lanReachable: false` when it detects a loopback-only bind.
- The **slug is stable**. Default slug is `slugify(relativePath)` — `web/eink` → `web-eink`
  (`scanner.ts`, slug set from `relPath`). Moving or renaming the folder silently changes the
  hostname and orphans the old NAS file; nothing cleans it up. `.atlas` `slug` overrides it and is
  run through `slugify`, so a project can claim a shorter name.

**The `.atlas` keys that matter here.** `port` (number), `slug` (string, optional override),
`devPublic: true` (drops basic auth on the `.remote` host). Read at `scanner.ts` in the `.atlas`
metadata block; written by hand or `PATCH /api/atlas`.

**Cost of a registration.** Two ACME certificates per hostname plus a full Caddyfile reload — the
NAS wildcard is `*.jurrejan.com` and does not cover two labels deep. So: register on demand, never
in bulk. This is a hard constraint, not a preference.

**Known per-stack state** (`.orchestrate/findings/scaffold.md` §2, and the unmerged
`worktree-atlas-rules` branch in `_management/cookiecutter-templates`):
- Vite family (sveltekit, react, tizen-tv): ships **localhost-only**, needs `--host 0.0.0.0` or
  `server.host: true`.
- Next.js: dev default is already 0.0.0.0; the template added `-H 0.0.0.0` explicitly.
- node-api, go/api: already bind 0.0.0.0.
- fastapi, flask: fixed on the branch (`--host 0.0.0.0` in the Justfile dev recipe); unfixed in
  already-generated projects.
- CLI/library/native templates have no dev server — the skill must recognise these and stop.

**Existing prose to converge with, not duplicate.** The templates branch carries
`.claude/rules/atlas.md` (identical in all 20 templates, still unmerged). Read it before writing;
the skill is the *retrofit and verification* path for projects that will never get that file, and
its wording should not contradict it.

---

## What the skill must do, in order

Write it as a procedure, not an essay. Each step states the check, the fix, and the evidence.

1. **Is this a project with a dev server at all?** `atlas info --json`. No `devCommand` → say so
   and stop. Do not invent a dev script for a CLI or a library.
2. **Is it in the scan?** `atlas info` failing with "No scanned project" → `atlas scan`, retry once.
3. **Port.** Read `.atlas`. Outside 4100–4999 or missing → take one from
   `GET /api/ports/allocate`, write it to `.atlas`, and pin the same number in the dev script
   (`package.json`, Justfile, uvicorn args — match where the project already puts it).
4. **Bind address.** Inspect the dev script. Single process → `--host 0.0.0.0` is injected, but
   pin it in the script anyway so `bun run dev` behaves the same as `atlas run`. Fan-out wrapper
   (`concurrently`, `turbo`, `npm-run-all`, `honcho`, `foreman`, `pm2`, `overmind`) → the flags are
   dropped, so each sub-command needs its own bind. Vite may instead use `server.host: true` in
   `vite.config.*`.
5. **Slug.** Print what the hostname will be before registering. If the folder path makes an ugly
   or ambiguous slug, offer `.atlas` `slug`. Say plainly that a later folder move changes it.
6. **Register and verify.** `atlas run` (it waits 60s for the bind and prints the hostname) or
   `atlas hostnames assign` when no server should start. Then a real check:
   `curl -sS -o /dev/null -w '%{http_code}' https://<slug>.atlas.local.jurrejan.com/`. 200 → done.
   502 → the bind is wrong, go back to step 4. Anything else → report the code and the last lines
   of `~/dev/.atlas-logs/<slug>.log`.
7. **Record it.** One line in the project's CLAUDE.md: its hostname, its port, and that `atlas run`
   is how the dev server starts here.

---

## The output rule (the second half of the job, and the easy half to get wrong)

State it in the skill as a standing instruction for the rest of the session, not as a step:

> Once this project has a registered dev hostname, every URL you hand the user is the hostname.
> `http://localhost:<port>` is an internal detail — it appears in logs and config, never in a
> sentence addressed to the user.

Spell out the four places it leaks: the sentence after starting a dev server; "open
http://localhost:… to see it"; browser automation (`claude-in-chrome` navigates to the hostname);
and screenshots/reports quoting the bar. Spell out the exceptions too, so the rule survives contact:

- The hostname is not registered yet, or the NAS push failed (`nasSynced: false`) — say *that*, then
  give the localhost URL as the stated fallback.
- The bind is loopback-only — `atlas run` prints `lanReachable: false`; fix the bind rather than
  quietly falling back.
- Machine-facing config: test runners, `baseURL` in Playwright, health probes, `curl` in a script.
  These stay on localhost; TLS and the NAS hop buy nothing there.
- `atlas.remote` is password-gated and costs a round trip over WAN — offer it only when the user
  is off the LAN, or when `.atlas` `devPublic` is set.

---

## Failure modes the skill must name (each one cost a debugging session already)

- **Registered but 502** — loopback bind. The single most common outcome; check it every time.
- **Registered, pointing at a dead port** — a previous dev server was left running, the new one
  moved to port+1. `atlas run` now stops the project's own listeners first; a server started by
  hand in a terminal is still stopped by it, a launchd daemon on the same port will fight back.
- **Stale paths in the registry** — entries written before the `~/Documents/development` →
  `~/dev` move still carry the old path. Match on slug, not path, when reading
  `.atlas-hostnames.json`.
- **Folder renamed** → new slug, new hostname, orphaned `<old-slug>-atlas.caddy` on the NAS.
  `atlas hostnames rm` before the move is the clean order.
- **NAS unreachable** (off-LAN, VPN, NAS down) → `ensureRoute` returns null, no hostname, no error
  raised. The skill must check the response, not assume.
- **Host header** — Caddy rewrites `Host: localhost` on the proxy hop, so Vite's allowlist is
  already satisfied and no per-project `allowedHosts` change is needed. Do not add one.

---

## Non-goals

- No bulk registration, no "register every project" loop — certificate cost.
- No hand-editing the NAS Caddyfile or `sites/` — `ensureRoute` owns those files.
- Do not restate the `atlas` CLI surface; the `atlas-cli` skill and `.claude/rules/atlas.md`
  already do. Link, don't copy.
- No new config file, no wrapper script, no abstraction over `atlas run`.

---

## Acceptance — the skill is done when

1. Run on a fresh Vite project with no port and no hostname: it allocates a port, adds the bind,
   registers, and `curl` returns 200 over the hostname.
2. Run on `web/eink` (registered, historically loopback-only): it detects the 502 cause and fixes
   the bind instead of reporting success.
3. Run on a CLI project (`python/cli` render): it stops at step 1 without editing anything.
4. Run twice on the same project: the second run is a no-op that prints the hostname, with no NAS
   push (`ensureRoute` already short-circuits — confirm nothing new hit the registry).
5. After any of the above, the agent's own prose contains no `localhost:` URL.

---

## Settle these before shipping (verify, don't guess)

- **HMR over the proxy.** Host is rewritten to `localhost`, so Vite's HMR client likely tries
  `ws://localhost:<port>` from the viewer's browser and fails silently on a remote device. Test it
  once, then write down what actually happens — either "HMR works", or "full reload only over the
  hostname, use localhost while iterating". Do not ship a guess.
- **Python/Go dev servers.** `scaffold.md` §5 never verified the bind for `python/fastapi` and
  `go/api` in *generated* projects. Grep one of each before the skill claims to know.
- **Whether the templates branch merged.** If `worktree-atlas-rules` lands, scaffolded projects get
  `.claude/rules/atlas.md` and this skill becomes retrofit-only for older projects. Check, and set
  the skill's `description` trigger accordingly.

---

## Files

- `atlas-api/src/lib/caddyDev.ts` — hostname shape, `ensureRoute`, NAS push, registry
- `atlas-api/src/lib/ports.ts` — `ATLAS_PORT_RANGE`, `devFlags`, `discoverBoundPort`, `pickPort`
- `atlas-api/src/routes/api/run/+server.ts` · `.../api/hostnames/+server.ts`
- `atlas-api/src/lib/scanner.ts` — `slugify`, the `.atlas` metadata block
- `atlas-cli/src/commands/run.ts` · `atlas-cli/src/commands/hostnames.ts`
- `.orchestrate/findings/mechanism.md` · `.orchestrate/findings/scaffold.md` · `.orchestrate/report.md`
- `_management/cookiecutter-templates/.claude/worktrees/atlas-rules/**/.claude/rules/atlas.md`
- `~/dev/.atlas-hostnames.json` (registry) · `~/dev/.atlas-logs/<slug>.log` (dev server output)
