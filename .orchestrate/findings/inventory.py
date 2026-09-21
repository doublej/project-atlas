#!/usr/bin/env python3
"""Inventory of local, non-archived atlas projects for dev-hostname migration planning.
Rerunnable: reads .atlas-cache.json + .atlas-hostnames.json + per-project justfile/.atlas, writes
inventory.json and inventory.md next to this script.
"""
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

DEV_ROOT = Path("/Users/jurrejan/Documents/development")
CACHE = DEV_ROOT / ".atlas-cache.json"
HOSTNAMES = DEV_ROOT / ".atlas-hostnames.json"
OUT_DIR = Path(__file__).parent
DEV_RECIPE_NAMES = {"dev", "run", "serve", "start"}

SERVER_FRAMEWORKS = {
    "sveltekit", "next", "nuxt", "vite", "astro", "remix", "express",
    "fastify", "nestjs", "django", "flask", "fastapi", "rails",
}
PY_SERVICE_HINTS = re.compile(r"\buvicorn\b|\bfastapi\b|\bflask\b", re.I)

# atlas-api/src/routes/api/run/+server.ts: type 'just' -> `just <recipe>`, no injection.
# runner 'uv' -> `uv run <cmd>`, no injection. npm/bun/yarn/pnpm (unknown runner falls to npm)
# get `--port <port> --host 0.0.0.0` appended.
NON_CANDIDATE_DIRS = {"_sandbox", "_archive", "_data", "submodules", "vendor"}
HARDCODED_PORT_RE = re.compile(r"--port[= ](\d{2,5})|PORT\s*=\s*['\"]?(\d{2,5})|\bport\s*:\s*(\d{2,5})")
ATLAS_PORT_RANGE = range(4100, 5000)
REFERENCE_DATE = datetime(2026, 9, 3, tzinfo=timezone.utc)


def get_last_commit(project_path: Path):
    """ISO commit date of HEAD, only when project_path itself has a .git (not inherited
    from an ancestor repo)."""
    if not (project_path / ".git").exists():
        return None
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%cI"],
            cwd=project_path,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    date = result.stdout.strip()
    return date or None


def compute_activity(last_commit_iso):
    if not last_commit_iso:
        return "none"
    try:
        commit_dt = datetime.fromisoformat(last_commit_iso)
    except ValueError:
        return "none"
    age_days = (REFERENCE_DATE - commit_dt).days
    if age_days <= 90:
        return "active90"
    if age_days <= 365:
        return "active365"
    return "stale"


def load_json(path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text())


def read_justfile_recipes(project_path: Path):
    """Return {recipe_name: recipe_body_first_line} for dev/run/serve/start recipes."""
    jf = project_path / "justfile"
    if not jf.exists():
        jf = project_path / "Justfile"
    if not jf.exists():
        return {}
    found = {}
    try:
        lines = jf.read_text(errors="replace").splitlines()
    except OSError:
        return {}
    for i, line in enumerate(lines):
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:", line)
        if not m:
            continue
        name = m.group(1)
        if name not in DEV_RECIPE_NAMES:
            continue
        body = ""
        for j in range(i + 1, len(lines)):
            nxt = lines[j]
            if nxt.startswith(("\t", "    ")):
                body = nxt.strip()
                break
            if nxt.strip() == "":
                continue
            break
        found[name] = body
    return found


def read_atlas_file(project_path: Path):
    f = project_path / ".atlas"
    if not f.exists():
        return None
    try:
        return json.loads(f.read_text())
    except (json.JSONDecodeError, OSError):
        return {"__parse_error__": True}


def find_hardcoded_port(project_path: Path, pkg_scripts, justfile_recipes):
    """Scan dev/start script text and common config files for an explicit port number."""
    texts = list(pkg_scripts.values()) + list(justfile_recipes.values())
    for cfg_name in ("vite.config.ts", "vite.config.js", "next.config.js", "next.config.ts", "svelte.config.js"):
        f = project_path / cfg_name
        if f.exists():
            try:
                texts.append(f.read_text(errors="replace"))
            except OSError:
                pass
    for text in texts:
        m = HARDCODED_PORT_RE.search(text)
        if m:
            return int(next(g for g in m.groups() if g))
    return None


