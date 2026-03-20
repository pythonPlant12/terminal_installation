#!/usr/bin/env zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

ok "Auth gates skipped (Codex and Copilot not required)."
exit 0
