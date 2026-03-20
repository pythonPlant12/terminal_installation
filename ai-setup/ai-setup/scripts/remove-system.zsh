#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

VERBOSE=false
CONFIRM_ALL=false
COMPONENTS_TO_REMOVE=()

usage() {
  cat <<EOF
Usage: ./scripts/remove-system.zsh [options]

Selectively remove installed AI setup components that were previously installed
via the bootstrap system.

Options:
  --gsd               Remove get-shit-done-cc (gsd)
  --all               Remove all removable components (equivalent to --gsd)
  -y, --yes           Skip confirmation prompts
  -v, --verbose       Enable verbose logs
  -h, --help          Show this help

Examples:
  ./scripts/remove-system.zsh --all -y            # Remove all components without prompting

Note:
  - Removals are performed in reverse order of installation
  - This does NOT remove base tools like opencode, npm, bun
  - Removal is NON-DESTRUCTIVE: your Keychain credentials and config backups are preserved
EOF
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --gsd)
        COMPONENTS_TO_REMOVE+=("gsd")
        ;;
      --all)
        COMPONENTS_TO_REMOVE=("gsd")
        ;;
      -y|--yes)
        CONFIRM_ALL=true
        ;;
      -v|--verbose)
        VERBOSE=true
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1 (run ./scripts/remove-system.zsh --help)"
        ;;
    esac
    shift
  done
}

# Validate at least one component was specified
validate_components() {
  if (( ${#COMPONENTS_TO_REMOVE[@]} == 0 )); then
    die "No components specified. Use --gsd or --all"
  fi
}

# Show summary and ask for confirmation
confirm_removal() {
  echo ""
  log "Removal Summary:"
  log "=================="
  for component in "${COMPONENTS_TO_REMOVE[@]}"; do
    echo "  - $component"
  done
  echo ""
  
  if [[ "$CONFIRM_ALL" == "true" ]]; then
    ok "Proceeding without confirmation (--yes flag set)"
    return 0
  fi
  
  warn "This will remove the selected components from your system."
  echo ""
  read -r "response?Continue with removal? (yes/no): "
  
  if [[ "$response" != "yes" ]]; then
    log "Removal cancelled."
    exit 0
  fi
}

run_removal() {
  local component="$1"
  
  # Determine the removal order: reverse of installation
  # Removal order: gsd
  case "$component" in
    gsd)
      run_removal_step "Remove get-shit-done-cc (GSD)" \
        "Manually run: npm uninstall -g get-shit-done-cc" \
        "$ROOT_DIR/scripts/phases/93-remove-gsd.zsh"
      ;;
    *)
      die "Unknown component: $component"
      ;;
  esac
}

run_removal_step() {
  local step_name="$1"
  local fallback_action="$2"
  shift 2
  
  if [[ "$VERBOSE" == "true" ]]; then
    log "Running removal step: $step_name"
  else
    print -r -- "STEP: $step_name"
  fi
  
  local step_output
  if step_output="$(AIRCONSOLE_WITH_RECOVERY_CLI=1 AIRCONSOLE_BOOTSTRAP_SUBPROCESS=1 "$@" 2>&1)"; then
    ok "✓ $step_name completed"
    if [[ "$VERBOSE" == "true" && -n "$step_output" ]]; then
      print -r -- "$step_output"
    fi
    return 0
  fi
  
  warn "✗ $step_name failed"
  print -r -- "Output: $step_output"
  print -r -- "Fallback: $fallback_action"
  return 1
}

# Sort components for removal (reverse order)
sort_removal_components() {
  local -a sorted=()
  
  # Always process in reverse install order
  for component in gsd; do
    if [[ " ${COMPONENTS_TO_REMOVE[*]} " =~ " $component " ]]; then
      sorted+=("$component")
    fi
  done
  
  COMPONENTS_TO_REMOVE=("${sorted[@]}")
}

main() {
  parse_args "$@"
  set_verbose_logs "$VERBOSE"
  validate_components
  sort_removal_components

  local -a preflight_args=()
  local component
  for component in "${COMPONENTS_TO_REMOVE[@]}"; do
    preflight_args+=("--component" "$component")
  done

  run_removal_step \
    "Removal preflight checks" \
    "Verify required tools (node/npm) are installed and rerun ai-setup-remove" \
    "$ROOT_DIR/scripts/phases/90-remove-preflight.zsh" "${preflight_args[@]}"

  confirm_removal
  
  log ""
  log "========== AI Component Removal =========="
  log ""
  
  local failed_removals=()
  
  for component in "${COMPONENTS_TO_REMOVE[@]}"; do
    if ! run_removal "$component"; then
      failed_removals+=("$component")
    fi
  done
  
  log ""
  if (( ${#failed_removals[@]} == 0 )); then
    ok "========== All removals completed successfully =========="
    log ""
    log "Next steps:"
    log "  - Run 'ai-setup-doctor' to verify component removal"
    log "  - Run './bootstrap.zsh' to re-install components if needed"
  else
    warn "========== Some removals encountered issues =========="
    log "Failed removals:"
    for component in "${failed_removals[@]}"; do
      echo "  - $component"
    done
    log ""
    warn "Please check the errors above and retry, or manually remove using the fallback commands."
    exit 1
  fi
  
  log ""
}

main "$@"
