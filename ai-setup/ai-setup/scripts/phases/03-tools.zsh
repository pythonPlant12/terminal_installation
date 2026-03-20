#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 03
# PHASE_LABEL: tools

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/ensure-tools.zsh"

ensure_opencode_present_or_warn

ok "Tool checks complete."
