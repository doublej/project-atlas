# Verification of report.md against sources and code

Checked: inventory.md numbers, mechanism.md claims against atlas-api/src/routes/api/run/+server.ts
and atlas-api/src/lib/caddyDev.ts, and scaffold.md claims.

## Confirmed correct

- Report table (line 29-36) matches inventory.md summary exactly (458 total, 272/10/135/41).
- 106 .atlas, 17 port, 106 justfile, 2 hostname (line 37) matches inventory.md lines 19-22.
- Tier counts T1-T5 and activity table (lines 41-59) match inventory.md exactly.
- `/api/run` port injection: node/bun/yarn/pnpm branch appends `--port <port> --host 0.0.0.0`
  (+server.ts:62-65); `uv` branch injects nothing (`args = ['run', command]`, +server.ts:55-56);
  `just` branch injects nothing either. Report line 17 and line 91 both hold.
- `ensureRoute`/`removeRouteByPath`/`setPort`/`updateCachedPort`/`allocatePort`/`resolveLocal` all
  exist as named and are called the way Phase 0b (line 89-95) sketches; the hostname-only path is
  a real, minimal reuse — no invented functions.
- Missing project in cache -> `ensureRoute` skipped, response still 200 with no hostname fields
  (+server.ts:95-99, spreading `null`) — "silently skips" (line 19, mechanism sec5/8.2) is accurate.
- Certificate/DNS section (lines 71-79) matches mechanism.md sec9 point for point: no wildcard covers
  the two-labels-deeper atlas hostnames, only `coolify.caddy`'s single-label `*.jurrejan.com`
  wildcard exists; ACME account on LE staging; 50 certs/domain/week production cap; 45 site files,
  2 atlas-managed; DNS wildcard already resolves any depth. `caddyDev.ts:10` does read
  `SUBDOMAIN_LABEL = 'atlas'`, confirming the CLAUDE.md-vs-code label drift claim (line 79).
- Scaffold section (lines 63-70) matches scaffold.md: no template ships `.atlas` in-tree, only
  node-api binds 0.0.0.0, vite templates never pass `--host`, eink/spplx bind behavior, 132/528
  provenance count, 60 unversioned, template counts for sveltekit/python-cli/swift-macos/node-cli/
  node-api/fastapi.
- Phase ordering: no phase depends on a later one (0a/0b are prerequisites for 2, 1 is independent
  scaffold-only work, 3/4 are follow-on). Phase 2 and Phase 3 both carry a stated gate; Phase 3
  explicitly runs per-project with a diff review rather than in bulk, which is the gate for its
  only bulk-shaped, file-rewriting step.

## Wrong or unsupported claim

**Line 63: "Ten template families exist under `_management/cookiecutter-templates`."**

scaffold.md sec1 lists the actual inventory: python has 3 templates (cli, fastapi, flask),
typescript has 9 (bun-package, node-api, node-cli, node-worker, raycast-extension, nextjs,
node-lib, react, sveltekit), plus typescript/tizen-tv separately, go has 2 (cli, api), rust has 1
(cli), swift has 2 (ios, macos), shopify has 1 (theme), android has 1 (quest-vr) — roughly 19-20
distinct templates total. Grouped by top-level language/stack folder there are 7 families (python,
typescript, go, rust, swift, shopify, android). "Ten" matches neither a family-count nor a
template-count reading of scaffold.md; the correct figures are 7 language families comprising
~19-20 individual templates.

## Conclusion

The report holds except for one number: line 63's "Ten template families" is unsupported by
scaffold.md — the source shows 7 top-level families comprising ~19-20 individual templates.
Everything else checked (inventory counts, the port-injection mechanism, the hostname-only Phase
0b sketch, the certificate/DNS section, the scaffold bind-address findings, and phase ordering)
is accurate and traceable to its cited source or code.
