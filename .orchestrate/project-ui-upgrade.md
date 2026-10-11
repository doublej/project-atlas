# Project overview + editing, first class (web console)

JJ, 2026-10-11: "heavily upgrade the project overview and project editing tools to be first class (webui)".

Today the `/` list is a dense table whose row opens a small inline detail (`ProjectRow`), and
editing is scattered: description inline in `ProjectDetails`, everything `.atlas` in the
`ProjectSettings` modal, rename/move/archive/beads as separate dialogs or menu items, tags only
via the CLI. A project has no page of its own and no URL.

Target: **every project gets a real page with everything atlas knows and every edit atlas can
make, and the list becomes a proper working surface** (tags, bulk edits, shareable views,
keyboard).

## Ground rules (both workstreams)

- Read `atlas-api/CLAUDE.md` and `atlas-api/docs/ui-primitives.md` first. Svelte 5 runes only,
  plain CSS from `src/lib/styles/tokens.css`, `$lib/http` for every client call, `toast`,
  `ConfirmDialog`, `Notice`, `PageState`, `Table`, `SideNav`, `Selection` — nothing hand-rolled.
- Gates in `.quality.json`: ≤400 lines per `.svelte`/`src/lib/**/*.ts` (warn 300), ≤6 files per
  directory under `src/lib/components/**`, `src/lib/browser/**`. Make a new directory rather
  than overfill one. `just check` in `atlas-api/` must pass (fmt → loc → dir → lint →
  typecheck → test). The other workstream edits files at the same time: ignore check failures in
  files you do not own, never "fix" them.
- Every write goes through existing API routes (they enforce the write guard and `resolveLocal`):
  `PATCH /api/atlas` (`.atlas` merge, `null` clears), `PUT /api/description`, `POST /api/rename`,
  `POST /api/move`, `POST /api/archive`, `PUT /api/tags {path,tags}`, `PATCH /api/tags
  {paths,add,remove}` (bulk), `GET /api/tags` (vocabulary `{tags:[{tag,count}]}`), `PUT /api/config`
  (scan overrides), `POST /api/beads`, `POST /api/run`, `POST/DELETE /api/hostnames`. Reads:
  `GET /api/projects?path=<abs>` (one full record), `GET /api/atlas?path=`, `GET /api/agent-log?path=`,
  `GET /api/processes?project=<path>`, `POST /api/readme`, `GET /api/hostnames?all=1`.
  If you truly need a new route, keep it tiny and say so in your report.
- Remote projects (`isLocal` absent) are read-only: show, never offer an edit.
- Shared tag input: `src/lib/components/tags/TagInput.svelte` (`tags`, `vocabulary`, `onchange`)
  and pure `normalizeTags` in `src/lib/tag-normalize.ts`. Both workstreams use them; neither
  rewrites them (small additive props are fine — workstream A owns that file if it must change).
- Tags today: ~272 distinct, 5–9 per project, incl. a state tag (`active`/`parked`/`dormant`/`archived`).
- Verify in a real browser (claude-in-chrome) against a second build/dev server on another port
  (`bunx vite dev --port 47990 --host 127.0.0.1`, see the memory on Vite binding IPv6) — never by
  restarting the daemon. Take one screenshot of the finished thing.
- Commit in `atlas-api/` (its own git repo) after each atomic step, `verb: desc`, no session
  trailers, only your own files. Don't push.

## Workstream A — the project page (owner of `src/routes/p/**`, `src/lib/components/projectpage/**`, `src/lib/components/dialogs/**`, `src/lib/components/project/**`, `src/lib/components/tags/**`)

URL: **`/p/<relativePath>`** (e.g. `/p/multi-stack/deckhand`), route `src/routes/p/[...path]/`.
Load the full record server-side (the cached scan, match `relativePath`; 404 a miss). A remote
twin with the same relativePath: prefer the local one, link the others (`alsoOn`).

Layout: a header band + `SideNav` sections (or one scrolling page with an anchored side index —
pick what reads best at 1400px and at phone width).

