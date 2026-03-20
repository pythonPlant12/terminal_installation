#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 09
# PHASE_LABEL: codex-login

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: Codex Login"

# verify_codex_available() - Check if `codex` command exists in PATH
verify_codex_available() {
  command -v codex >/dev/null 2>&1
}

# verify_codex_auth() - Call `codex login status` and check if authenticated
verify_codex_auth() {
  if codex login status >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# phase_09_codex_login() - Main logic for Codex auth gate
phase_09_codex_login() {
  # Check if codex is available
  if ! verify_codex_available; then
    warn "Codex CLI not found in PATH"
    return 0  # Non-blocking
  fi
  
  # Check if codex is authenticated
  if verify_codex_auth; then
    ok "Codex authenticated"
    return 0
  else
    warn "Codex not authenticated. Run: codex login"
    return 0  # Non-blocking
  fi
}

# Execute the phase
phase_09_codex_login
