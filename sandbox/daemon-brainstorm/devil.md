# Devil's case against this

## The strongest objection

**atlas-api is itself a managed daemon, kickstarted by `atlas-watchdog` via `launchctl kickstart -k gui/$(id -u)/com.jurrejan.atlas-api`.** The moment you make atlas the home for *other* daemons, you've created a circular runtime dependency: atlas-api crashes → the thing supposed to restart wallgen/rvr-service/MCP servers is down → who restarts atlas-api? A Raycast script command that only fires when you manually open Raycast. That is not a supervisor. That is a polite reminder. Today this is fine because atlas-api's only job is to scan files; if it dies, nothing breaks. The minute it owns the lifecycle of paying-work daemons (wallgen earns money, rvr-service is your VR stack), an atlas-api bug becomes an outage across every project you own. **Do not give a project-indexer the power to take down your business.**

## Premise problems

- **Atlas indexes projects. Daemons are not projects.** The `Project` shape in `atlas-api/src/lib/scanner.ts` is "thing in `~/dev` with a git/package/justfile." A launchd unit is a *runtime artifact*, not a source artifact. Cramming it in violates the single source-of-truth that makes the scanner cache coherent (60s TTL, stale-while-revalidate). Now the cache has to invalidate on `launchctl` state changes too.
- **launchd already exists and is good.** The three existing `com.jurrejan.*` plists (atlas-api, beads-bridge, dlwatcher) are 25 lines each, declarative, survive reboots, and need zero custom code. You are proposing to wrap a working system call in a SvelteKit endpoint to get… what, a pretty list? `launchctl list | grep jurrejan` already does that.
- **In-repo plists drift from `~/Library/LaunchAgents`.** Apple's loader only reads the latter. You will end up with three states: file in repo, symlink in LaunchAgents, loaded-in-memory job. Right now you have one symlink (`com.jurrejan.vpn-subnet-fix.plist`) and it works precisely because it's the only abstraction. Introducing a sync layer guarantees a "why isn't my change taking effect" debugging session within a month.
- **Scope creep dilutes atlas's identity.** atlas-browser, atlas-picker, and atlas-watchdog are all *read-mostly* over a scanner. The only write endpoints today are tiny (rename, archive, beads ticket). Adding `bootstrap`/`bootout`/`kickstart`/`unload` makes atlas a process supervisor, which it isn't designed, tested, or hardened to be.

## Implementation landmines

- **`launchctl bootstrap gui/<uid>` requires an Aqua session.** atlas-api running under its own LaunchAgent already *is* in a gui session, so this works — until you `bun run dev` it from a TTY for debugging and `launchctl` silently fails with "Bootstrap failed: 5: Input/output error." Different errors in dev vs. prod is the worst kind of bug.
- **`launchctl bootout` of a job that wedged in `WaitingForSocket` blocks for the kill grace period (default 20s).** A SvelteKit fetch handler hanging for 20s ties up Bun's event loop and your Raycast UI shows a spinner. You will add a timeout; the timeout will leave the job in a half-stopped state; cleanup will require manual `launchctl bootout` from a terminal anyway.
- **Plist parsing.** You will write XML plist serialization in TypeScript. `plist` npm packages are unmaintained or buggy with `<data>` blobs and `<array><dict>` nesting. The existing handwritten plists already differ in whitespace, key ordering, and `ProcessType` presence — your serializer round-trip will mutate every existing file on first save.
- **Log explosion.** Three daemons today already write to `/tmp/atlas-api.log`, `~/Library/Logs/beads-bridge.log`, `~/Library/Logs/dl-watcher.stderr.log` — three different conventions. If atlas "manages" them, it'll either inherit the chaos or rewrite every plist's `StandardOutPath`, breaking your existing `tail -f` muscle memory.
- **Stale references.** Delete `~/dev/dl-watcher`? `com.jurrejan.dlwatcher` keeps respawning a broken venv path and floods logs with `ENOENT` until you remember it exists. Atlas's scanner won't catch this because the plist lives in `~/Library/LaunchAgents`, outside its scan root.
- **Keychain/TCC prompts.** Some daemons (rvr-service touches HID, MCP servers touch network) will trigger Full Disk Access or Input Monitoring prompts. Running them under atlas's launchd label inherits *atlas-api's* TCC grants — wrong app gets the permission, security audit becomes a nightmare.

## Cheaper alternatives that already exist

- **Just keep using `~/Library/LaunchAgents` directly.** A 30-line Raycast script (`launchctl list | awk '/jurrejan/'` + per-row kickstart action) gives 90% of the UX with zero new code. The existing `atlas-watchdog` is the proof — it's 23 lines and works.
- **Homebrew services** for anything brew-installed (postgres, redis). `brew services list` is the table view you want.
- **`pm2`** for Node/Bun daemons — battle-tested, `pm2 startup` writes the launchd plist for you, `pm2 monit` is a TUI that already exists.
- **A `~/dev/_management/daemons/` plain folder** with versioned plists + a `just install`/`just reload` recipe. Source-controlled, no API, no scanner, no circular dep. This is what `vpn-subnet-fix` already does (symlink from LaunchAgents into the repo).
- **`launchcontrol`** (the GUI app) if you want a pane of glass.

The tradeoff with all of these: no Raycast integration. But Raycast script commands are 20 lines of bash — write four of them.

## If you do it anyway — minimum sanity checks

1. **atlas-api MUST NOT be in its own managed set.** Bootstrap of atlas-api stays via `launchctl` alone, watched only by `atlas-watchdog`. No self-management. Document this in `atlas-api/CLAUDE.md`.
2. **Plists are source-of-truth in repo; `~/Library/LaunchAgents/com.jurrejan.*.plist` are symlinks only.** No in-place serialization. Atlas reads, never writes XML — edits go through `$EDITOR` then `launchctl bootout && bootstrap`.
3. **All write endpoints (`bootstrap`, `bootout`, `kickstart`) require a 5s hard timeout and return job state from `launchctl print` after the call.** No silent half-states.
4. **A "managed daemon" must declare its repo path; if the path disappears, atlas surfaces a `stale` flag and offers `bootout` — never auto-restarts a broken job.**
5. **Read-only mode by default.** atlas displays daemon state; an explicit env var (`ATLAS_DAEMON_WRITE=1`) enables lifecycle actions. Ship the display first, live with it 30 days, then decide if you actually need the write path.
