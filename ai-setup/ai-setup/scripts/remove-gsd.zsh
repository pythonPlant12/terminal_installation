#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Removing get-shit-done-cc from system..."

# Verify npm is available
require_cmd npm

# Uninstall global gsd-cc package
if npm list -g get-shit-done-cc >/dev/null 2>&1; then
  log "Found global gsd-cc installation, removing..."
  npm uninstall -g get-shit-done-cc || die "Failed to uninstall gsd-cc"
  ok "gsd-cc uninstalled from npm"
else
  warn "gsd-cc not found in global npm packages (may already be removed)"
fi

# Verify removal
if npm list -g get-shit-done-cc >/dev/null 2>&1; then
  die "gsd-cc uninstall verification failed; package still present"
fi

ok "get-shit-done-cc has been successfully removed"