def is_candidate(relevance, rel_path, flow_policy):
    if relevance not in ("web-dev-server", "python-service"):
        return False
    parts = Path(rel_path).parts
    if any(p in NON_CANDIDATE_DIRS for p in parts):
        return False
    if flow_policy == "external":
        return False
    if len(parts) > 3:
        return False
    return True


def compute_tier(row):
    """Tier a candidate row using the run route's injection rules (npm/bun/yarn/pnpm get
    --port/--host injected; just and uv do not)."""
    runner = row["runner"]
    has_dev_or_start = bool(row["pkgScripts"].get("dev") or row["pkgScripts"].get("start"))
    atlas_port = (row.get("atlasFile") or {}).get("port") if row["hasAtlasFile"] else None

    if runner in ("npm", "bun", "yarn", "pnpm", None) and has_dev_or_start:
        if atlas_port:
            return "T1", "node runner with dev/start script and an .atlas port on record"
        return "T2", "node runner with dev/start script but no .atlas port yet — first run will allocate one"
    if row["relevance"] == "python-service" or runner == "uv":
        return "T4", "python-service / uv runner: atlas injects nothing, port must come from the app itself"
    if runner == "just" or row["justfileDevRecipes"]:
        return "T3", "just/justfile recipe: atlas injects nothing, recipe must be checked by hand for port/host handling"
    return "T5", f"candidate but no clear dev/start script or justfile recipe (runner={runner})"


def classify(project, justfile_recipes, pkg_scripts):
    framework = (project.get("framework") or "").lower()
    ptype = (project.get("type") or "").lower()
    scripts_blob = " ".join(pkg_scripts.values()) + " " + " ".join(justfile_recipes.values())

    if PY_SERVICE_HINTS.search(scripts_blob) or ptype == "python" and PY_SERVICE_HINTS.search(
        json.dumps(project.get("description") or "")
    ):
        return "python-service"
    if project.get("port") or framework in SERVER_FRAMEWORKS or pkg_scripts.get("dev") or pkg_scripts.get("start") or justfile_recipes:
        return "web-dev-server"
    if ptype in ("node", "python", "rust") and not project.get("port"):
        return "cli-or-lib"
    return "unknown"


