#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$ROOT_DIR/apps.manifest"

# shellcheck source=scripts/common.sh
source "$ROOT_DIR/scripts/common.sh"

usage() {
  cat <<'USAGE'
Usage: ./bootstrap.sh [options]

Options:
  --list                  List available apps
  --apps <ids>            Comma-separated app ids (e.g., atlas-api,atlas-picker)
  --all                   Select all apps
  --run                   Run selected apps after install (default)
  --no-run                Do not run apps after install
  --non-interactive       Do not prompt (defaults to --all if --apps not set)
  --background            Run selected apps in background (logs in .run-logs)
  --foreground            Run a single app in foreground
  -h, --help              Show help
USAGE
}

if [[ ! -f "$MANIFEST" ]]; then
  err "Missing manifest: $MANIFEST"
  exit 1
fi

# Arrays (bash 3.2 compatible)
APP_ID=()
APP_NAME=()
APP_PATH=()
APP_TOOLS=()
APP_INSTALL=()
APP_RUN=()
APP_OS=()
APP_DEPS=()

APP_COUNT=0
while IFS='|' read -r id name path tools install_cmd run_cmd os deps; do
  id="$(trim "$id")"
  [[ -z "$id" ]] && continue
  [[ "$id" == \#* ]] && continue

  APP_ID[$APP_COUNT]="$(trim "$id")"
  APP_NAME[$APP_COUNT]="$(trim "$name")"
  APP_PATH[$APP_COUNT]="$(trim "$path")"
  APP_TOOLS[$APP_COUNT]="$(trim "$tools")"
  APP_INSTALL[$APP_COUNT]="$(trim "$install_cmd")"
  APP_RUN[$APP_COUNT]="$(trim "$run_cmd")"
  APP_OS[$APP_COUNT]="$(trim "$os")"
  APP_DEPS[$APP_COUNT]="$(trim "$deps")"

  APP_COUNT=$((APP_COUNT + 1))
done < "$MANIFEST"

if [[ $APP_COUNT -eq 0 ]]; then
  err "No apps found in manifest."
  exit 1
fi

CURRENT_OS="$(detect_os)"
if [[ "$CURRENT_OS" == "unknown" ]]; then
  warn "Unknown OS. Proceeding without OS filtering."
fi

find_app_index() {
  local target="$1"
  local i
  for ((i=0; i<APP_COUNT; i++)); do
    if [[ "${APP_ID[$i]}" == "$target" ]]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}

os_supported() {
  local os_csv="$1"
  if [[ -z "$os_csv" || "$CURRENT_OS" == "unknown" ]]; then
    return 0
  fi
  while IFS= read -r os; do
    [[ -z "$os" ]] && continue
    if [[ "$os" == "$CURRENT_OS" ]]; then
      return 0
    fi
  done < <(split_csv "$os_csv")
  return 1
}

list_apps() {
  local i
  echo "Available apps (os: $CURRENT_OS):"
  for ((i=0; i<APP_COUNT; i++)); do
    if os_supported "${APP_OS[$i]}"; then
      printf -- "- %s: %s (%s)\n" "${APP_ID[$i]}" "${APP_NAME[$i]}" "${APP_PATH[$i]}"
    fi
  done
}

# Parse CLI args
APPS_ARG=""
RUN_AFTER="yes"
NON_INTERACTIVE="no"
LIST_ONLY="no"
RUN_MODE="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apps|-a)
      APPS_ARG="${2:-}"
      shift 2
      ;;
    --all)
      APPS_ARG="all"
      shift
      ;;
    --run)
      RUN_AFTER="yes"
      shift
      ;;
    --no-run)
      RUN_AFTER="no"
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE="yes"
      shift
      ;;
    --list)
      LIST_ONLY="yes"
      shift
      ;;
    --background)
      RUN_MODE="background"
      shift
      ;;
    --foreground)
      RUN_MODE="foreground"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$LIST_ONLY" == "yes" ]]; then
  list_apps
  exit 0
fi

