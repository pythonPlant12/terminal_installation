#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 11
# PHASE_LABEL: verify-readiness

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/health-check.zsh"
source "$ROOT_DIR/scripts/helpers/keychain-helpers.zsh"

log "Phase 11: Verify Readiness"

# verify_atlassian_auth()
# Check Atlassian credential validity.
# Returns 0 if valid, 1 if missing/invalid
verify_atlassian_auth() {
  local url keychain_url
  local email keychain_email
  local token keychain_token
  
  # Retrieve credentials from Keychain
  keychain_url=$(retrieve_from_keychain "opencode-atlassian-url" || echo "")
  keychain_email=$(retrieve_from_keychain "opencode-atlassian-email" || echo "")
  keychain_token=$(retrieve_from_keychain "opencode-atlassian-token" || echo "")
  
  # If any credential is missing, return 1
  if [[ -z "$keychain_url" ]] || [[ -z "$keychain_email" ]] || [[ -z "$keychain_token" ]]; then
    return 1
  fi
  
  # Validate token against Jira API
  if validate_atlassian_token "$keychain_url" "$keychain_email" "$keychain_token"; then
    return 0
  else
    return 1
  fi
}


# verify_opencode_installed()
# Check OpenCode CLI availability.
# Returns 0 if found, 1 otherwise
verify_opencode_installed() {
  if check_tool_available "opencode"; then
    return 0
  else
    return 1
  fi
}

verify_recovery_cli_available() {
  local -a commands=(
    "ai-setup-export"
    "ai-setup-import"
    "ai-setup-rollback"
    "ai-setup-snapshot"
  )

  local command_name
  for command_name in "${commands[@]}"; do
    if ! check_tool_available_or_linked "$command_name"; then
      return 1
    fi
  done

  return 0
}

# verify_docker_desktop()
# Check if Docker CLI is available (required for Atlassian MCP).
# Returns 0 if found, 1 if not found.
verify_docker_desktop() {
  command -v docker >/dev/null 2>&1
}

# phase_11_verify_readiness()
# Main phase logic: collect per-tool verification results and report aggregate health.
# Always returns 0 (non-blocking)
phase_11_verify_readiness() {
  if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    warn "PATH is missing ~/.local/bin; linked AI setup commands may not be discoverable. Add: export PATH=\"$HOME/.local/bin:$PATH\""
  fi

  if verify_atlassian_auth; then
    status_atlassian="ok"
    report_tool_status "Atlassian MCP" "0" "ok" "keychain" ""
  else
    status_atlassian="warn"
    report_tool_status "Atlassian MCP" "0" "warn" "keychain" "Run: opencode-atlassian-login"
  fi
  if verify_opencode_installed; then
    status_opencode="ok"
    report_tool_status "OpenCode CLI" "0" "ok" "command-status" ""
  else
    status_opencode="critical"
    report_tool_status "OpenCode CLI" "1" "critical" "command-status" "Re-run bootstrap"
  fi

  if verify_docker_desktop; then
    status_docker="ok"
    report_tool_status "Docker Desktop" "0" "ok" "command-status" ""
  else
    status_docker="warn"
    report_tool_status "Docker Desktop" "0" "warn" "command-status" "Required for Atlassian MCP — Install: https://www.docker.com/products/docker-desktop/"
  fi


  if [[ "${AIRCONSOLE_WITH_RECOVERY_CLI:-1}" != "1" ]]; then
    status_recovery="disabled"
    report_tool_status "Recovery CLI" "disabled" "warn" "command-status" "Enable optional component and rerun bootstrap"
  elif verify_recovery_cli_available; then
    status_recovery="ok"
    report_tool_status "Recovery CLI" "0" "ok" "command-status" ""
  else
    status_recovery="warn"
    report_tool_status "Recovery CLI" "1" "warn" "command-status" "Re-run bootstrap to relink bin tools"
  fi
  
  # Build tools_array with status
  tools_array=(
    "Atlassian:$status_atlassian"
    "OpenCode:$status_opencode"
    "Docker:$status_docker"
    "RecoveryCLI:$status_recovery"
  )
  
  # Report aggregate health summary
  report_health_summary "${tools_array[@]}" || true
  
  # Always return 0 (non-blocking)
  return 0
}

# Execute phase
phase_11_verify_readiness
