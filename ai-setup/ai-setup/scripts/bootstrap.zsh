#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/bootstrap-backup.zsh"

VERBOSE=true
SAFE_MODE="${AIRCONSOLE_BOOTSTRAP_SAFE:-0}"
WITH_RECOVERY_CLI="${AIRCONSOLE_WITH_RECOVERY_CLI:-1}"
typeset -a COMPLETED_STEPS=()

usage() {
  cat <<EOF
Usage: ./bootstrap.zsh [options]

Options:
  -h, --help       Show this help

Advanced: optional component toggles are available through AIRCONSOLE_WITH_RECOVERY_CLI.
EOF
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --with-recovery-cli)
        WITH_RECOVERY_CLI="1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1 (run ./bootstrap.zsh --help)"
        ;;
    esac
    shift
  done
}

run_mode() {
  set_verbose_logs true

  run_step \
    "preflight" \
    "Install missing prerequisites and rerun ./bootstrap.zsh." \
    "" \
     "$ROOT_DIR/scripts/phases/01-preflight.zsh"

  backup_existing_dirs
  # Trap: auto-rollback on any failure after backup.
  # _BOOTSTRAP_COMPLETED flag prevents rollback on successful exit.
  _BOOTSTRAP_COMPLETED=false
  trap '
    if [[ "${_BOOTSTRAP_COMPLETED:-false}" != "true" ]]; then
      rollback_backup
    fi
  ' EXIT

  run_step \
    "Install dependencies" \
    "Check network access, then rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/scripts/phases/02-dependencies.zsh"

  # After phase 02 installs bun, ensure ~/.bun/bin is on PATH for subsequent phases.
  if [[ -x "$HOME/.bun/bin/bun" ]] && ! command -v bun >/dev/null 2>&1; then
    export PATH="$HOME/.bun/bin:$PATH"
    vlog "bun added to PATH: $HOME/.bun/bin"
  fi

  run_step \
    "Ensure tools are installed" \
    "Check network/npm access, then rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/scripts/phases/03-tools.zsh"

  run_step \
    "bin link setup" \
    "Resolve local ~/.local/bin link conflicts and rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/scripts/phases/05-bin-link-setup.zsh"

  run_step \
    "opencode plugins" \
    "Confirm npm/bun registry access, then rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/scripts/phases/06-opencode-plugins.zsh"

  # Keep config sync after plugin provisioning so repo config remains authoritative.
  run_step \
    "sync opencode config" \
    "Resolve config sync issues and rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/scripts/link_opencode.zsh"

  run_step \
    "skill inventory" \
    "Run 'ai-setup-skill-inventory --generate' manually and rerun ./bootstrap.zsh." \
    "./bootstrap.zsh" \
    "$ROOT_DIR/bin/ai-setup-skill-inventory" --generate

   run_step \
     "integration verification" \
     "Install missing integrations and rerun ./bootstrap.zsh." \
     "./bootstrap.zsh" \
     "$ROOT_DIR/scripts/phases/07-verify-integrations.zsh"

   run_step \
     "atlassian login" \
     "Provide Atlassian credentials and rerun ./bootstrap.zsh." \
     "./bootstrap.zsh" \
     "$ROOT_DIR/scripts/phases/08-atlassian-login.zsh"

#   run_step \
#     "codex login" \
#     "Authenticate Codex and rerun ./bootstrap.zsh." \
#     "./bootstrap.zsh" \
#     "$ROOT_DIR/scripts/phases/09-codex-login.zsh"
#
#    run_step \
#      "copilot login" \
#      "Configure Copilot and rerun ./bootstrap.zsh." \
#      "./bootstrap.zsh" \
#      "$ROOT_DIR/scripts/phases/10-copilot-login.zsh"

    run_step \
      "verify readiness" \
      "Check integration status and rerun ./bootstrap.zsh." \
      "./bootstrap.zsh" \
      "$ROOT_DIR/scripts/phases/11-verify-readiness.zsh"

    # Optional phase 12: snapshot creation (if AIRCONSOLE_AUTO_SNAPSHOT=1)
    if [[ "${AIRCONSOLE_AUTO_SNAPSHOT:-}" == "1" ]]; then
      run_step \
        "snapshot creation" \
        "Snapshot creation failed (non-blocking); bootstrap complete." \
        "" \
        "$ROOT_DIR/scripts/phases/12-snapshot-creation.zsh" "Bootstrap Complete"
    else
      vlog "Skipping phase 12 snapshot (to enable, run: AIRCONSOLE_AUTO_SNAPSHOT=1 ./bootstrap.zsh)"
    fi

    log ""
    log "========== AI Setup Complete =========="
    log "All AI tools and integrations have been verified."
    log "Run 'ai-setup-doctor' at any time to check integration health."
    if [[ "${AIRCONSOLE_WITH_RECOVERY_CLI:-1}" == "1" ]]; then
      log "Run 'ai-setup-snapshot --create' to create a snapshot of this setup."
    else
      log "Recovery CLIs are disabled by configuration."
    fi
    log "========================================"
    log ""


  # Mark bootstrap as complete so the EXIT trap does NOT rollback.
  _BOOTSTRAP_COMPLETED=true

  warn_backup_retention

  "$ROOT_DIR/scripts/phases/04-summary.zsh" \
    --status "success" \
    --steps "${(j:,:)COMPLETED_STEPS}" \
    --next "./bootstrap.zsh"
}

