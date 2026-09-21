# atlas run: why it never worked, and what changed

Date: 2026-09-15. Session: bold-auk. Done-condition: `atlas run` from a real project starts its dev server, prints a live address, and that address answers HTTP, all shown by tool output.

## Outcome

Done and verified. On `web/personal-homepage-simple`, `atlas run` now stops the two servers that were squatting port 4101, starts Vite bound to all interfaces, returns after 15 seconds once the port is really bound, and the printed hostname `https://web-personal-homepage-simple.atlas.local.jurrejan.com` answers HTTP 200. Before the fix the same command printed the same hostname and it answered 502.

## What was wrong

Three faults stacked. Each alone made the printed address a lie.

1. **Old servers squatted the port.** The run route remembered its spawned processes in an in-memory map. The daemon restarted on 11 September, the map was lost, and every server started before that kept running. On this project two Vite instances still held port 4101, one on IPv4 loopback, one on IPv6 loopback. A new Vite found the port busy and silently moved to the next port, while the hostname stayed routed to 4101.
2. **Loopback-only bind.** The project's dev script pins its own port (`vite dev --port 4101`). One regular expression decided both flags, so a script that declared a port got no `--host 0.0.0.0` either. Vite bound loopback, and the Caddy reverse proxy on the NAS cannot reach loopback on this Mac. Result: 502.
3. **The CLI declared success on a guess.** It waited 8 seconds for a bind and then printed the hostname whatever happened. A cold Vite with dependency re-optimisation needs 17 to 33 seconds here.

A false lead, ruled out with evidence: the dev-server logs looked as if each new server died with SIGTERM right after start. That message came from the previous run's parent process writing its exit notice through a stale file handle into the freshly truncated log, leaving a sparse gap. A spawn outside the daemon with identical settings ran fine, and the daemon's own spawn was still alive minutes later.

## What changed

atlas-api, commit c5254e9 on `main` (nested repo `atlas-api/`):

- `src/lib/ports.ts`: `canTakePortFlags` became `devFlags(script, port)`, which adds `--port` and `--host 0.0.0.0` independently and adds nothing for fan-out scripts. New `projectListenerGroups(path, port)` finds listeners on the port whose working directory is the project, via lsof and ps, never the daemon's own process group. New `stopProjectListeners(path, port)` sends SIGTERM to those groups, waits up to 3 seconds for them to be gone, then SIGKILLs what is left.
- `src/routes/api/run/+server.ts`: the in-memory map is gone. POST stops the project's listeners and waits before spawning. The body may carry `wait` in milliseconds, capped at 60 seconds. The reply carries `bound` and `replaced`. DELETE uses the same lookup.
- `src/lib/ports.test.ts`: tests for `devFlags`.

atlas-cli, commit 0feeb84 on `main` (nested repo `atlas-cli/`):

- `src/commands/run.ts`: sends `wait: 60000`, says when it stopped a previous server, dies with the last 15 log lines when the server exited or bound nothing, prints the localhost URL plus a warning when the bind is loopback-only, otherwise prints the hostname.

Workspace root, commit 6ad0a14: one CLAUDE.md convention line about the above.

**Caveat on the atlas-api commit, this needs you.** The atlas-api repo had not been committed since 4 September, and the whole port-discovery machinery my fix builds on (`allocatePort`, `discoverBoundPort`, `resolveLocal`, `caddyDev`, an untracked `src/lib/mutex.ts`) was still uncommitted working-tree work. Because my changes depend on it, `git add` of the three files swept that earlier content in: the commit shows 443 insertions where my own share is roughly 150, and it also carried a `RenameDialog.svelte` move that was already staged. The commit does not build from a clean checkout until `mutex.ts` and the rest of that pile are committed too. Nothing else in the working tree was touched. To undo the commit shape while keeping every change on disk:

```
git -C atlas-api reset --soft HEAD~1
```

The daemon was rebuilt and reloaded (`bun run daemon:reload`), new pid 3367, health ok.

## Verification, all from tool output this session

| Check | Result |
|---|---|
| `bun test src/lib/ports.test.ts` (atlas-api) | 11 pass, 0 fail, exit 0 |
| `bun run check` (svelte-check) | 0 errors, 0 warnings, exit 0 |
| biome on the three changed files | exit 0, two pre-existing non-null-assertion warnings, none new |
| `bunx tsc --noEmit` (atlas-cli) | exit 0 |
| `atlas run` in personal-homepage-simple | stderr "stopped the previous dev server", stdout the hostname, exit 0, 15 s |
| listeners on 4101 after the run | one process, bound `*:4101`; both squatters gone |
| `curl http://192.168.178.180:4101/` | 200 |
| `curl https://web-personal-homepage-simple.atlas.local.jurrejan.com/` | 200 |
| `DELETE /api/run` for the project | `{"stopped":true}`, port free, process gone |

