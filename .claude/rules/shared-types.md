---
paths:
  - "atlas-api/src/lib/scanner.ts"
  - "atlas-browser/src/scanner.ts"
  - "atlas-picker/src/project.rs"
---

# Shared scanner types — keep three consumers in sync

`atlas-api/src/lib/scanner.ts` is the **source of truth** for the `Project` / `ProjectAtlas` shape (it produces `.atlas-cache.json` and the `/api/projects` response). Two consumers re-declare the same shape and **will not fail to compile when they drift** — that silent drift is the bug this rule prevents.

When you change a type in any of these files, update all three:

| File | Language | Convention |
|------|----------|------------|
| `atlas-api/src/lib/scanner.ts` | TS (source) | `camelCase` fields — emitted as-is to JSON |
| `atlas-browser/src/scanner.ts` | TS (consumer) | `camelCase`, must match the API field names exactly |
| `atlas-picker/src/project.rs` | Rust (consumer) | `snake_case` fields; map to the JSON names with `#[serde(rename = "...")]` / serde rename, e.g. `relative_path` ↔ `relativePath`, `project_type` ↔ `type`, `dev_command` ↔ `devCommand` |

## Checklist when editing a `Project` field

1. Add/change the field in `scanner.ts` (the API).
2. Mirror it in `atlas-browser/src/scanner.ts`.
3. Mirror it in `atlas-picker/src/project.rs` with the correct serde mapping (and `#[serde(default)]` if optional).
4. A field that exists only in the API (no consumer mirror) is dead weight in the picker/browser — either wire it through both consumers or don't ship it.

## Verify

```bash
cd atlas-api    && bun run check   # source types
cd atlas-browser && npm run build   # consumer 1
cd atlas-picker  && just check      # consumer 2 (clippy + fmt + build)
```

Related: [`shared/CLAUDE.md`](../../shared/CLAUDE.md) covers the action/daemon registries, which follow the same three-consumer-sync pattern.
