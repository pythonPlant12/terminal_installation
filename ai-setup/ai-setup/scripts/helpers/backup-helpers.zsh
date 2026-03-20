#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"
source "$ROOT_DIR/scripts/helpers/keychain-helpers.zsh"

# create_timestamp()
# Returns ISO 8601 compact format (YYYY-MM-DDTHHMM SS)
create_timestamp() {
  date -u +"%Y-%m-%dT%H%M%S"
}

# create_unique_snapshot_dir(phase_name)
# Creates collision-free snapshot directory in .backup/snapshots/
# Checks for existing directory and increments if needed
# Returns the full path to new snapshot directory
create_unique_snapshot_dir() {
  local phase_name="${1:-.backup/snapshots}"
  local timestamp base_dir snapshot_dir
  
  timestamp="$(create_timestamp)"
  base_dir="$ROOT_DIR/.backup/snapshots"
  snapshot_dir="${base_dir}/${timestamp}"
  
  mkdir -p "$base_dir"
  
  # Check for collision and increment if needed
  local counter=1
  local original_dir="$snapshot_dir"
  while [[ -d "$snapshot_dir" ]]; do
    snapshot_dir="${original_dir}-${counter}"
    counter=$((counter + 1))
  done
  
  mkdir -p "$snapshot_dir"
  print -r -- "$snapshot_dir"
}

# backup_repository(snapshot_dir)
# Creates git bundle with full history (HEAD --all)
# Verifies with `git bundle verify`
# Places git-bundle.bundle in snapshot_dir
backup_repository() {
  local snapshot_dir="$1"
  local bundle_file="${snapshot_dir}/git-bundle.bundle"
  
  vlog "Bundling git repository to $bundle_file..."
  
  if ! git -C "$ROOT_DIR" bundle create "$bundle_file" HEAD --all >/dev/null 2>&1; then
    warn "Git bundle creation failed"
    return 1
  fi
  
  if ! git bundle verify "$bundle_file" >/dev/null 2>&1; then
    warn "Git bundle verification failed"
    return 1
  fi
  
  ok "Git bundle created and verified"
  return 0
}

# restore_from_bundle(bundle_file, target_dir)
# Restores git state from bundle
# Clones if new repo, fetches if existing
restore_from_bundle() {
  local bundle_file="$1"
  local target_dir="$2"
  
  vlog "Restoring git state from bundle..."
  
  if [[ ! -d "${target_dir}/.git" ]]; then
    # Clone from bundle
    if ! git clone "$bundle_file" "$target_dir" >/dev/null 2>&1; then
      warn "Git clone from bundle failed"
      return 1
    fi
  else
    # Fetch into existing repo
    if ! git -C "$target_dir" fetch "$bundle_file" 'refs/heads/*:refs/heads/*' >/dev/null 2>&1; then
      warn "Git fetch from bundle failed"
      return 1
    fi
  fi
  
  ok "Git state restored from bundle"
  return 0
}