Independent review (fresh sonnet agent, read-only): PASS. It re-ran the four gates (all exit 0), confirmed the web console and Raycast never send `wait` so they keep the 8-second behaviour, confirmed the cwd prefix check needs a trailing slash so `web/foo` cannot match `web/foobar`, confirmed the daemon's own process group is excluded, and found no remaining reference to the removed map or the old flag helper. Its one finding is the commit-shape caveat below.

## Still open

- Other leaked dev servers from before the daemon restart are still running: `the-ultimate-music-quiz` (process group 41350, since 10 September) and a `dev:worker` (pid 91137, since 11 September). The next `atlas run` on each project stops them automatically. Nothing was killed outside the project used for testing.
- A project whose server binds a port other than its `.atlas` port and is never discovered within 60 seconds would not be found by the next run's lookup, and two servers would coexist. Not seen in practice; discovery persists the real port whenever it finds one.
- `atlas run` on a project whose own launchd daemon listens on the project's `.atlas` port from inside the project folder would stop that daemon before spawning; launchd restarts it and the two fight over the port. Same failure shape as before the change, now louder.
- There is no `atlas stop`; stopping is `DELETE /api/run` or the web console. Not requested.
- A repo hook refuses commit trailers with a session link, so the commits carry none.

## Budget

No subagents for the investigation or the fix (one dependent chain, done inline). One sonnet verifier for the fresh-eyes pass.


---

# Scaffold version in the web console

Date: 2026-09-15, session bold-auk. Done-condition: the console at `/` shows, for every project with a `.template-meta.json`, its template and the version it was generated from, and marks the ones behind the template's current version, verified in a browser.

## Outcome

Done and verified in the browser. The version badge already existed: `ProjectBadges.svelte` has rendered "sveltekit v2.4.0" style badges since commit 7ea74e7 of 10 September, linking to the templates page, and the deployed build had it. What was missing was any sign of whether that version is current. Each row now compares its version with the template's current `_version` and shows an amber "sveltekit v2.4.2 → 2.6.0" badge when behind, with a title that names `/update-scaffold`. Rows on the current version look as before.

Screenshots: `/var/folders/gf/mydszwwx4y903frqzf0rs9980000gn/T/claude-chrome-screenshots-DcLj6Y/screenshot-1789428615527-0.jpg` (before, plain badges) and `/var/folders/gf/mydszwwx4y903frqzf0rs9980000gn/T/claude-chrome-screenshots-DcLj6Y/screenshot-1789429099240-1.jpg` (after, utt-website row marked behind).

## What changed (atlas-api, uncommitted)

- `src/routes/+page.server.ts` loads the current versions with the same template discovery the `/templates` page uses and returns `templateVersions`, a record from template name to version.
- `src/routes/+page.svelte` and `src/lib/components/project/ProjectRow.svelte` pass it down as a prop.
- `src/lib/components/project/ProjectBadges.svelte` derives whether the project is behind and switches the badge to the warning tone with the arrow text.

Left uncommitted on purpose: all four files already carried uncommitted edits from the earlier UI overhaul, so a commit would sweep that work in, as happened with the atlas-api commit in the first section. Commit them with the rest of the pile.

## Verification

| Check | Result |
|---|---|
| `bun run check` | exit 0 |
| biome on the four files | exit 0 |
| `bun run test`, `bun run build` (implementer) | exit 0 |
| `bun run daemon:reload` | exit 0, health ok |
| server payload of `/` | carries `templateVersions` with sveltekit at 2.6.0; 22 sveltekit projects sit on older versions |
| browser, live page | three "sveltekit v2.4.2 → 2.6.0" badges found; screenshot above |

Independent review (fresh sonnet agent, read-only): matches the spec, no correctness defects; `bun run check` and `bun run test` exit 0; warm `GET /` at 0.2 to 0.4 seconds. Its one nit: template discovery runs uncached on every load of `/`. It reads 20 small files and the `/templates` page already does the same, so it stays as is.

## Still open

- The current version comes from the templates repo working tree on disk, which right now holds uncommitted version bumps (2.6.0 for sveltekit while the last commit says 2.5.x). The marker follows whatever is on disk.
- The root page takes several seconds to render 534 rows; the browser extension's screenshot injection timed out twice on first load. Not caused by this change.

## Budget

One sonnet implementer, one sonnet verifier.


---

