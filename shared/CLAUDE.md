# Context for `shared/`

## What this is

The single source of truth for things all three UI consumers (atlas-api, atlas-browser, atlas-picker) must agree on:

- `actions.json` — the project **action registry** (open, run, copy, deploy, agent, …): what actions exist, when they apply, and which consumers show them.
- `daemons.json` — the **daemon registry**: which launchd daemons atlas displays/manages.
- `templates.json` — the **template registry**: category folder → ordered list of suggested cookiecutter templates, used by `atlas new`.

> **Exception to the three-consumer-sync rule:** `templates.json` / `templates.ts` are consumed **only** by atlas-api (`$shared/templates`) and atlas-cli (`atlas new`). Scaffolding is not a browser/picker concern, so the Rust + Raycast mirrors are intentionally absent — do **not** add `src/templates.rs` or a browser mirror to "stay in sync".

The `.ts` files (`actions.ts`, `daemons.ts`) are TypeScript types + helper functions over the JSON, imported by the two TS consumers. The Rust consumer re-declares equivalent types and reads the JSON directly.

## Mental model

JSON is data; consumers are renderers. The registry defines **what** an action is and **when** it appears (`condition`, `dynamic`, `consumers`) — never **how** it executes. Each consumer keeps its own execution logic:

- **atlas-api** — imports via the `$shared/actions` / `$shared/daemons` aliases (configured in `svelte.config.js`).
- **atlas-browser** — imports the compiled JS (`../../shared/actions.js`); TS types mirrored in `src/action-registry.ts`.
- **atlas-picker** — embeds the JSON at compile time via `include_str!("../../shared/actions.json")`; Rust types in `src/actions.rs`.

## Important invariants

- **Edit the JSON first.** Adding/removing/changing an action or daemon starts here, not in a consumer. Then update consumer-specific rendering only if the new shape needs it.
- **Three consumers must stay in sync.** A field added to `ActionDef` in `actions.ts` has no effect in atlas-picker until `src/actions.rs` learns about it (and vice versa). The Rust side won't fail to compile just because the JSON gained a field — silent drift is the failure mode.
- **`condition` / `dynamic` semantics live in the helpers.** `getActions` filters by `consumers` + `condition`; `getDynamicActions` expands `scripts` / `justRecipes` / `deploy` / `domains` / `umami`. If you add a new `dynamic` kind, update both `getDynamicActions` (TS) and the Rust expansion logic (`build_subactions` in `atlas-picker/src/ui.rs`), plus the `condition` field lookups (`getField` in TS, `meets_condition` in Rust).
- **`selfManaged: true` blocks lifecycle actions.** `com.jurrejan.atlas-api` carries this flag so the API refuses to start/stop/restart itself — atlas-watchdog is its sole supervisor. Don't remove the flag to "fix" a daemon action.
- Plists are referenced here but **edited by humans only** — atlas never writes plist files.

## Common change patterns

- **New action:** add an entry to `actions.json` (give it `group`, `icon`, optional `condition`/`consumers`); extend the `ActionDef` interface in `actions.ts` only if it needs a new field; mirror in `src/action-registry.ts` (browser) and `src/actions.rs` (picker) as needed.
- **New daemon:** add an entry to `daemons.json` (`label`, `name`, optional `port`/`project`/`plist`/`logs`). No code change needed in the helpers.

## Verification

```bash
cd ../atlas-api    && bun run check   # types resolve through $shared aliases
cd ../atlas-browser && npm run build   # browser consumes shared/*.js
cd ../atlas-picker  && just check      # Rust re-embeds + type-checks the JSON
```

## Related context

- Root [`../CLAUDE.md`](../CLAUDE.md) — workspace overview, full endpoint table, registry conventions.
- [`.claude/rules/shared-types.md`](../.claude/rules/shared-types.md) — the type-sync rule across the three consumer files.
