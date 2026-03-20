#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 90
# PHASE_LABEL: remove-preflight

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

typeset -a requested_components=()

while (( $# > 0 )); do
  case "$1" in
    --component)
      requested_components+=("${2:-}")
      shift 2
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

(( ${#requested_components[@]} > 0 )) || die "Missing required argument: --component"

require_macos_supported
require_cmd zsh

for component in "${requested_components[@]}"; do
  case "$component" in
    gsd)
      require_cmd npm
      ;;
    *)
      die "Unsupported component in preflight: $component"
      ;;
  esac
done

ok "Removal preflight checks passed."
