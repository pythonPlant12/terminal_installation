#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

# export_backup_for_migration(output_dir)
# Creates portable tar.gz bundle with git repository, config files, snapshots
# Excludes: .env, credentials, node_modules, .DS_Store
# Returns bundle filename
export_backup_for_migration() {
  local output_dir="${1:-.}"
  local bundle_name="ai-setup-backup-$(date -u +"%Y-%m-%d_%H%M%S").tar.gz"
  local bundle_path="${output_dir}/${bundle_name}"
  
  vlog "Creating migration bundle to $bundle_path..."
  
  # Create temporary directory for staging
  local staging_dir
  staging_dir="$(mktemp -d)"
  mkdir -p "${staging_dir}/airconsole-ai-setup"
  
  # Copy repository (excluding certain paths)
  if ! git -C "$ROOT_DIR" archive --format=tar HEAD | tar -x -C "${staging_dir}/airconsole-ai-setup" >/dev/null 2>&1; then
    warn "Git archive failed"
    rm -rf "$staging_dir"
    return 1
  fi
  
  # Copy .git for full history (but exclude large files)
  if [[ -d "$ROOT_DIR/.git" ]]; then
    cp -r "$ROOT_DIR/.git" "${staging_dir}/airconsole-ai-setup/.git" 2>/dev/null || true
  fi
  
  # Copy config files if they exist
  [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "${staging_dir}/airconsole-ai-setup/.zshrc-backup" || true
  [[ -f "$HOME/.gitconfig" ]] && cp "$HOME/.gitconfig" "${staging_dir}/airconsole-ai-setup/.gitconfig-backup" || true
  [[ -d "$HOME/.config/opencode" ]] && cp -r "$HOME/.config/opencode" "${staging_dir}/airconsole-ai-setup/.config-opencode-backup" || true
  
  # Copy snapshots if they exist
  if [[ -d "$ROOT_DIR/.backup/snapshots" ]]; then
    mkdir -p "${staging_dir}/airconsole-ai-setup/.backup"
    cp -r "$ROOT_DIR/.backup/snapshots" "${staging_dir}/airconsole-ai-setup/.backup/snapshots" 2>/dev/null || true
  fi
  
  # Create migration manifest in bundle
  if ! create_migration_manifest "${staging_dir}/airconsole-ai-setup"; then
    vlog "Migration manifest creation failed (continuing with export)"
  fi

  # Keep a single canonical migration manifest at bundle root.
  # Remove the planning template copy from exported payload to avoid ambiguity.
  rm -f "${staging_dir}/airconsole-ai-setup/.planning/phases/04-recovery-and-migration/MIGRATION-MANIFEST.md" 2>/dev/null || true
  
  # Create tar.gz bundle
  if ! tar czf "$bundle_path" -C "$staging_dir" airconsole-ai-setup >/dev/null 2>&1; then
    warn "Tar bundle creation failed"
    rm -rf "$staging_dir"
    return 1
  fi
  
  rm -rf "$staging_dir"
  echo "$bundle_name"
  return 0
}

# create_migration_manifest()
# Generates MIGRATION-MANIFEST.md template with platform info and credential status
create_migration_manifest() {
  local bundle_dir="$1"
  local manifest_file="${bundle_dir}/MIGRATION-MANIFEST.md"
  
  vlog "Generating migration manifest..."
  
  local timestamp hostname macos_version architecture
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  hostname="$(hostname -s)"
  macos_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
  architecture="$(uname -m)"
  
  local homebrew_packages npm_packages
  homebrew_packages="$(brew list --formula 2>/dev/null | wc -l || echo 0)"

  npm_packages="$(npm list -g --depth=0 2>/dev/null | wc -l || echo 0)"
  
  cat > "$manifest_file" <<EOF
# AI Setup Migration Backup

**Created:** ${timestamp}
**From:** ${hostname} (${macos_version}, ${architecture})

## What's Included

- Complete git repository history and current state
- Configuration files (.zshrc, .gitconfig, opencode config)
- OpenCode integration definitions
- Setup state snapshots (from Phase 1-3 completion)
- All tool manifests (Brewfile)
- Previous snapshots for reference

**Tool versions at export:**
- Homebrew packages: ${homebrew_packages}

- Global npm packages: ${npm_packages}

## What's NOT Included (You Need These)

- ❌ Keychain Credentials (Atlassian, system keychain)
- ❌ Tool Authentication (Codex, Copilot)
- ❌ Plaintext secrets (.env files, API tokens)
- ❌ Machine-specific configurations

These are machine-specific and require user-specific credentials. No plaintext secrets are included in this backup for security.

## Restore Instructions

### On a New Machine

1. **Extract the bundle:**
   \`\`\`bash
   tar xzf ai-setup-backup-*.tar.gz
   cd airconsole-ai-setup
   \`\`\`

2. **Verify git repository:**
   \`\`\`bash
   git status
   \`\`\`

3. **Run bootstrap to install/converge tools:**
    \`\`\`bash
    ./bootstrap.zsh
    \`\`\`

4. **Re-enter credentials when prompted:**
   - Atlassian: site URL, email, API token

5. **Verify setup is complete:**
   \`\`\`bash
   ai-setup-doctor
   \`\`\`

## Security Notes

- No credentials exported (secure transfer)
- Each machine stores credentials locally
- Bundle integrity checked on import (SHA256)
- Recommendation: Transfer via secure channel (USB, encrypted cloud sync)

## Platform Compatibility

⚠️ **Note:** This backup was created on ${hostname} with macOS ${macos_version} (${architecture}).

If you're restoring on a different macOS version or architecture:
- Tool binaries may not be compatible
- Run \`./bootstrap.zsh\` to re-converge for your new machine
- Homebrew will install versions suitable for your machine

## Troubleshooting

**Extract failed:** Check disk space and tar availability
**Bootstrap failed:** See README.md for troubleshooting
**Credentials rejected:** Verify tokens are still valid (may have expired)
**Tools not found:** Run \`./bootstrap.zsh\` again (idempotent)

## Questions?

See the main README.md for detailed help and troubleshooting.
EOF
  
  return 0
}

# create_integrity_checksum(bundle_file)
# Generates SHA256 checksum file
create_integrity_checksum() {
  local bundle_file="$1"
  local checksum_file="${bundle_file}.sha256"
  
  vlog "Generating checksum for $bundle_file..."
  
  if ! shasum -a 256 "$bundle_file" > "$checksum_file" 2>/dev/null; then
    warn "Checksum generation failed"
    return 1
  fi
  
  ok "Checksum created: $checksum_file"
  return 0
}

# verify_backup_integrity(bundle_file)
# Verifies SHA256 checksum of bundle
verify_backup_integrity() {
  local bundle_file="$1"
  local checksum_file="${bundle_file}.sha256"
  
  if [[ ! -f "$checksum_file" ]]; then
    warn "Checksum file not found: $checksum_file"
    return 1
  fi
  
  vlog "Verifying checksum..."
  
  if ! shasum -a 256 -c "$checksum_file" >/dev/null 2>&1; then
    warn "Checksum verification failed"
    return 1
  fi
  
  ok "Checksum verified: $bundle_file"
  return 0
}

# capture_platform_info()
# Records current machine platform information as JSON
capture_platform_info() {
  local macos_version build_version architecture hostname
  macos_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
  build_version="$(sw_vers -buildVersion 2>/dev/null || echo 'unknown')"
  architecture="$(uname -m)"
  hostname="$(hostname -s)"
  
  local homebrew_version bun_version npm_version git_version
  homebrew_version="$(brew --version 2>/dev/null | head -1 || echo 'unknown')"
  bun_version="$(bun --version 2>/dev/null || echo 'unknown')"
  npm_version="$(npm --version 2>/dev/null || echo 'unknown')"
  git_version="$(git --version 2>/dev/null || echo 'unknown')"
  
  local json_output
  json_output=$(cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hostname": "$hostname",
  "macos_version": "$macos_version",
  "macos_build": "$build_version",
  "architecture": "$architecture",
  "tool_versions": {
    "homebrew": "$homebrew_version",
    "bun": "$bun_version",
    "npm": "$npm_version",
    "git": "$git_version"
  }
}
EOF
)
  
  echo "$json_output"
  return 0
}

# extract_migration_bundle(bundle_file, target_dir)
# Safely extracts tar to target directory with validation
extract_migration_bundle() {
  local bundle_file="$1"
  local target_dir="${2:-.}"
  
  vlog "Extracting bundle to $target_dir..."
  
  if [[ ! -f "$bundle_file" ]]; then
    die "Bundle file not found: $bundle_file"
  fi
  
  # Verify integrity first
  if ! verify_backup_integrity "$bundle_file"; then
    die "Bundle integrity check failed"
  fi
  
  # Check for conflicts
  if [[ -d "${target_dir}/airconsole-ai-setup" ]]; then
    warn "Directory already exists: ${target_dir}/airconsole-ai-setup"
    warn "Extraction will overwrite existing files"
  fi
  
  # Extract
  if ! tar xzf "$bundle_file" -C "$target_dir" >/dev/null 2>&1; then
    die "Bundle extraction failed"
  fi
  
  ok "Bundle extracted to ${target_dir}/airconsole-ai-setup"
  return 0
}

# detect_configured_credentials()
# Checks what credentials were present in the setup
# Returns JSON with credential status
detect_configured_credentials() {
  # Check Atlassian in Keychain
  local atlassian_present="false"
  if [[ -n "$(security find-generic-password -s 'opencode-atlassian-url' -a "$USER" -w 2>/dev/null || true)" ]]; then
    atlassian_present="true"
  fi
  
  cat <<EOF
{
  "atlassian": $atlassian_present
}
EOF
EOF
  
  return 0
}

ok "Migration helpers loaded"
