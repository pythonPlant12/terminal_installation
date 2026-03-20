#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 01
# PHASE_LABEL: preflight

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

require_macos_supported
require_cmd zsh
require_cmd git

if ! command -v brew >/dev/null 2>&1; then
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1; then
    die "brew not found and can not be installed. Install Homebrew (https://brew.sh/) and rerun ./bootstrap.zsh"
  fi
fi

ok "Preflight checks passed."
