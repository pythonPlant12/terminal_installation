#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 08
# PHASE_LABEL: atlassian-login

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/keychain-helpers.zsh"

log "Phase: Atlassian Login"

# atlassian_mcp_enabled() - Check if opencode.jsonc contains Atlassian MCP config
atlassian_mcp_enabled() {
  local config_file="$ROOT_DIR/opencode/opencode.jsonc"
  [[ -f "$config_file" ]] && grep -q '"atlassian"' "$config_file"
}

# phase_08_atlassian_login() - Main logic for Atlassian credential setup
phase_08_atlassian_login() {
  # Check if Atlassian MCP is enabled in config
  if ! atlassian_mcp_enabled; then
    ok "Atlassian: skipped (not enabled in config)"
    return 0
  fi

  # Docker Desktop prerequisite check — Atlassian MCP runs in a Docker container
  if ! command -v docker >/dev/null 2>&1; then
    print -r -- ""
    print -r -- "  ⚠️  Docker Desktop required for Atlassian MCP"
    print -r -- "  ──────────────────────────────────────────────────────────"
    print -r -- "  Atlassian MCP (Jira & Confluence) runs in a Docker container."
    print -r -- "  Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
     print -r -- "  Start Docker Desktop, then rerun: ./bootstrap.zsh"
    print -r -- "  ──────────────────────────────────────────────────────────"
    print -r -- ""
    warn "Atlassian: skipping credential setup (Docker Desktop not installed)"
    return 0
  fi

  # If credentials are already set and valid, nothing to do
  if "$ROOT_DIR/bin/opencode-atlassian-status" >/dev/null 2>&1; then
    ok "Atlassian: credentials already in Keychain"
    return 0
  fi

  # Check if all three env vars are set (CI mode)
  if [[ -n "${ATLASSIAN_SITE_URL:-}" ]] && \
     [[ -n "${ATLASSIAN_EMAIL:-}" ]] && \
     [[ -n "${ATLASSIAN_API_TOKEN:-}" ]]; then
    
    log "Using Atlassian credentials from environment (CI mode)"
    
    # Store all three in Keychain
    store_in_keychain "opencode-atlassian-url" "$ATLASSIAN_SITE_URL" || die "Failed to store URL in Keychain"
    store_in_keychain "opencode-atlassian-email" "$ATLASSIAN_EMAIL" || die "Failed to store email in Keychain"
    store_in_keychain "opencode-atlassian-token" "$ATLASSIAN_API_TOKEN" || die "Failed to store token in Keychain"
    
    # Validate token immediately
    if validate_atlassian_token "$ATLASSIAN_SITE_URL" "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN"; then
      ok "Atlassian credentials valid"
      return 0
    else
      warn "Atlassian credentials invalid (HTTP 401)"
      return 1
    fi
  
  # Interactive mode
  elif is_interactive; then
    log "Interactive mode: Prompting for Atlassian credentials"
    
    # Call existing bin/opencode-atlassian-login script
    if "$ROOT_DIR/bin/opencode-atlassian-login"; then
      # After completion, retrieve credentials from Keychain
      local url email token
      url="$(retrieve_from_keychain "opencode-atlassian-url")"
      email="$(retrieve_from_keychain "opencode-atlassian-email")"
      token="$(retrieve_from_keychain "opencode-atlassian-token")"
      
      # Validate immediately
      if validate_atlassian_token "$url" "$email" "$token"; then
        ok "Atlassian credentials valid"
        return 0
      else
        warn "Setup succeeded but credentials invalid"
        return 1
      fi
    else
      warn "Atlassian login script failed"
      return 1
    fi
  
  # Non-interactive mode without env vars
  else
    warn "Atlassian: non-interactive mode, credentials not pre-set. Run: opencode-atlassian-login"
    return 0
  fi
}

# Execute the phase
phase_08_atlassian_login
