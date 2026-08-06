# Project Atlas Workspace

A multi-interface workspace for the Atlas API backend and related tools. This repo provides a single bootstrap flow to install and run the pieces you want.

## Components
- `atlas-api`: SvelteKit API/service that exposes the project atlas.
- `atlas-browser`: Raycast extension that talks to the API (macOS only).
- `atlas-picker`: Rust CLI that talks to the API.
- `atlas-watchdog`: Raycast script command (macOS only).

## Quick Start
```bash
./bootstrap.sh
```

## Non-interactive examples
```bash
./bootstrap.sh --list
./bootstrap.sh --apps atlas-api,atlas-picker
./bootstrap.sh --apps atlas-api --run
./bootstrap.sh --apps atlas-api --no-run
```

## One-shot installer (for GitHub)
If you publish this workspace as a GitHub repo, you can offer a single install entry point:
```bash
./install.sh --repo <your-repo-url>
```
This clones the workspace repo and runs `bootstrap.sh` so users can select apps.

## Notes
- Raycast tools only run on macOS. The bootstrapper will skip them on Linux.
- Update `apps.manifest` to add or change apps, tools, or commands.
