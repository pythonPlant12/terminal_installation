#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

# Module-level flag: set by backup_existing_dirs, read by rollback_backup.
# Empty means no backup was created (safe no-op for rollback).
_BOOTSTRAP_BACKUP_TIMESTAMP=""

# backup_existing_dirs()
# Renames ~/.config/opencode and ~/.cache/opencode to .bak-YYYYMMDD-HHMMSS.
# Both directories use the same timestamp for traceability.
# Sets _BOOTSTRAP_BACKUP_TIMESTAMP so rollback_backup can find them.
# Safe to call when directories don't exist (first-time bootstrap).
backup_existing_dirs() {
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"

  local config_dir="$HOME/.config/opencode"
  local cache_dir="$HOME/.cache/opencode"
  local config_bak="$HOME/.config/opencode.bak-${timestamp}"
  local cache_bak="$HOME/.cache/opencode.bak-${timestamp}"

  local did_backup=false

  if [[ -d "$config_dir" ]]; then
    mv "$config_dir" "$config_bak"
    log "Renamed $config_dir -> $config_bak"
    did_backup=true
  else
    vlog "No existing config dir ($config_dir), skipping rename"
  fi

  if [[ -d "$cache_dir" ]]; then
    mv "$cache_dir" "$cache_bak"
    log "Renamed $cache_dir -> $cache_bak"
    did_backup=true
  else
    vlog "No existing cache dir ($cache_dir), skipping rename"
  fi

  if [[ "$did_backup" == true ]]; then
    _BOOTSTRAP_BACKUP_TIMESTAMP="$timestamp"
    ok "Clean-slate backup created with timestamp $timestamp"
  else
    vlog "No directories to back up (first-time bootstrap)"
  fi
}

# rollback_backup()
# Restores .bak-TIMESTAMP directories to their original locations.
# Only acts when _BOOTSTRAP_BACKUP_TIMESTAMP is set (backup was created).
# Safe to call multiple times or when no backup exists.
rollback_backup() {
  if [[ -z "${_BOOTSTRAP_BACKUP_TIMESTAMP:-}" ]]; then
    return 0
  fi

  local timestamp="$_BOOTSTRAP_BACKUP_TIMESTAMP"
  local config_bak="$HOME/.config/opencode.bak-${timestamp}"
  local cache_bak="$HOME/.cache/opencode.bak-${timestamp}"
  local config_dir="$HOME/.config/opencode"
  local cache_dir="$HOME/.cache/opencode"

  if [[ -d "$config_bak" ]]; then
    # Remove partially-created config dir from failed phases
    if [[ -d "$config_dir" ]]; then
      rm -rf "$config_dir"
    fi
    mv "$config_bak" "$config_dir"
    warn "Rolled back $config_bak -> $config_dir"
  fi

  if [[ -d "$cache_bak" ]]; then
    # Remove partially-created cache dir from failed phases
    if [[ -d "$cache_dir" ]]; then
      rm -rf "$cache_dir"
    fi
    mv "$cache_bak" "$cache_dir"
    warn "Rolled back $cache_bak -> $cache_dir"
  fi

  _BOOTSTRAP_BACKUP_TIMESTAMP=""
  warn "Bootstrap backup rolled back due to failure"
}

# warn_backup_retention()
# Counts accumulated .bak-* directories in ~/.config/ and ~/.cache/.
# Warns if total exceeds threshold (3). Never auto-deletes.
warn_backup_retention() {
  local threshold=3
  local config_count=0
  local cache_count=0

  # Count opencode.bak-* directories in each parent
  if [[ -d "$HOME/.config" ]]; then
    config_count=$(find "$HOME/.config" -maxdepth 1 -type d -name "opencode.bak-*" 2>/dev/null | wc -l)
    config_count=$(( config_count + 0 ))  # strip whitespace from wc
  fi

  if [[ -d "$HOME/.cache" ]]; then
    cache_count=$(find "$HOME/.cache" -maxdepth 1 -type d -name "opencode.bak-*" 2>/dev/null | wc -l)
    cache_count=$(( cache_count + 0 ))
  fi

  local total=$(( config_count + cache_count ))

  if (( total > threshold )); then
    warn "Found $total bootstrap backup directories ($config_count in ~/.config, $cache_count in ~/.cache)."
    warn "Consider cleaning up old backups. List them first with: ls -d ~/.config/opencode.bak-* ~/.cache/opencode.bak-*"
    warn "If you are sure you want to delete them, you can run: rm -rf ~/.config/opencode.bak-* ~/.cache/opencode.bak-*"
  fi
}
