#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 93
# PHASE_LABEL: remove-gsd

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

log "Phase: remove get-shit-done-cc"
"$ROOT_DIR/scripts/remove-gsd.zsh"
ok "gsd removal phase completed"
