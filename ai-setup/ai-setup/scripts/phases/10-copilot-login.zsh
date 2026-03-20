#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 10
# PHASE_LABEL: copilot-login

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: Copilot Login"

# verify_copilot_available() - Check if `copilot` command exists in PATH
verify_copilot_available() {
  command -v copilot >/dev/null 2>&1
}

# verify_copilot_config() - Check if config file exists at ~/.copilot/config.json
verify_copilot_config() {
  [[ -f "$HOME/.copilot/config.json" ]]
}

# phase_10_copilot_login() - Main logic for Copilot auth gate
phase_10_copilot_login() {
  # Check if copilot is available
  if ! verify_copilot_available; then
    warn "Copilot CLI not found in PATH"
    return 0  # Non-blocking
  fi
  
  # Check if copilot config exists
  if verify_copilot_config; then
    ok "Copilot configured"
    return 0
  else
    warn "Copilot not configured. Run: copilot (then /login inside app)"
    return 0  # Non-blocking
  fi
}

# Execute the phase
phase_10_copilot_login
