#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

ensure_npm_cli_if_missing() {
  local command_name="$1"
  local package_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$command_name already installed: $($command_name --version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  require_cmd npm
  log "Installing $command_name via npm package $package_name"
  retry_with_backoff 3 1 "install $package_name" -- npm i -g "$package_name"
}

ensure_opencode_present_or_warn() {
  if command -v opencode >/dev/null 2>&1; then
    ok "opencode already installed: $(opencode --version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  warn "OpenCode CLI is not installed yet."
  warn "Install it via your preferred org-approved channel, then rerun ./bootstrap.zsh."
}

run_legacy_entrypoint() {
  ensure_opencode_present_or_warn

  ok "Tools ensured."
}

if [[ "${(%):-%N}" == "$0" ]]; then
  run_legacy_entrypoint
fi