AVAILABLE_INDICES=()
for ((i=0; i<APP_COUNT; i++)); do
  if os_supported "${APP_OS[$i]}"; then
    AVAILABLE_INDICES+=("$i")
  fi
done

if [[ ${#AVAILABLE_INDICES[@]} -eq 0 ]]; then
  err "No apps available for OS: $CURRENT_OS"
  exit 1
fi

SELECTED_IDS=()

select_interactive() {
  local display_map=()
  local display_index=1
  echo "Select apps to install/run (comma-separated numbers, ids, or 'all'):"
  for idx in "${AVAILABLE_INDICES[@]}"; do
    printf "  %d) %s - %s\n" "$display_index" "${APP_ID[$idx]}" "${APP_NAME[$idx]}"
    display_map[$display_index]="$idx"
    display_index=$((display_index + 1))
  done

  local selection
  read -r selection
  selection="$(trim "$selection")"

  if [[ -z "$selection" || "$selection" == "all" ]]; then
    for idx in "${AVAILABLE_INDICES[@]}"; do
      SELECTED_IDS+=("${APP_ID[$idx]}")
    done
    return
  fi

  # If selection contains letters, treat as ids
  if [[ "$selection" =~ [a-zA-Z] ]]; then
    selection="${selection// /}"
    IFS=',' read -r -a ids <<< "$selection"
    for id in "${ids[@]}"; do
      [[ -z "$id" ]] && continue
      SELECTED_IDS+=("$id")
    done
    return
  fi

  selection="${selection// /}"
  IFS=',' read -r -a nums <<< "$selection"
  for n in "${nums[@]}"; do
    [[ -z "$n" ]] && continue
    if [[ -n "${display_map[$n]:-}" ]]; then
      idx="${display_map[$n]}"
      SELECTED_IDS+=("${APP_ID[$idx]}")
    else
      warn "Invalid selection: $n"
    fi
  done
}

if [[ -n "$APPS_ARG" ]]; then
  if [[ "$APPS_ARG" == "all" ]]; then
    for idx in "${AVAILABLE_INDICES[@]}"; do
      SELECTED_IDS+=("${APP_ID[$idx]}")
    done
  else
    APPS_ARG="${APPS_ARG// /}"
    IFS=',' read -r -a ids <<< "$APPS_ARG"
    for id in "${ids[@]}"; do
      [[ -z "$id" ]] && continue
      SELECTED_IDS+=("$id")
    done
  fi
else
  if [[ "$NON_INTERACTIVE" == "yes" ]]; then
    for idx in "${AVAILABLE_INDICES[@]}"; do
      SELECTED_IDS+=("${APP_ID[$idx]}")
    done
  else
    select_interactive
  fi
fi

if [[ ${#SELECTED_IDS[@]} -eq 0 ]]; then
  err "No apps selected."
  exit 1
fi

id_in_array() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

ORDERED_IDS=()
VISITED_IDS=()

add_with_deps() {
  local id="$1"
  if id_in_array "$id" "${VISITED_IDS[@]}"; then
    return
  fi
  VISITED_IDS+=("$id")

  local idx
  if ! idx="$(find_app_index "$id")"; then
    warn "Unknown app id: $id"
    return
  fi

  local deps_csv="${APP_DEPS[$idx]}"
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    add_with_deps "$dep"
  done < <(split_csv "$deps_csv")

  ORDERED_IDS+=("$id")
}

for id in "${SELECTED_IDS[@]}"; do
  add_with_deps "$id"
done

# Remove duplicates while preserving order
FINAL_IDS=()
for id in "${ORDERED_IDS[@]}"; do
  if ! id_in_array "$id" "${FINAL_IDS[@]}"; then
    FINAL_IDS+=("$id")
  fi
done

log "Selected apps: ${FINAL_IDS[*]}"

INSTALLED_IDS=()
FAILED_IDS=()
SKIPPED_IDS=()

for id in "${FINAL_IDS[@]}"; do
  idx="$(find_app_index "$id" || true)"
  if [[ -z "$idx" ]]; then
    warn "Skipping unknown app: $id"
    SKIPPED_IDS+=("$id")
    continue
  fi

  if ! os_supported "${APP_OS[$idx]}"; then
    warn "Skipping $id (unsupported OS: $CURRENT_OS)"
    SKIPPED_IDS+=("$id")
    continue
  fi

  app_path="$ROOT_DIR/${APP_PATH[$idx]}"
  if [[ ! -d "$app_path" ]]; then
    warn "Skipping $id (missing path: $app_path)"
    SKIPPED_IDS+=("$id")
    continue
  fi

  missing=()
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    missing+=("$tool")
  done < <(missing_tools_for "${APP_TOOLS[$idx]}")

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Skipping $id (missing tools: ${missing[*]})"
    for tool in "${missing[@]}"; do
      warn "  - $(install_hint "$tool")"
    done
    SKIPPED_IDS+=("$id")
    continue
  fi

  install_cmd="${APP_INSTALL[$idx]}"
  if [[ -z "$install_cmd" ]]; then
    log "No install step for $id."
  else
    log "Installing $id in ${APP_PATH[$idx]}"
    if ! (cd "$app_path" && bash -c "$install_cmd"); then
      warn "Install failed for $id"
      FAILED_IDS+=("$id")
      continue
    fi
  fi

  INSTALLED_IDS+=("$id")
done

if [[ "$RUN_AFTER" != "yes" ]]; then
  log "Install complete. Run disabled (--no-run)."
  exit 0
fi

RUN_IDS=()
for id in "${INSTALLED_IDS[@]}"; do
  RUN_IDS+=("$id")
done

if [[ ${#RUN_IDS[@]} -eq 0 ]]; then
  warn "No apps to run."
  exit 0
fi

run_count=0
for id in "${RUN_IDS[@]}"; do
  idx="$(find_app_index "$id" || true)"
  run_cmd="${APP_RUN[$idx]}"
  [[ -n "$run_cmd" ]] && run_count=$((run_count + 1))
done

if [[ "$RUN_MODE" == "foreground" && $run_count -gt 1 ]]; then
  warn "Multiple apps selected; switching to background mode."
  RUN_MODE="background"
fi

if [[ "$RUN_MODE" == "auto" ]]; then
  if [[ $run_count -gt 1 ]]; then
    RUN_MODE="background"
  else
    RUN_MODE="foreground"
  fi
fi

if [[ "$RUN_MODE" == "foreground" ]]; then
  for id in "${RUN_IDS[@]}"; do
    idx="$(find_app_index "$id" || true)"
    run_cmd="${APP_RUN[$idx]}"
    [[ -z "$run_cmd" ]] && continue
    app_path="$ROOT_DIR/${APP_PATH[$idx]}"
    log "Running $id in foreground: $run_cmd"
    cd "$app_path"
    exec bash -c "$run_cmd"
  done
else
  LOG_DIR="$ROOT_DIR/.run-logs"
  mkdir -p "$LOG_DIR"
  log "Starting apps in background. Logs: $LOG_DIR"
  for id in "${RUN_IDS[@]}"; do
    idx="$(find_app_index "$id" || true)"
    run_cmd="${APP_RUN[$idx]}"
    [[ -z "$run_cmd" ]] && continue
    app_path="$ROOT_DIR/${APP_PATH[$idx]}"
    log "Starting $id: $run_cmd"
    (cd "$app_path" && bash -c "$run_cmd") > "$LOG_DIR/$id.log" 2>&1 &
    echo "  $id -> PID $! (log: $LOG_DIR/$id.log)"
  done
  log "All selected apps started."
fi

if [[ ${#FAILED_IDS[@]} -gt 0 ]]; then
  warn "Some installs failed: ${FAILED_IDS[*]}"
fi
if [[ ${#SKIPPED_IDS[@]} -gt 0 ]]; then
  warn "Some apps were skipped: ${SKIPPED_IDS[*]}"
fi