Header: name (click to rename inline → `/api/rename`, then `goto` the new URL), path (copy),
host badge, state + stack badges, **tags editable inline with `TagInput`** (saves on change,
vocabulary from `/api/tags`), description editable inline, and the primary actions from the
action registry (`getActions(project,'svelte')` + `runAction`, as `ProjectActions` does): run dev
/ stop, open hostname, iTerm, Finder, claude-tree. Previous/next project keys are a bonus.

Sections, each a card, each showing everything the scanner has, nothing hidden behind a click
unless it is long:
1. **Overview** — description, README rendered (lazy, `/api/readme`; markdown → reuse whatever the
   console already uses for markdown, else plain pre-wrapped text), stack (type/framework/runner),
   git branch + dirty + flow/drift, modified, template + scaffold-behind warning, domains, umami,
   deploy.
2. **Run** — dev command, scripts and just recipes each with a run button (the existing
   dynamic actions), port, the dev hostname (`HostnameSection` from the settings dialog, reused),
   live processes for this project (`/api/processes?project=`) with a stop button
   (`/api/processes/stop`, `ConfirmDialog`).
3. **Work** — beads counts + "new ticket" (reuse `BeadsDialog` or inline form), agent-log journal
   (`/api/agent-log`: recent events, active intents, latest handoff), Claude sessions (count, last,
   summary).
4. **Claude** — `ClaudeSetup` (MCP servers, agents/commands/skills/rules/hooks), CLAUDE.md /
   AGENTS.md token sizes, link to `/claude-tree?root=<path>`.
5. **Settings** — everything `ProjectSettings` edits today (description, type, framework, slug
   with live check, port, archived, devPublic, the read-only rest of `.atlas`) **plus** domains,
   umami, tags, rename, move (pick a folder — reuse `MoveDialog`), scan overrides
   (`ScanOverrides`), archive. Extract the modal's form into a reusable component used by both
   the page and the modal so there is one form, not two. Unsaved-changes indicator + Save/Reset;
   destructive actions behind `ConfirmDialog`.

The existing modal keeps working (the list still opens it from a row menu) but now renders the
same form component.

## Workstream B — the overview list (owner of `src/routes/+page.svelte`, `src/routes/+page.server.ts`, `src/lib/components/browser/**`, `src/lib/components/table/**`, `src/lib/browser/**`, `src/lib/project-summary.ts`)

1. **Project name links to `/p/<relativePath>`** in table, cards and nested views (a real `<a>`,
   so cmd-click opens a tab; clicking the row elsewhere still expands it inline).
2. **Tags column** in `ProjectTable` (chips, truncated with "+n"), clicking a chip toggles that tag
   filter. Tag facet in `FilterPanel` gets counts and a filter box (272 tags is too many chips —
   show the top ~30 by count, the rest behind the box).
3. **Views live in the URL**: search, tags, type, framework, runner, host, tools, dev/readme,
   promotion, view mode and sort sync to query params (`replaceState`, no history spam), so a
   filtered view is bookmarkable and survives reload. `?tag=a&tag=b` style.
4. **Multi-select + bulk bar**: checkbox column using the `Selection` primitive (shift-click
   ranges per its rules); a sticky bar when ≥1 selected: add tags / remove tags (`TagInput` +
   `PATCH /api/tags`), archive / unarchive (`/api/archive`, `ConfirmDialog`), copy paths, clear.
   Remote projects can't be selected for writes.
5. **Keyboard**: `/` focuses search, `j`/`k` or arrows move a row focus, `Enter` opens the project
   page, `x` toggles selection, `Esc` clears. Visible focus ring.
6. **State at a glance**: the state tag (`active`/`parked`/`dormant`/`archived`) as a small
   coloured dot or badge in the Name cell, and quick state facet chips above the table.

Keep the page a composition root (state + callbacks); new markup goes in components.

## Done means

Both workstreams merged in `atlas-api`, `just check` green, a screenshot of the list (tags column,
bulk bar) and of `/p/multi-stack/deckhand`, and a ≤10-line report: what was built, what was cut
and why, any new route.