run_step() {
  local step_name="$1"
  local next_action="$2"
  local recovery_command="$3"
  shift 3

  if [[ "$VERBOSE" == true ]]; then
    log "Running step: $step_name"
  else
    print -r -- "STEP: $step_name"
  fi

  local step_output
  if step_output="$(run_step_command "$@")"; then
    COMPLETED_STEPS+=("$step_name")
    if [[ "$VERBOSE" == true && -n "$step_output" ]]; then
      print -r -- "$step_output"
    elif [[ -n "$step_output" ]]; then
      # Non-verbose: surface auth/health status lines (✅/⚠️/❌) so users
      # can see which integrations passed or failed without --verbose.
      local status_lines
      status_lines="$(print -r -- "$step_output" | grep -E '^(✅|⚠️|❌)' || true)"
      if [[ -n "$status_lines" ]]; then
        print -r -- "$status_lines"
      fi
    fi
    return 0
  fi

  print -r -- "FAIL: $step_name"
  
  # Show actionable context from failure output
  if [[ -n "$step_output" ]]; then
    # In verbose mode or when output is short, show all context
    if [[ "$VERBOSE" == true ]]; then
      print -r -- "CAUSE: Step execution failed"
      print -r -- "$step_output"
    else
      # Default mode: show first meaningful error line(s) for triage
      local error_summary
      error_summary="$(print -r -- "$step_output" | grep -i "error\|failed\|fatal\|command" | head -3)"
      if [[ -n "$error_summary" ]]; then
        print -r -- "CAUSE:"
        print -r -- "$error_summary"
      else
        # Fallback to last few lines which often contain the actual error
        print -r -- "CAUSE:"
        print -r -- "$(print -r -- "$step_output" | tail -5)"
      fi
    fi
  else
    print -r -- "CAUSE: Command returned non-zero exit status with no output"
  fi
  
  print -r -- ""
  print -r -- "NEXT: $next_action"
  if [[ -n "$recovery_command" ]]; then
    print -r -- "RECOVERY: $recovery_command"
  fi

  "$ROOT_DIR/scripts/phases/04-summary.zsh" \
    --status "failed" \
    --steps "${(j:,:)COMPLETED_STEPS}" \
    --next "$recovery_command"

  exit 1
}

run_step_command() {
  if [[ "$SAFE_MODE" == "1" ]]; then
    if [[ "$VERBOSE" == true ]]; then
      print -r -- "[safe-mode] skipped command: $*"
    fi
    return 0
  fi

  local temp_log
  temp_log="$(mktemp)"

  local exit_code=0
  # Set AIRCONSOLE_BOOTSTRAP_SUBPROCESS=1 to signal to phases that they're running
  # in a subprocess context where stdout is redirected (no interactive prompts possible).
  # Also set AIRCONSOLE_BOOTSTRAP_NONINTERACTIVE=1 to auto-resolve conflicts instead of hanging.
  if AIRCONSOLE_BOOTSTRAP_SUBPROCESS=1 AIRCONSOLE_BOOTSTRAP_NONINTERACTIVE=1 AIRCONSOLE_WITH_RECOVERY_CLI="${AIRCONSOLE_WITH_RECOVERY_CLI:-1}" "$@" >"$temp_log" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi
  local output
  output="$(<"$temp_log")"
  rm -f "$temp_log"

  if (( exit_code != 0 )); then
    print -r -- "$output"
    return "$exit_code"
  fi

  # Always pass output through — run_step() decides what to display
  # based on verbose mode (full output) vs non-verbose (status lines only).
  if [[ -n "$output" ]]; then
    print -r -- "$output"
  fi

  return 0
}

parse_args "$@"
export AIRCONSOLE_WITH_RECOVERY_CLI="$WITH_RECOVERY_CLI"
run_mode
