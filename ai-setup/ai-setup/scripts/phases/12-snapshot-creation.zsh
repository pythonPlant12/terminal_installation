#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 12
# PHASE_LABEL: snapshot-creation

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/backup-helpers.zsh"

# phase_12_snapshot(phase_name)
# Orchestrates snapshot creation workflow
# Parameters:
#   - $PHASE_NAME: optional description of phase (e.g., "Bootstrap Complete")
phase_12_snapshot() {
  local phase_name="${1:-.}"
  
  log "Phase 12: Creating configuration snapshot..."
  
  # Safety: skip if restore is in progress
  if [[ "${RESTORE_IN_PROGRESS:-}" == "1" ]]; then
    vlog "Skipping snapshot (restore in progress)"
    return 0
  fi
  
  # Create snapshot directory
  local snapshot_dir
  snapshot_dir="$(create_unique_snapshot_dir "$phase_name")"
  if [[ -z "$snapshot_dir" ]]; then
    warn "Failed to create snapshot directory"
    return 0
  fi
  
  # Backup repository
  if ! backup_repository "$snapshot_dir"; then
    warn "Repository backup failed"
    return 0
  fi
  
  # Capture config state
  if ! capture_config_state "$snapshot_dir"; then
    warn "Config state capture failed"
    return 0
  fi
  
  # Write manifest
  if ! write_snapshot_manifest "$snapshot_dir" "$phase_name"; then
    warn "Manifest generation failed"
    return 0
  fi
  
  # Create pre-restore backup if not first snapshot
  if [[ -n "$(ls -d "$ROOT_DIR/.backup/pre-restore-"* 2>/dev/null | head -1)" ]]; then
    if ! backup_current_state_for_restore "$snapshot_dir"; then
      vlog "Pre-restore backup creation failed (non-blocking)"
    fi
  fi
  
  # Update LATEST symlink
  local latest_link="$ROOT_DIR/.backup/LATEST"
  rm -f "$latest_link" 2>/dev/null || true
  ln -s "$(basename "$snapshot_dir")" "$latest_link"
  
  # Show summary
  local snapshot_size
  snapshot_size="$(du -sh "$snapshot_dir" | cut -f1)"
  local file_count
  file_count="$(ls "$snapshot_dir" | wc -l)"
  
  ok "Snapshot created: $(basename "$snapshot_dir"), size: $snapshot_size, files: $file_count"
  vlog "Snapshot location: $snapshot_dir"
  
  return 0
}

# Note: This phase file is intended to be sourced by callers (bootstrap/CLI wrappers)
# and should not execute automatically on load.
