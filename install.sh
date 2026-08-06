#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${INSTALL_REPO_URL:-}"
TARGET_DIR="${INSTALL_DIR:-$HOME/atlas-workspace}"
PASS_ARGS=()

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [--repo <git-url>] [--dir <path>] [bootstrap args...]

Examples:
  ./install.sh --repo git@github.com:your-org/atlas-workspace.git
  ./install.sh --repo https://github.com/your-org/atlas-workspace.git --dir ~/dev/atlas-workspace
  ./install.sh --repo https://github.com/your-org/atlas-workspace.git --apps atlas-api,atlas-picker
USAGE
}

# If we're already in a repo with bootstrap.sh, just forward.
if [[ -f "./bootstrap.sh" ]]; then
  exec ./bootstrap.sh "$@"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --dir)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PASS_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$REPO_URL" ]]; then
  echo "Missing repo URL. Provide --repo or set INSTALL_REPO_URL."
  usage
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install. Please install git first."
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  git clone --depth 1 "$REPO_URL" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
if [[ ! -f "./bootstrap.sh" ]]; then
  echo "bootstrap.sh not found in $TARGET_DIR"
  exit 1
fi

exec ./bootstrap.sh "${PASS_ARGS[@]}"
