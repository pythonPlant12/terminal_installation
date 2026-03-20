#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 05
# PHASE_LABEL: bin-link-setup

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: Bin link setup"

# Check if running in interactive mode
if is_interactive; then
  log "Interactive mode - bin link conflicts may prompt"
else
  log "Non-interactive mode - bin link conflicts back up automatically"
fi

# Ensure managed bin scripts are linked into ~/.local/bin.
"$ROOT_DIR/scripts/link_bin.zsh"

ok "Bin link setup complete"
