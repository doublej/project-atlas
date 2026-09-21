# Fixing atlas — 2026-08-31

## Outcome

Atlas works from the development root again. Running `atlas scan`, `atlas sideload` and
`atlas ports` from `~/Documents/development` now all exit 0 and print no "atlas-api isn't
running" line. Two defects caused the failures, both are fixed, committed and live: the
command-line tool mistook a slow health check for a dead daemon, and the API served a
project cache that never refreshed itself.

Nothing was pushed. No worker sessions were spawned, so none are left running.

## The two defects

The first defect lived in `atlas-cli/src/api.ts`. Its `isUp()` gave the daemon two seconds
to answer `/api/health` and treated every failure, including a timeout, as proof the process
was gone. Under machine load the probe blew its two seconds against a daemon that had been
up for a day and had never exited. The tool then announced "atlas-api isn't running",
ran `launchctl kickstart` against a healthy job, polled for 4.5 seconds and died with
"atlas-api still isn't up". Measured against the running daemon, health answers in 10 to 210
milliseconds across 39 probes, cold and warm, including during a full rescan, so a two-second
failure never meant death. A daemon that is genuinely dead refuses the connection instantly
instead of hanging, which is what the fix keys on: only a refused connection now counts as
down, and a timeout counts as alive but busy.

The second defect lived in `atlas-api/src/lib/scanner.ts`. Its `scan()` read the cache,
computed whether it was older than the 60 second time-to-live, and then returned it anyway
without acting on that flag. The comment said "let client decide to refresh in background"
and no client ever did. The catalog therefore aged without bound until somebody ran
`atlas scan` by hand. That is why `atlas sideload` reported the path
`multi-stack/sideload/sideload-web`, which had not existed for an hour. A stale read now
starts one background rescan, guarded by a single in-flight promise so concurrent readers
cannot stampede it, and still answers immediately from the cache it has.

## What changed

`atlas-cli`, commit dd163ba on main: `src/api.ts` catches the fetch error and returns true
for `TimeoutError`, plus a new `src/api.test.ts` covering both directions.

`atlas-api`, commit 35d9a27 on main: `src/lib/scanner.ts` gains a `revalidate()` helper and
a two-line change in `scan()` that calls it when the cache is stale.

`project-atlas`, commit 5427f52 on main: one line in `CLAUDE.md` recording that a health-probe
timeout means busy rather than dead, next to the existing rule about `launchctl kickstart`.

## How it was verified

The new test in `atlas-cli` was run against the old code and fails there, and passes against
the new code, so it genuinely catches the regression. The full command-line suite is 66 tests
passing, and `tsc --noEmit` is clean. On the API side `svelte-check` reports 0 errors and 0
warnings, and the daemon was rebuilt and restarted with `bun run daemon:reload`.

The cache fix was proven end to end rather than by reading code. A throwaway project was
created at `_sandbox/stale-probe`, a scan picked it up as project 476 of 476, the directory
was deleted from disk, and no scan was run afterwards. The first query past the 60 second
time-to-live still returned the deleted project, as designed, and 15 seconds later the same
query returned "No projects matching", meaning the background rescan had corrected the
catalog on its own. Health stayed at 200 in 18 milliseconds throughout.

The closing check ran the three commands that failed at the start of the night. All three
exit 0 with zero restart messages, and `atlas sideload` resolves to `multi-stack/sideload`,
its real path.

## Open

The daemon now runs as pid 98922 after the deliberate restart, with last exit code 0.

`shared/daemons.json` in project-atlas was already modified before this run started. It was
left untouched and uncommitted.

Two things were seen and deliberately not chased. The catalog count moves between 455 and 476
between scans, which is expected while directories are being created and removed but was
never explained. And `enrichCacheWithGit` runs git across every repository in batches of 20
with no per-repository timeout, so one wedged repository would stall the enrichment pass
silently; it never misbehaved during this run.