# Cookiecutter templates: scaffolds that work with atlas

Date: 2026-09-15, session bold-auk. Done-condition: every template scaffolds a project that carries what atlas expects, verified by rendering projects from the changed templates, and the same change reaches an already generated project through the scaffold update tool, verified on a copy of a real project.

## Outcome

Done on a branch, verified, not merged. Three commits sit on branch `worktree-atlas-rules` in the worktree `.claude/worktrees/atlas-rules` of the cookiecutter-templates repo: cc514c6 (the guidance file, the updater rule, nextjs host bind, raycast update entry point, version bumps), 7cfac6c (host binds for sveltekit, react, tizen-tv, fastapi, flask) and 2b0f051 (one CLAUDE.md convention line). Merging is yours, see below.

## What every generated project now gets

Every template ships `.claude/rules/atlas.md`, identical in all 20, registered as a cross-family shared file. It tells an agent what `.atlas` is, to start the dev server with `atlas run` and why the dev command must bind all interfaces on the `.atlas` port, where ports come from, the other `atlas` commands, and how scaffold updates work. The updater lists that path as template-managed, so `update-scaffold --apply` writes it in place on projects that never had it instead of leaving a sidecar. That is the part that reaches existing projects: the SessionStart hook in each generated project sees the version bump and prompts for the update.

Every port-bearing template's dev command now binds all interfaces on the cookiecutter port: nextjs gained `-H 0.0.0.0`, sveltekit, react and tizen-tv gained `--host 0.0.0.0` on Vite, fastapi and flask gained `--host 0.0.0.0` in their Justfile dev recipe. node-api and go/api already did. raycast-extension, which has no Justfile by design, got `scripts/update-scaffold.sh` and a package.json script so it can take updates like the rest. Each changed template has a minor version bump and a CHANGELOG line. The post-generation hooks were already writing `.atlas` and running `atlas agent-log init` and were left alone.

## Verification, all from tool output in this session

| Check | Result |
|---|---|
| rules file present in all 20 templates | 20 files, one checksum, equal to my draft |
| `uv run tools/sync_check.py` in the worktree | exit 0, "All families in sync" |
| cookiecutter render of sveltekit, react, fastapi from the branch | exit 0 each; dev commands carry `--host 0.0.0.0`; rules file present |
| scaffold update on a copy of web/demo-voor-klip (2.4.0) with `COOKIECUTTER_TEMPLATES` pointed at the worktree | exit 0; `.claude/rules/atlas.md` written in place, no sidecar, checksum equal to the draft; `.atlas` kept description and port 4100; meta moved to 2.5.0 |

The worker's own render test run: 44 of 47 variants pass. The three failures are typescript/nextjs `bun run lint`, which the worker showed also fails on an untouched render of main's nextjs (next build rewrites tsconfig.json before biome runs). That proof rests on the worker's run, not mine, so it stays open.

Independent review (fresh sonnet agent, read-only): PASS, no defects against the spec. It confirmed the 20 identical files and the manifest entry, the updater pattern, every port bind including node-api and go/api, the raycast entry point, the version bumps, sync_check exit 0, and repeated the scaffold update on its own copy of demo-voor-klip with the same result. One pre-existing quirk it noticed, outside this change: the updater also writes a spurious `.template-meta.json.upstream` sidecar next to the file it updates in place.

## Needs you: the merge

The templates repo's main working tree holds a large uncommitted rollout from another session: 84 files, version bumps in every template, agent.md additions, a rewritten sync manifest, and an untracked `tools/add_shared_file.py`. Generated projects are already being offered those uncommitted versions by the SessionStart hook. My branch starts from main's last commit, so its version numbers collide with the uncommitted bumps (the branch has sveltekit at 2.5.0 where your working tree says 2.6.0) and a merge into the dirty tree will conflict on cookiecutter.json, CHANGELOG.md and sync_manifest.json. The order that works: commit the pending pile on main first, then `git merge worktree-atlas-rules`, resolve the version and manifest conflicts by keeping the higher version plus one minor for the atlas change, run `uv run tools/sync_check.py`, and remove the worktree with `git worktree remove .claude/worktrees/atlas-rules`. Until the merge, generated projects do not see this change.

## Still open

- The nextjs render-test lint failure, pre-existing per the worker's baseline run.
- Version collision with the uncommitted bumps, resolved at merge time as above.
- Projects on retrofit or heavily customised scaffolds still receive the dev-command change only as a `.upstream` sidecar, by the updater's design; the rules file lands regardless.

## Budget

One haiku inventory session, one sonnet implementer session, one sonnet verifier. All sessions stopped.
