#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 06
# PHASE_LABEL: opencode-plugins

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: OpenCode plugin provisioning"

# Verify prerequisites exist
require_cmd node
require_cmd bun
require_cmd bunx

# Install plugins declared in repository OpenCode config
log "Installing OpenCode config plugins..."
retry_with_backoff 3 2 "OpenCode config plugin install" -- "$ROOT_DIR/scripts/install-opencode-plugins.zsh"

log "Phase: GSD (get-shit-done-cc) install/update"

require_cmd npx
retry_with_backoff 3 2 "GSD install" -- "$ROOT_DIR/scripts/install-gsd.zsh"

log "Patching GSD workflows with learnings-researcher..."
"$ROOT_DIR/scripts/helpers/patch-gsd-learnings.zsh"

ok "OpenCode plugins provisioned"
