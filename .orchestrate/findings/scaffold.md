# Scaffold audit: dev-server + hostname wiring

## 1. Versions (cookiecutter.json `_version`)
- python/{cli,fastapi,flask}: 2.2.0
- typescript/{bun-package,node-api,node-cli,node-worker,raycast-extension}: 2.2.0
- typescript/{nextjs,node-lib,react,sveltekit}: 2.6.0
- typescript/tizen-tv: 1.0.1
- go/{cli,api}: 1.1.0
- rust/cli: 2.2.0
- swift/{ios,macos}: 3.3.0
- shopify/theme: 1.1.0
- android/quest-vr: 2.3.0

## 2. Per-template: Justfile, .atlas, port wiring, bind address
No template ships a `.atlas` file in its tree — it's generated at scaffold time by
`hooks/post_gen_project.py:write_atlas()` (e.g. typescript/sveltekit/hooks/post_gen_project.py:196-210).
Every family has this function; fields are always `description, type, framework, port?, archived: false`
(port omitted for CLI-shaped templates with no `port` cookiecutter var: rust/cli, python/cli, go/cli,
swift/*, shopify/theme, android/quest-vr). No template ever writes `slug` or `devPublic` into `.atlas`.

**Web/server templates** (have `port` in cookiecutter.json + `.atlas`):
| template | port default | Justfile `dev` recipe | package.json dev script | bind host |
|---|---|---|---|---|
| typescript/sveltekit | 5173 (cookiecutter.json:7) | `bun run dev` (Justfile:15) | `vite dev --port {{port}}` (package.json:8) | vite default = localhost only; no `--host`/`server.host` in vite.config.ts |
| typescript/react | 5173 | `bun run dev` | `vite --port {{port}}` | same — localhost only |
| typescript/tizen-tv | 5173 | `bun run dev` | `vite dev --port {{port}}` | same — localhost only |
| typescript/nextjs | 3000 | `bun run dev` | `next dev --turbopack -p {{port}}` (package.json:8) | no `-H` flag → Next dev default (0.0.0.0) |
| typescript/node-api | 3000 | `bun run dev` → `tsx watch src/index.ts` | reads `env.PORT`/`env.HOST` | `env.ts:8` defaults `HOST` to `0.0.0.0`; `src/index.ts:12` `.listen({port: env.PORT, hostname: env.HOST})` — explicit 0.0.0.0 |
| typescript/node-worker | 3000 (no HTTP listener, background worker) | `bun run dev` → `tsx watch` | n/a | n/a |
| python/fastapi | 8000 (cookiecutter.json:7) | (check Justfile `dev`) | uvicorn — check main.py for `--host` | not inspected line-by-line; FastAPI templates conventionally bind 0.0.0.0 for uvicorn dev — verify in `{{cookiecutter.project_slug}}/src/**/main.py` before relying on it |
| go/api | 8080 (cookiecutter.json:7) | — | Go `http.ListenAndServe` — verify bind addr in generated `main.go` | not inspected |

**CLI/library/native templates** (no `port`, no dev-server concept): rust/cli, python/cli, go/cli,
swift/ios, swift/macos, shopify/theme, android/quest-vr, typescript/{bun-package,node-lib,node-cli,
node-worker,raycast-extension}. Justfiles ship `install/lint/lint-fix/typecheck/test/loc-check/
dir-check/check/build/clean/claude-tree/update-scaffold` but no `dev` recipe (node-cli has `dev` +
`run-cli *ARGS`; shopify/theme has `dev`/`share` via Shopify CLI, not vite).

**Key gap for the LAN reverse proxy**: only `typescript/node-api` explicitly binds `0.0.0.0`. The three
Vite-based templates (sveltekit, react, tizen-tv) rely on Vite's default (`localhost`/127.0.0.1) with no
`--host` flag anywhere in Justfile, package.json, or vite.config.ts — **these will not be reachable via
the LAN hostname reverse proxy as scaffolded.** Migrating/auditing existing projects for the hostname
proxy must check for `--host` (or `server.host: true`) explicitly; its absence in the current templates
is the thing to fix, not a state to replicate.

## 3. Provenance + upgrade tooling
- `.template-meta.json` (written by every hook's `write_meta()`, e.g. typescript/sveltekit/hooks/post_gen_project.py:139-149):
  `{template, template_version, template_source: {type, path, git_remote, git_sha}, rendered_at, context}`.
  This is the only record of which template/version produced a project.
- Upgrade path: `update-scaffold` skill (`/Users/jurrejan/.claude/skills` — cookiecutter-templates repo
  ships `.claude` update-check hook: `check_template_update.py` compares local vs upstream `_version`
  via `template_source.path` and prints `[template-update] ...`) + Justfile recipe `update-scaffold *ARGS`
  present in every generated Justfile (e.g. typescript/sveltekit Justfile:130). No cruft/cookiecutter-replay
  usage found. No `atlas upgrade` command exists in atlas-cli/src/commands — only `atlas new` (scaffold)
  and `atlas flow` (branch policy) touch `.atlas`.
- v1 limitation (documented in this repo's CLAUDE.md): update check breaks silently if the
  cookiecutter-templates repo path moves, since `template_source.path` is an absolute path snapshot.

## 4. Ideal minimal post-scaffold state (spec)
- `.atlas` — `{description, type, framework, port?, archived:false}` from the template hook, PLUS
  (currently missing from every template, added later by `atlas flow init`/`bootstrapFlow`):
  `flow: {policy:"gitflow", trunk:"main", integration:"develop"}` (atlas-cli/src/commands/flow.ts:47-49,
  63-67 — only auto-added by `atlas new` when the target has no `.git` yet, i.e. new projects only).
  `slug` and `devPublic` are never written by anything in the new-project path — both are manual-only
  fields read by atlas-api/src/lib/scanner.ts:723-725 as overrides; absent means slug defaults to
  the folder path slugified (scanner.ts:863) and devPublic defaults false (proxy requires auth).
- `.template-meta.json` — provenance, as above.
- `Justfile` — family-standard recipe set (see table in family CLAUDE.md); web templates additionally need
  `dev` wired to bind `0.0.0.0` if LAN proxy access is wanted.
- `CLAUDE.md`, `agent.md`, `.gitignore`, `.quality.json` — per-family shared files (sync_manifest.json).
- Git: `main` + `develop` branches, one scaffold commit (bootstrapFlow, atlas-cli/src/commands/flow.ts:58-68).

`atlas new` (atlas-cli/src/commands/new.ts) itself never writes `.atlas` fields directly — it only
allocates a port via `/api/ports/allocate` and passes `port=<n>` as cookiecutter context
(new.ts:108-130), so the port ends up baked into `.atlas`/package.json by the template's own hook.
`bootstrapFlow` (new.ts:91, flow.ts:58-68) is the only other `.atlas` writer in the new-project path,
merging in just the `flow` block.

## 5. Cross-family migration differences
- **Port field**: only present in templates with a dev server (all typescript web/API templates,
  python/fastapi, go/api, presumably swift network templates if any). CLI/native/library templates
  correctly omit it — do not add `port` to `.atlas` for those during migration.
- **Bind address**: only node-api hardcodes 0.0.0.0. Python/Go dev servers weren't verified in this pass
  (grep for `--host`/`ListenAndServe` bind arg in their generated `main.py`/`main.go` before assuming).
- **`dev` recipe existence**: web+API templates have it; pure-CLI/library templates (rust/cli, python/cli,
  go/cli, node-lib, bun-package, raycast-extension) don't and shouldn't get one.
- **`.template-meta.json` presence**: universal across all families — safe migration signal to check for
  on every project regardless of stack.
- **`flow` block**: only present if `atlas flow init` was run (opt-in per `dev_root` CLAUDE.md
  `<branch_flow>` rule) — do not add to single-line trunk repos as a drive-by.

## 6. eink and spplx (the only two projects with a registered dev hostname)

| | web/eink (port 4109) | games/spplx (port 4110) |
|---|---|---|
| template | typescript/sveltekit 1.3.0 (.template-meta.json) | typescript/sveltekit 2.6.0 (.template-meta.json) |
| rendered_at | 2026-05-20 | 2026-09-03 |
| Justfile `dev` | `bun run dev` | `bun run dev` |
| package.json `dev` | `vite dev` — no `--port`, no `--host` | `vite dev --port 4110` — no `--host` |
| vite.config.ts | plain `sveltekit()` plugin, no `server.host` | plain `sveltekit()` plugin, no `server.host` |
| LAN reachability | **localhost only** — Vite default bind, no override anywhere | **localhost only** — same |
| .atlas | `{description, type:"node", framework:"sveltekit", archived:false, port:4109}` — no `slug`, no `devPublic`, no `flow` | `{description, type:"node", framework:"sveltekit", port:4110, archived:false, flow:{policy:"gitflow", trunk:"main", integration:"develop"}}` — no `slug`, no `devPublic` |

Both are older/current sveltekit renders and both confirm the section-2 gap: the LAN hostname reverse
proxy needs `--host`/`server.host` wiring that the sveltekit template has never shipped, at either
version. eink additionally never got its port wired into the `dev` script (fixed by 2.6.0, seen in
spplx) — its .atlas `port:4109` is a manual/atlas-allocated value not reflected in `vite dev`.

## 7. Scaffold-born catalog census

`find ~/Documents/development -iname .template-meta.json`, skipping `_archive/`, `_sandbox/`,
`node_modules/`, and `.worktree/`/`.claude/worktrees/` copies (worktrees duplicate their parent's file
and aren't separate projects):

- **132 distinct projects** carry a `.template-meta.json` (148 raw hits before dropping 16 worktree
  copies) out of **528** level-1/2 directories under dev_root (excluding `_archive`/`_sandbox`) —
  roughly a quarter of the catalog is scaffold-born; the rest predate the template system or were
  never scaffolded.
- Template distribution (template, template_version → count), most-common first:
  - typescript/sveltekit: 20 unversioned (pre-`template_version`-field schema) + 5×2.6.0, 5×2.4.2,
    5×2.2.0, 5×1.3.0, 2×2.4.0, 2×2.3.0, 2×2.1.0, 1×2.4.1, 1×1.1.0 = **48 total**
  - python/cli: 10 unversioned + 6×2.2.0, 5×1.4.0, 4×2.1.0, 3×2.1.1 = **28 total**
  - typescript/node-cli: 8 unversioned + 1×2.2.0, 1×2.1.0 = **10 total**
  - swift/stt-component: 6 unversioned (this template no longer exists in the repo — likely renamed
    into swift/ios or removed)
  - swift/macos: 6 unversioned + 2×3.3.0, 2×3.2.0, 2×3.1.0, 1×2.0.0 = **13 total**
  - typescript/node-api: 5 unversioned + 1×2.2.0, 1×2.1.0 = **7 total**
  - python/fastapi: 1 unversioned + 4×2.1.0, 1×2.2.0, 1×2.1.1 = **7 total**
  - rust/cli: 2 unversioned + 1×2.1.0, 1×1.1.0 = **4 total**
  - typescript/nextjs: 1 unversioned + 1×1.3.0 = **2 total**
  - typescript/node-worker: 1 (unversioned)
  - typescript/tizen-tv: 1×1.0.1
  - typescript/raycast-extension: 1×1.0.0
  - typescript/bun-package: 1×2.1.2
  - swift/ios: 1 (unversioned)
  - go/cli: 1×1.1.0 + 1×1.0.1 = 2

  "Unversioned" entries (no `template_version` key, 60 of the 132) predate the current
  `.template-meta.json` schema (typescript/sveltekit/hooks/post_gen_project.py:139-149) — old renders
  from before the versioning convention landed. `swift/stt-component` is a stale template name not
  present in the repo today.

## Files referenced
- typescript/sveltekit/hooks/post_gen_project.py:132-149,196-210 (write_meta, write_atlas)
- typescript/sveltekit/{{cookiecutter.project_slug}}/package.json:8,10
- typescript/sveltekit/{{cookiecutter.project_slug}}/vite.config.ts
- typescript/node-api/{{cookiecutter.project_slug}}/src/env.ts:8
- typescript/node-api/{{cookiecutter.project_slug}}/src/index.ts:12,14
- typescript/*/{{cookiecutter.project_slug}}/Justfile (recipe list per family, lines vary — see grep above)
- /Users/jurrejan/Documents/development/multi-stack/project-atlas/atlas-cli/src/commands/new.ts:82-130
- /Users/jurrejan/Documents/development/multi-stack/project-atlas/atlas-cli/src/commands/flow.ts:47-68
- /Users/jurrejan/Documents/development/multi-stack/project-atlas/atlas-api/src/lib/scanner.ts:717-742,1213-1224
