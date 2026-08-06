#!/usr/bin/env bash
set -euo pipefail

color_reset="\033[0m"
color_red="\033[0;31m"
color_yellow="\033[0;33m"
color_green="\033[0;32m"
color_blue="\033[0;34m"

log() { echo -e "${color_blue}==>${color_reset} $*"; }
warn() { echo -e "${color_yellow}WARN:${color_reset} $*"; }
err() { echo -e "${color_red}ERROR:${color_reset} $*" 1>&2; }

detect_os() {
  local uname_out
  uname_out="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$uname_out" in
    darwin*) echo "darwin" ;;
    linux*) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  echo "$s"
}

split_csv() {
  local csv="$1"
  csv="$(echo "$csv" | tr -d '[:space:]')"
  if [[ -z "$csv" ]]; then
    echo ""
    return
  fi
  echo "$csv" | tr ',' '\n'
}

has_tool() {
  command -v "$1" >/dev/null 2>&1
}

missing_tools_for() {
  local tools_csv="$1"
  local missing=()
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    if ! has_tool "$tool"; then
      missing+=("$tool")
    fi
  done < <(split_csv "$tools_csv")

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s
' "${missing[@]}"
  fi
}

install_hint() {
  local tool="$1"
  case "$tool" in
    bun)
      echo "Install bun: curl -fsSL https://bun.sh/install | bash"
      ;;
    cargo|rustc|rustup)
      echo "Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
      ;;
    ray)
      echo "Install Raycast and enable the ray CLI (macOS only)."
      ;;
    node|npm)
      echo "Install Node.js (recommended: https://nodejs.org or a version manager)."
      ;;
    lsof)
      echo "Install lsof via your package manager (macOS: preinstalled)."
      ;;
    git)
      echo "Install git via your package manager."
      ;;
    *)
      echo "Install $tool via your package manager."
      ;;
  esac
}
