#!/usr/bin/env zsh
set -euo pipefail

log() { print -r -- "→ $*"; }
ok()  { print -r -- "✅ $*"; }
warn(){ print -r -- "⚠️  $*"; }
die() { print -r -- "❌ $*"; exit 1; }

VERBOSE_LOGS="${VERBOSE_LOGS:-false}"
set_verbose_logs() { VERBOSE_LOGS="$1"; }
vlog() {
  if [[ "$VERBOSE_LOGS" == "true" ]]; then
    log "$@"
  fi
}

#
# Usage:
# retry_with_backoff <max_attempts> <base_delay_seconds> <description> -- <command> [args...]
#
# Behavior:
# \- Executes the command until it succeeds or attempts are exhausted.
# \- Wait time starts at <base_delay_seconds> and doubles after each failure.
# \- Returns0 on success,1 if all attempts fail.
# \- Requires `--` before the command
retry_with_backoff() {
  local max_attempts="$1"
  local base_delay="$2"
  local description="$3"
  shift 3

  if [[ "$1" != "--" ]]; then
    die "retry_with_backoff requires -- before command"
  fi
  shift

  local attempt=1
  local delay="$base_delay"

  while (( attempt <= max_attempts )); do
    if "$@"; then
      return 0
    fi

    if (( attempt == max_attempts )); then
      return 1
    fi

    warn "Transient failure: $description (attempt $attempt/$max_attempts). Retrying in ${delay}s..."
    sleep "$delay"
    delay=$(( delay * 2 ))
    attempt=$(( attempt + 1 ))
  done

  return 1
}

# Usage: require_cmd <command_name>
# Checks if the specified command is available in the system.
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

# Usage:
# run_with_context <description> -- <command> [args...]
# Behavior:
# \- Captures command stdout and stderr to temporary files.
# \- Returns command exit status unchanged.
# \- On failure, prints:
# \- `Command failed: <description>`
# \- `Exit code: <code>`
# \- First line of stderr, or stdout if stderr is empty.
# \- On success, prints captured stdout only when `VERBOSE
run_with_context() {
  local description="$1"
  shift
  
  local temp_out temp_err
  temp_out="$(mktemp)"
  temp_err="$(mktemp)"
  
  local exit_code=0
  if "$@" >"$temp_out" 2>"$temp_err"; then
    exit_code=0
  else
    exit_code=$?
  fi
  
  local stdout_content stderr_content
  stdout_content="$(<"$temp_out")"
  stderr_content="$(<"$temp_err")"
  rm -f "$temp_out" "$temp_err"
  
  if (( exit_code != 0 )); then
    print -r -- "Command failed: $description"
    print -r -- "Exit code: $exit_code"
    if [[ -n "$stderr_content" ]]; then
      print -r -- "Error output: ${stderr_content%%$'\n'*}"
    elif [[ -n "$stdout_content" ]]; then
      print -r -- "Output: ${stdout_content%%$'\n'*}"
    fi
    return "$exit_code"
  fi
  
  if [[ "$VERBOSE_LOGS" == "true" ]]; then
    [[ -n "$stdout_content" ]] && print -r -- "$stdout_content"
  fi
  
  return 0
}

# Usage: require_macos_supported
# Checks if the script is running on a supported version of macOS (14+).
# Exits with an error message if the OS is unsupported.
require_macos_supported() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This setup supports macOS only."

  # macOS 14+ (Sonoma+) to match “currently supported macOS” reality in 2026.
  local ver major
  ver="$(sw_vers -productVersion)"
  major="${ver%%.*}"

  if (( major < 14 )); then
    die "Unsupported macOS $ver. Require macOS 14+."
  fi

  ok "macOS $ver supported."
}

# Usage: ensure_dir <directory_path>
# Ensures the specified directory exists, creating it if necessary.
ensure_dir() { mkdir -p "$1"; }

# Usage: is_interactive
# Check if running in interactive mode
is_interactive() {
  [[ -t 0 ]] && \
    [[ "${AIRCONSOLE_BOOTSTRAP_NONINTERACTIVE:-0}" != "1" ]] && \
    [[ -z "${CI:-}" ]] && \
    [[ -z "${AIRCONSOLE_BOOTSTRAP_SUBPROCESS:-}" ]] && \
    return 0
  return 1
}