# capture_config_state(snapshot_dir)
# Tars ~/.config/opencode, ~/.zshrc, ~/.gitconfig, and any .bak files from Phase 2
# Places config-state.tar.gz in snapshot_dir
capture_config_state() {
  local snapshot_dir="$1"
  local config_tar="${snapshot_dir}/config-state.tar.gz"
  
  vlog "Capturing configuration state to $config_tar..."
  
  local tar_files=()
  
  # Always include if they exist
  [[ -f "$HOME/.zshrc" ]] && tar_files+=("$HOME/.zshrc")
  [[ -f "$HOME/.gitconfig" ]] && tar_files+=("$HOME/.gitconfig")
  [[ -d "$HOME/.config/opencode" ]] && tar_files+=("$HOME/.config/opencode")
  
  # Include any backup files from Phase 2
  [[ -d "$HOME" ]] && tar_files+=($(find "$HOME" -maxdepth 1 -name ".dotbot-backup.*" -type d 2>/dev/null || true))
  
  if [[ ${#tar_files[@]} -eq 0 ]]; then
    warn "No config files found to backup"
    touch "$config_tar"
    return 0
  fi
  
  if ! tar czf "$config_tar" "${tar_files[@]}" >/dev/null 2>&1; then
    warn "Config tar creation failed"
    return 1
  fi
  
  ok "Configuration state captured ($(du -h "$config_tar" | cut -f1))"
  return 0
}

# restore_config_state(snapshot_dir)
# Extracts config tar to home (preserves original paths)
restore_config_state() {
  local snapshot_dir="$1"
  local config_tar="${snapshot_dir}/config-state.tar.gz"
  
  if [[ ! -f "$config_tar" ]]; then
    warn "Config tar not found: $config_tar"
    return 1
  fi
  
  vlog "Restoring configuration state from $config_tar..."
  
  if ! tar xzf "$config_tar" -C / >/dev/null 2>&1; then
    warn "Config tar extraction failed"
    return 1
  fi
  
  ok "Configuration state restored"
  return 0
}

# write_snapshot_manifest(snapshot_dir, phase_name)
# Generates JSON manifest with system and state information
write_snapshot_manifest() {
  local snapshot_dir="$1"
  local phase_name="${2:-Bootstrap}"
  local manifest_file="${snapshot_dir}/manifest.json"
  
  vlog "Generating snapshot manifest..."
  
  local timestamp hostname macos_version build_version architecture
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  hostname="$(hostname -s)"
  macos_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
  build_version="$(sw_vers -buildVersion 2>/dev/null || echo 'unknown')"
  architecture="$(uname -m)"
  
  # Get tool versions
  local homebrew_packages homebrew_casks bun_version npm_packages git_commits
  homebrew_packages="$(brew list --formula 2>/dev/null | wc -l || echo 0)"
  homebrew_casks="$(brew list --cask 2>/dev/null | wc -l || echo 0)"
  bun_version="$(bun --version 2>/dev/null || echo 'not installed')"
  npm_packages="$(npm list -g --depth=0 2>/dev/null | wc -l || echo 0)"
  git_commits="$(git -C "$ROOT_DIR" rev-list --all --count 2>/dev/null || echo 0)"
  
  # Check credential status
  local atlassian_present
  
  # Check if opencode is linked
  local opencode_linked
  opencode_linked="$([[ -L "$HOME/.opencode" ]] && echo 'true' || echo 'false')"
  
  # Get repo state
  local repo_branch repo_commit repo_dirty
  repo_branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  repo_commit="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')"
  repo_dirty="$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null | wc -l || echo 0)"
  
  # Generate manifest JSON
  local manifest_json
  manifest_json=$(cat <<EOF
{
  "timestamp": "$timestamp",
  "snapshot_created_at": "$timestamp",
  "phase_completed": "$phase_name",
  "hostname": "$hostname",
  "macos_version": "$macos_version",
  "macos_build": "$build_version",
  "architecture": "$architecture",
  "tools": {
    "homebrew_packages": $homebrew_packages,
    "homebrew_casks": $homebrew_casks,
    "bun_version": "$bun_version",
    "npm_packages": $npm_packages
  },
  "repository": {
    "branch": "$repo_branch",
    "commit": "$repo_commit",
    "commits_total": $git_commits,
    "dirty_files": $repo_dirty
  },
  "credentials": {
    "atlassian": $atlassian_present
  },
  "config_state": {
    "opencode_linked": $opencode_linked
  }
}
EOF
)
  
  echo "$manifest_json" > "$manifest_file"
  ok "Manifest written to $manifest_file"
  return 0
}

# backup_current_state_for_restore(snapshot_dir)
# Creates ~/.backup/pre-restore-{timestamp}/ with current config tar
# Used to undo rollback itself
# Only called if this is not the first snapshot
backup_current_state_for_restore() {
  local snapshot_dir="$1"
  local timestamp
  timestamp="$(create_timestamp)"
  
  local pre_restore_dir="$ROOT_DIR/.backup/pre-restore-${timestamp}"
  mkdir -p "$pre_restore_dir"
  
  vlog "Creating pre-restore backup in $pre_restore_dir..."
  
  if ! tar czf "${pre_restore_dir}/current-state.tar.gz" \
    "$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.config/opencode" \
    >/dev/null 2>&1; then
    warn "Pre-restore backup creation failed"
    return 1
  fi
  
  # Create manifest of pre-restore state
  local manifest_json
  manifest_json=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "purpose": "Enable undo of restore operation",
  "previous_snapshot": "$(basename "$snapshot_dir")",
  "file": "current-state.tar.gz"
}
EOF
)
  echo "$manifest_json" > "${pre_restore_dir}/manifest.json"
  
  ok "Pre-restore backup created: $pre_restore_dir"
  return 0
}

# preview_config_changes(snapshot_dir)
# Shows files that would be changed (tar listing, git diff)
# Returns change count
preview_config_changes() {
  local snapshot_dir="$1"
  local config_tar="${snapshot_dir}/config-state.tar.gz"
  
  if [[ ! -f "$config_tar" ]]; then
    warn "Config tar not found for preview"
    return 1
  fi
  
  vlog "Preview: Config files in snapshot:"
  tar tzf "$config_tar" 2>/dev/null | grep -v '/$' | head -20
  
  local file_count
  file_count="$(tar tzf "$config_tar" 2>/dev/null | grep -v '/$' | wc -l)"
  
  log "Would restore $file_count configuration files"
  return 0
}


snapshot_guard_error() {
  print -u2 -r -- "$1"
  return 1
}

# resolve_snapshot_dir(snapshot_id)
# Resolves and validates a snapshot directory by ID.
# Enforces single snapshot ID input, root containment, and symlink rejection.
resolve_snapshot_dir() {
  local snapshot_id="$1"
  local snapshots_root="$ROOT_DIR/.backup/snapshots"

  if [[ -z "$snapshot_id" ]]; then
    snapshot_guard_error "Snapshot id is required"
    return 1
  fi

  if [[ "$snapshot_id" == */* ]] || [[ "$snapshot_id" == "." ]] || [[ "$snapshot_id" == ".." ]] || [[ "$snapshot_id" == *".."* ]]; then
    snapshot_guard_error "Invalid snapshot id: $snapshot_id"
    return 1
  fi

  if [[ ! -d "$snapshots_root" ]]; then
    snapshot_guard_error "Snapshot storage not found: $snapshots_root"
    return 1
  fi

  local candidate="${snapshots_root}/${snapshot_id}"
  if [[ ! -e "$candidate" ]]; then
    snapshot_guard_error "Snapshot not found: $snapshot_id"
    return 1
  fi

  if [[ -L "$candidate" ]]; then
    snapshot_guard_error "Snapshot entry is a symlink and is not allowed: $snapshot_id"
    return 1
  fi

  if [[ ! -d "$candidate" ]]; then
    snapshot_guard_error "Snapshot entry is not a directory: $snapshot_id"
    return 1
  fi

  local snapshots_root_real candidate_real
  snapshots_root_real="$(cd "$snapshots_root" && pwd -P)"
  candidate_real="$(cd "$candidate" && pwd -P)"

  case "$candidate_real" in
    "$snapshots_root_real"/*)
      ;;
    *)
      snapshot_guard_error "Snapshot path escapes snapshots root: $snapshot_id"
      return 1
      ;;
  esac

  echo "$candidate_real"
}

ok "Backup helpers loaded"