def main():
    cache = load_json(CACHE, {})
    hostnames = load_json(HOSTNAMES, {})
    projects = cache.get("projects", [])

    rows = []
    notes = []

    for p in projects:
        if not p.get("isLocal"):
            continue
        if p.get("archived"):
            continue
        rel = p.get("relativePath", "")
        if "_archive" in Path(rel).parts:
            continue

        project_path = Path(p["path"])
        justfile_recipes = read_justfile_recipes(project_path) if p.get("hasJustfile") else {}
        pkg_scripts_all = p.get("scripts") or {}
        pkg_scripts = {k: v for k, v in pkg_scripts_all.items() if k in ("dev", "start")}
        atlas_file = read_atlas_file(project_path)

        slug = p.get("slug", "")
        flow = p.get("flow") or {}
        row = {
            "relativePath": rel,
            "name": p.get("name"),
            "slug": slug,
            "type": p.get("type"),
            "framework": p.get("framework"),
            "runner": p.get("runner"),
            "gitOwner": flow.get("owner"),
            "flowPolicy": flow.get("policy"),
            "hasJustfile": bool(p.get("hasJustfile")),
            "justfileDevRecipes": justfile_recipes,
            "pkgScripts": pkg_scripts,
            "hasAtlasFile": atlas_file is not None,
            "atlasFile": atlas_file,
            "port": p.get("port"),
            "hostnameRegistered": slug in hostnames,
        }
        row["relevance"] = classify(p, justfile_recipes, pkg_scripts)
        if row["relevance"] == "unknown":
            notes.append(f"{rel}: type={p.get('type')} framework={p.get('framework')} no port/scripts/justfile signal")
        if atlas_file and atlas_file.get("__parse_error__"):
            notes.append(f"{rel}: .atlas present but failed to parse as JSON")

        row["candidate"] = is_candidate(row["relevance"], rel, flow.get("policy"))
        if row["candidate"]:
            tier, tier_notes = compute_tier(row)
            row["tier"] = tier
            row["tierNotes"] = tier_notes
        else:
            row["tier"] = None
            row["tierNotes"] = None
        row["nested"] = False  # filled in below, needs all candidate paths first
        hp = find_hardcoded_port(project_path, pkg_scripts, justfile_recipes)
        row["hardcodedPort"] = hp
        if row["candidate"]:
            last_commit = get_last_commit(project_path)
            row["lastCommit"] = last_commit
            row["activity"] = compute_activity(last_commit)
        else:
            row["lastCommit"] = None
            row["activity"] = None
        rows.append(row)

    # nested: another candidate's relativePath is an ancestor directory of this one
    candidate_paths = [Path(r["relativePath"]) for r in rows if r["candidate"]]
    for r in rows:
        if not r["candidate"]:
            continue
        this_path = Path(r["relativePath"])
        for other in candidate_paths:
            if other == this_path:
                continue
            try:
                this_path.relative_to(other)
                r["nested"] = True
                break
            except ValueError:
                continue

    # slugDup: two or more rows share a slug
    slug_counts = {}
    for r in rows:
        slug_counts[r["slug"]] = slug_counts.get(r["slug"], 0) + 1
    for r in rows:
        r["slugDup"] = slug_counts.get(r["slug"], 0) > 1
        r["slugLong"] = len(r["slug"] or "") > 63

    OUT_DIR.joinpath("inventory.json").write_text(json.dumps(rows, indent=2, sort_keys=True))

    buckets = {}
    for r in rows:
        buckets.setdefault(r["relevance"], []).append(r)

    summary_lines = ["# Local project inventory", "", "## Summary", ""]
    summary_lines.append(f"- Total local, non-archived projects: {len(rows)}")
    summary_lines.append("- By bucket:")
    for bucket in sorted(buckets):
        summary_lines.append(f"  - {bucket}: {len(buckets[bucket])}")
    cat_counts = {}
    for r in rows:
        cat_counts[r["type"]] = cat_counts.get(r["type"], 0) + 1
    summary_lines.append("- By type:")
    for cat in sorted(cat_counts, key=lambda k: (k is None, k)):
        summary_lines.append(f"  - {cat}: {cat_counts[cat]}")
    summary_lines.append(f"- Have .atlas file: {sum(1 for r in rows if r['hasAtlasFile'])}")
    summary_lines.append(f"- Have a detected port: {sum(1 for r in rows if r['port'])}")
    summary_lines.append(f"- Have a justfile dev/run/serve/start recipe: {sum(1 for r in rows if r['justfileDevRecipes'])}")
    summary_lines.append(f"- Have a registered dev hostname: {sum(1 for r in rows if r['hostnameRegistered'])}")
    summary_lines.append("")

    candidates = [r for r in rows if r["candidate"]]
    tier_counts = {}
    tier_by_type = {}
    for r in candidates:
        tier_counts[r["tier"]] = tier_counts.get(r["tier"], 0) + 1
        tier_by_type.setdefault(r["tier"], {})
        tier_by_type[r["tier"]][r["type"]] = tier_by_type[r["tier"]].get(r["type"], 0) + 1
    nested_count = sum(1 for r in candidates if r["nested"])
    slug_dup_rows = [r for r in rows if r["slugDup"]]
    slug_long_rows = [r for r in rows if r["slugLong"]]
    hardcoded_outside_range = [r for r in rows if r["hardcodedPort"] and r["hardcodedPort"] not in ATLAS_PORT_RANGE]

    migration_lines = ["## Migration candidates", ""]
    migration_lines.append(f"- Total candidates: {len(candidates)}")
    for tier in sorted(tier_counts):
        migration_lines.append(f"  - {tier}: {tier_counts[tier]}")
        for cat, cnt in sorted(tier_by_type[tier].items(), key=lambda kv: (kv[0] is None, kv[0])):
            migration_lines.append(f"    - {cat}: {cnt}")
    migration_lines.append(f"- Nested (monorepo child of another candidate): {nested_count}")
    migration_lines.append("")

    activity_order = ["active90", "active365", "stale", "none"]
    cross = {tier: {a: 0 for a in activity_order} for tier in sorted(tier_counts)}
    for r in candidates:
        cross[r["tier"]][r["activity"]] += 1
    migration_lines.append("### Tier by activity")
    migration_lines.append("")
    migration_lines.append("| tier | active90 | active365 | stale | none |")
    migration_lines.append("|---|---|---|---|---|")
    for tier in sorted(tier_counts):
        migration_lines.append(
            f"| {tier} | {cross[tier]['active90']} | {cross[tier]['active365']} | "
            f"{cross[tier]['stale']} | {cross[tier]['none']} |"
        )
    migration_lines.append("")

    active90_rows = [r for r in candidates if r["activity"] == "active90"]
    migration_lines.append(f"### active90 candidates ({len(active90_rows)})")
    migration_lines.append("")
    migration_lines.append("| path | tier | runner | port | hardcodedPort |")
    migration_lines.append("|---|---|---|---|---|")
    for r in sorted(active90_rows, key=lambda x: x["relativePath"]):
        migration_lines.append(
            f"| {r['relativePath']} | {r['tier']} | {r['runner'] or '-'} | {r['port'] or '-'} | "
            f"{r['hardcodedPort'] or '-'} |"
        )
    migration_lines.append("")
    migration_lines.append(f"### Duplicate slugs ({len(slug_dup_rows)})")
    migration_lines.append("")
    if slug_dup_rows:
        for r in sorted(slug_dup_rows, key=lambda x: (x["slug"], x["relativePath"])):
            migration_lines.append(f"- `{r['slug']}` — {r['relativePath']}")
    else:
        migration_lines.append("- none")
    migration_lines.append("")
    migration_lines.append(f"### Slugs over 63 chars ({len(slug_long_rows)})")
    migration_lines.append("")
    if slug_long_rows:
        for r in sorted(slug_long_rows, key=lambda x: x["relativePath"]):
            migration_lines.append(f"- `{r['slug']}` ({len(r['slug'])} chars) — {r['relativePath']}")
    else:
        migration_lines.append("- none")
    migration_lines.append("")
    migration_lines.append(f"### Hardcoded ports outside 4100-4999 ({len(hardcoded_outside_range)})")
    migration_lines.append("")
    if hardcoded_outside_range:
        for r in sorted(hardcoded_outside_range, key=lambda x: x["relativePath"]):
            migration_lines.append(f"- {r['relativePath']}: port {r['hardcodedPort']}")
    else:
        migration_lines.append("- none")
    migration_lines.append("")

    md = summary_lines + migration_lines
    for bucket in sorted(buckets):
        md.append(f"## {bucket} ({len(buckets[bucket])})")
        md.append("")
        md.append(
            "| path | name | slug | type | framework | runner | git owner | flow | justfile | pkg dev/start | "
            "port | hostname | .atlas | candidate | tier | nested | hardcodedPort | slugDup | slugLong |"
        )
        md.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
        for r in sorted(buckets[bucket], key=lambda x: x["relativePath"]):
            jf = ", ".join(f"{k}: `{v}`" for k, v in r["justfileDevRecipes"].items()) or "-"
            pk = ", ".join(f"{k}: `{v}`" for k, v in r["pkgScripts"].items()) or "-"
            atlas_str = "yes" if r["hasAtlasFile"] else "-"
            tier_str = f"{r['tier']} ({r['tierNotes']})" if r["tier"] else "-"
            md.append(
                f"| {r['relativePath']} | {r['name']} | {r['slug']} | {r['type']} | {r['framework'] or '-'} | "
                f"{r['runner'] or '-'} | {r['gitOwner'] or '-'} | {r['flowPolicy'] or '-'} | {jf} | {pk} | "
                f"{r['port'] or '-'} | {'yes' if r['hostnameRegistered'] else '-'} | {atlas_str} | "
                f"{'yes' if r['candidate'] else '-'} | {tier_str} | {'yes' if r['nested'] else '-'} | "
                f"{r['hardcodedPort'] or '-'} | {'yes' if r['slugDup'] else '-'} | {'yes' if r['slugLong'] else '-'} |"
            )
        md.append("")

    md.append("## Notes: unclassified or anomalous")
    md.append("")
    if notes:
        for n in notes:
            md.append(f"- {n}")
    else:
        md.append("- none")

    OUT_DIR.joinpath("inventory.md").write_text("\n".join(md) + "\n")

    print(f"projects scanned (raw cache): {len(projects)}")
    print(f"kept (local, non-archived, not under _archive): {len(rows)}")
    for bucket in sorted(buckets):
        print(f"  {bucket}: {len(buckets[bucket])}")


if __name__ == "__main__":
    main()
