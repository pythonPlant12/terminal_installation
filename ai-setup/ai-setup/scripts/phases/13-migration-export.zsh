#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 13
# PHASE_LABEL: migration-export

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/migration-helpers.zsh"

# phase_13_export(output_dir)
# Orchestrates migration bundle creation
# Parameters:
#   - $OUTPUT_DIR: optional output directory (default: current directory)
phase_13_export() {
  local output_dir="${1:-.}"
  
  log "Phase 13: Creating migration export bundle..."
  
  # Verify git repo available
  if ! git -C "$ROOT_DIR" status >/dev/null 2>&1; then
    die "Git repository not available"
  fi
  
  # Warn if repo is dirty
  local dirty_count
  dirty_count="$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null | wc -l)"
  if [[ $dirty_count -gt 0 ]]; then
    warn "Git repository has $dirty_count uncommitted changes (will be included in bundle)"
  fi
  
  # Check disk space
  local available_space
  available_space="$(df "$output_dir" | awk 'NR==2 {print $4}')"
  if [[ $available_space -lt 100000 ]]; then  # Less than 100MB
    warn "Low disk space available: $(( available_space / 1024 ))MB"
  fi
  
  # Capture platform info
  vlog "Capturing platform information..."
  capture_platform_info >/dev/null || true
  
  # Create bundle
  local bundle_name
  bundle_name="$(export_backup_for_migration "$output_dir")"
  
  if [[ -z "$bundle_name" ]]; then
    die "Failed to create migration bundle"
  fi
  
  local bundle_path="${output_dir}/${bundle_name}"
  
  # Create checksum
  if ! create_integrity_checksum "$bundle_path"; then
    warn "Checksum creation failed (bundle created but not verified)"
  fi
  
  # Get bundle details
  local bundle_size
  bundle_size="$(du -h "$bundle_path" | cut -f1)"
  
  local file_count
  file_count="$(tar tzf "$bundle_path" 2>/dev/null | wc -l)"
  
  # Show summary
  ok "Migration export complete"
  log "Bundle: $bundle_name"
  log "Size: $bundle_size"
  log "Files: $file_count"
  log ""
  log "Checksum: $(head -1 "${bundle_path}.sha256" 2>/dev/null | cut -d' ' -f1)"
  log ""
  log "Next steps:"
  log "  1. Transfer bundle to new machine"
  log "  2. Run: ai-setup-import $bundle_name"
  log ""
  
  return 0
}

# Note: This phase file is intended to be sourced by callers (bootstrap/CLI wrappers)
# and should not execute automatically on load.