# Usage: file_type_description <path>
# Describe file type for user-facing messages
file_type_description() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local link_target
    link_target="$(readlink "$target")"
    echo "symlink to $link_target"
  elif [[ -d "$target" ]]; then
    echo "directory"
  elif [[ -f "$target" ]]; then
    echo "file"
  else
    echo "exists"
  fi
}

# Usage: backup_and_link <source> <destination>
# Backup existing file/directory and create symlink
backup_and_link() {
  local src="$1" dst="$2"
  local timestamp
  timestamp="$(date +%Y%m%d%H%M%S)"
  local backup="${dst}.dotbot-backup.${timestamp}"
  
  warn "Backing up $dst -> $backup"
  mv "$dst" "$backup"
  ln -s "$src" "$dst"
  ok "Linked: $dst -> $src"
}

# Usage: prompt_user_choice <source> <destination>
# Prompt user for conflict resolution choice
# Options: backup (b), adopt (a), skip (s)
prompt_user_choice() {
  local src="$1" dst="$2"
  
  echo
  warn "Conflict detected: $dst already exists"
  echo "  Existing: $(file_type_description "$dst")"
  echo "  New link would point to: $src"
  echo
  echo "Choose action:"
  echo "  b) Backup existing and create link"
  echo "  a) Adopt (keep existing, skip link)"
  echo "  s) Skip this file"
  echo
  read -r "choice?Choice [b/a/s]: "
  
  case "$choice" in
    b|B) backup_and_link "$src" "$dst" ;;
    a|A) log "Adopting existing: $dst" ;;
    s|S) log "Skipped: $dst" ;;
    *) warn "Invalid choice, skipping"; log "Skipped: $dst" ;;
  esac
}

# Usage: handle_conflict <source> <destination>
# Handle conflict by prompting or auto-resolving based on interactivity
# If non-interactive, defaults to backup. If interactive, prompts user for choice.
handle_conflict() {
  local src="$1" dst="$2"
  
  if ! is_interactive; then
    # Non-interactive mode: default to backup
    log "Non-interactive mode: backing up conflict at $dst"
    backup_and_link "$src" "$dst"
    return
  fi
  
  # Interactive mode: prompt user
  prompt_user_choice "$src" "$dst"
}

# Usage: link_file <source> <destination>
# Create a symlink from source to destination, handling conflicts appropriately.
link_file() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  
  # If it's already the correct symlink, keep it.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "Link ok: $dst"
    return
  fi
  
  # If dst is a symlink pointing elsewhere, replace it silently (no backup needed)
  if [[ -L "$dst" ]]; then
    ln -sf "$src" "$dst"
    ok "Linked: $dst -> $src"
    return
  fi

  # Detect conflict (target exists as a real file or directory)
  if [[ -e "$dst" ]]; then
    handle_conflict "$src" "$dst"
    return
  fi
  
  # No conflict, create symlink normally
  ln -s "$src" "$dst"
  ok "Linked: $dst -> $src"
}

# --- Durable Step Execution helpers (Practice 1) ---
# See: opencode/rules/durable-step-execution.md

# Usage: step_done <surface> <step> <id>
# Returns 0 if the step marker exists, 1 otherwise.
step_done() {
  local surface="$1" step="$2" id="$3"
  local marker="${ROOT_DIR:-.}/.state/${surface}-${step}-${id}.done"
  [[ -f "$marker" ]]
}

# Usage: mark_done <surface> <step> <id>
# Creates the marker file for a completed step.
# MUST only be called AFTER the step's verification gate passes.
mark_done() {
  local surface="$1" step="$2" id="$3"
  local state_dir="${ROOT_DIR:-.}/.state"
  ensure_dir "$state_dir"
  local marker="${state_dir}/${surface}-${step}-${id}.done"
  date -u '+%Y-%m-%dT%H:%M:%SZ' > "$marker"
  vlog "Marker written: $marker"
}

# Usage: clear_markers [surface]
# If surface is given, removes all markers for that surface.
# If no argument, removes all markers.
clear_markers() {
  local state_dir="${ROOT_DIR:-.}/.state"
  [[ -d "$state_dir" ]] || return 0

  if [[ -n "${1:-}" ]]; then
    local surface="$1"
    rm -f "${state_dir}/${surface}"-*.done 2>/dev/null
    vlog "Cleared markers for surface: $surface"
  else
    rm -f "${state_dir}"/*.done 2>/dev/null
    vlog "Cleared all markers"
  fi
}
