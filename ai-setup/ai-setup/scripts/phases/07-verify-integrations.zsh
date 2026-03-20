#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 07
# PHASE_LABEL: verify-integrations

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: Integration verification"

# Define reusable verification helpers
verify_tool() {
  local tool="$1"
  local description="$2"
  
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$description"
    return 0
  else
    warn "$description not found"
    return 1
  fi
}

verify_file() {
  local file="$1"
  local description="$2"
  
  if [[ -f "$file" ]]; then
    ok "$description"
    return 0
  else
    warn "$description not found"
    return 1
  fi
}

# verify_docker_desktop()
# Check if Docker CLI is available (required for Atlassian MCP).
# Returns 0 if found, 1 if not found.
verify_docker_desktop() {
  command -v docker >/dev/null 2>&1
}

verify_opencode_config() {
  if [[ -f "$HOME/.config/opencode/opencode.json" || -f "$HOME/.config/opencode/opencode.jsonc" ]]; then
    ok "OpenCode config"
    return 0
  fi

  warn "OpenCode config not found"
  return 1
}

# Initialize failed array
local failed=()

# Verify each integration
verify_tool opencode "OpenCode CLI" || failed+=("opencode CLI")
verify_opencode_config || failed+=("OpenCode config")
verify_tool mcp-atlassian-opencode "Atlassian MCP wrapper" || failed+=("MCP wrapper")

# Docker Desktop — required runtime for Atlassian MCP
if verify_docker_desktop; then
  ok "Docker Desktop: available (required for Atlassian MCP)"
else
  failed+=("Docker Desktop")
  print -r -- ""
  print -r -- "  ⚠️  Docker Desktop not found"
  print -r -- "  ──────────────────────────────────────────────────────────"
  print -r -- "  Atlassian MCP (Jira & Confluence) requires Docker Desktop."
  print -r -- "  Install: https://www.docker.com/products/docker-desktop/"
  print -r -- "  Start Docker Desktop, then rerun: ./bootstrap.zsh"
  print -r -- "  ──────────────────────────────────────────────────────────"
  print -r -- ""
fi

# Report verification results
if (( ${#failed[@]} == 0 )); then
  ok "All integrations verified"
  return 0
fi

# Some integrations not available
warn "Some integrations not available:"
for item in "${failed[@]}"; do
  warn "  - $item"
done
warn "Continue with limited functionality or rerun bootstrap."

# Return 0 always (non-blocking verification)
return 0
