#!/usr/bin/env zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

require_cmd node
require_cmd npx

log "Installing/Updating get-shit-done-cc into OpenCode (global)..."
npx --yes get-shit-done-cc@latest --opencode --global

ok "GSD installed/updated for OpenCode."
