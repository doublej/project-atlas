# Context for `shared/`

## What this is

The registries every consumer must agree on. The registry rules (edit the JSON first, what/when
never how, `selfManaged`, humans-only plists, no IPs) are in the root `../CLAUDE.md`.

- `actions.json` — the **action registry**: what project actions exist, when they apply, which
  consumers show them.
- `daemons.json` — the **daemon registry**: launchd daemons atlas displays/manages.
- `templates.json` — the **template registry**: category folder → ordered suggested cookiecutter
  templates, for `atlas new`.
- `hosts.json` — the **host registry**: machines atlas catalogs, their roots, SSH aliases and
  scan-agent paths. `ssh: null` marks the primary host, the one machine atlas may write to.
- `services.json` — the **service registry**: permanent local web UIs that get a
  `<slug>.atlas.local` hostname. atlas-api only (`$shared/services`); everyone else reads
  `/api/services`. `remote: true` puts a service on `atlas.remote` — atlas-api
  carries shell-exec routes, so never set it without the service password in front.

## How each consumer imports it

- **atlas-api** — the `$shared` alias (`svelte.config.js`) over the `.ts` helpers.
- **atlas-browser** — the compiled JS (`../../shared/actions.js`); TS types mirrored in
  `src/action-registry.ts`.
- **atlas-picker** — `include_str!("../../shared/actions.json")` at compile time; Rust types in
  `src/actions.rs`.

## Important invariants

- **Three consumers must stay in sync.** A field added to `ActionDef` in `actions.ts` does nothing
  in atlas-picker until `src/actions.rs` learns it, and the Rust side won't fail to compile when
  the JSON gains a field. Silent drift is the failure mode.
- **`templates.*` are consumed only by atlas-api and atlas-cli.** Scaffolding is not a
  browser/picker concern: do **not** add `src/templates.rs` or a browser mirror.
- **`hosts.*` are consumed by atlas-api (`$shared/hosts`), atlas-cli (`../../shared/hosts`) and
  `atlas-api/src/lib/scanner.ts` through a *relative* path**, because the scanner also runs
  standalone and bundled on remote hosts, where SvelteKit aliases don't exist. atlas-picker reads
  `Project.host` from the cache and has no mirror.
- **`hosts.json` field names are a contract with deckhand** (`~/dev/multi-stack/deckhand` reads the
  file directly): keep `id` / `label` / `ssh` / `root` / `os` / `role`. `label` is display copy on
  deckhand's phone screen. `node` / `agent` / `skipGit` and the per-host cache fragments are ours.
  Liveness is deckhand's: `status` here is scan-aged (≤10 min).
- **`isLocal` is the write gate.** Every action that touches a filesystem or GUI carries
  `"condition": ["isLocal"]`; only `copy-path`, `deploy-open`, `domain-open`, `umami-open` and
  `refresh` are safe on another machine's project. It is present-only-when-true because conditions
  are existence checks with no equality operator.
- **`condition` / `dynamic` semantics live in the helpers.** `getActions` filters by `consumers` +
  `condition`; `getDynamicActions` expands `scripts` / `justRecipes` / `deploy` / `domains` /
  `umami`. A new `dynamic` kind needs `getDynamicActions` (TS) and `build_subactions` in
  `atlas-picker/src/ui.rs`, plus the condition lookups (`getField` in TS, `meets_condition` in
  Rust).

## Common change patterns

- **New action:** add an entry to `actions.json` (`group`, `icon`, optional
  `condition`/`consumers`); extend `ActionDef` in `actions.ts` only for a new field; mirror in
  `src/action-registry.ts` (browser) and `src/actions.rs` (picker) as needed.
- **New daemon:** an entry in `daemons.json` (`label`, `name`, optional `port`/`project`/`plist`/`logs`/`selfManaged`); no code change.

## Verification

```bash
cd ../atlas-api     && bun run check   # types resolve through $shared aliases
cd ../atlas-browser && npm run build   # browser consumes shared/*.js
cd ../atlas-picker  && just check      # Rust re-embeds + type-checks the JSON
```

Related: `../.claude/rules/shared-types.md` (the Project type-sync rule).
