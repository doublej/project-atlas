# Context for `shared/`

## What this is

The single source of truth for things all three UI consumers (atlas-api, atlas-browser, atlas-picker) must agree on:

- `actions.json` — the project **action registry** (open, run, copy, deploy, agent, …): what actions exist, when they apply, and which consumers show them.
- `daemons.json` — the **daemon registry**: which launchd daemons atlas displays/manages.
- `templates.json` — the **template registry**: category folder → ordered list of suggested cookiecutter templates, used by `atlas new`.
- `hosts.json` — the **host registry**: the machines atlas catalogs (`m2` primary, `fractal` satellite, `ubuntu` deploy), their roots, SSH aliases and scan-agent paths.

> **Exception to the three-consumer-sync rule:** `templates.json` / `templates.ts` are consumed **only** by atlas-api (`$shared/templates`) and atlas-cli (`atlas new`). Scaffolding is not a browser/picker concern, so the Rust + Raycast mirrors are intentionally absent — do **not** add `src/templates.rs` or a browser mirror to "stay in sync".

> **Second exception:** `hosts.json` / `hosts.ts` are consumed by atlas-api (`$shared/hosts`),
> atlas-cli (`../../shared/hosts`) and — deliberately — by `atlas-api/src/lib/scanner.ts` through a
> *relative* path, because the scanner also runs standalone (`bun run scan`) and is bundled for
> remote hosts, where SvelteKit's aliases do not exist. atlas-picker has no mirror: it reads
> `Project.host` out of the cache and never needs the registry.

**Never put an IP in `hosts.json`.** Every machine on this LAN is DHCP with no reservation; the
M2's address already drifted once and silently broke a cross-machine sync. SSH aliases only.
`ssh: null` marks the primary host — the one machine atlas is allowed to write to.

**`hosts.json` has one consumer outside this repo.** deckhand's Python daemon
(`~/dev/multi-stack/deckhand`) reads the file directly for its machine list — the same deal
atlas-picker has with the cache, and the reason `id` / `label` / `ssh` / `root` / `os` / `role`
are now names to keep: a rename breaks a repo that will not fail to compile here. `label` is the
word on deckhand's machines screen, so it is display copy for a phone, not just a dev-console
string. `node` / `agent` / `skipGit` stay ours — nothing outside reads them. The per-host cache
fragments (`~/dev/.atlas-cache-<id>.json`) are **not** part of that deal — unversioned plumbing
between `remoteScan.ts` and `finalizeAtlas`. Liveness is deckhand's, not atlas's: `status` here is
scan-aged (≤10 min), which is right for a catalog and wrong for an online/offline dot.

The `.ts` files (`actions.ts`, `daemons.ts`, `hosts.ts`) are TypeScript types + helper functions over the JSON, imported by the two TS consumers. The Rust consumer re-declares equivalent types and reads the JSON directly.

## Mental model

JSON is data; consumers are renderers. The registry defines **what** an action is and **when** it appears (`condition`, `dynamic`, `consumers`) — never **how** it executes. Each consumer keeps its own execution logic:

- **atlas-api** — imports via the `$shared/actions` / `$shared/daemons` aliases (configured in `svelte.config.js`).
- **atlas-browser** — imports the compiled JS (`../../shared/actions.js`); TS types mirrored in `src/action-registry.ts`.
- **atlas-picker** — embeds the JSON at compile time via `include_str!("../../shared/actions.json")`; Rust types in `src/actions.rs`.

## Important invariants

- **Edit the JSON first.** Adding/removing/changing an action or daemon starts here, not in a consumer. Then update consumer-specific rendering only if the new shape needs it.
- **Three consumers must stay in sync.** A field added to `ActionDef` in `actions.ts` has no effect in atlas-picker until `src/actions.rs` learns about it (and vice versa). The Rust side won't fail to compile just because the JSON gained a field — silent drift is the failure mode.
- **`isLocal` is the write gate.** 25 of the 30 actions carry `"condition": ["isLocal"]`; only
  `copy-path`, `deploy-open`, `domain-open`, `umami-open` and `refresh` are safe on another
  machine's project. `isLocal` is present-only-when-true on purpose — conditions are existence
  checks with no equality operator, so this needed no change to the condition grammar. It is the
  *second* layer: `/api/*` write routes reject a non-local path with 400 on their own.
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
