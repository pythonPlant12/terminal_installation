#!/usr/bin/env zsh
# reconcile_json_with_repo_precedence.zsh
# Copies repository OpenCode config (repo is authoritative).
# Repository config is always copied as-is; no user merge.
# This ensures predictable, safe behavior and avoids merge failures.

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

OPENCODE_SRC_DIR="$ROOT_DIR/opencode"
OPENCODE_DST_DIR="$HOME/.config/opencode"
OPENCODE_SRC_CONFIG_JSONC="$OPENCODE_SRC_DIR/opencode.jsonc"
OPENCODE_SRC_OMO_CONFIG_JSON="$OPENCODE_SRC_DIR/oh-my-opencode.json"
OPENCODE_DST_CONFIG_JSON="$OPENCODE_DST_DIR/opencode.json"
OPENCODE_DST_CONFIG_JSONC="$OPENCODE_DST_DIR/opencode.jsonc"
OPENCODE_DST_OMO_CONFIG_JSON="$OPENCODE_DST_DIR/oh-my-opencode.json"

backup_config_to_bak() {
  local target="$1"
  local backup="${target}.bak.${BACKUP_TIMESTAMP}"

  if [[ -L "$target" ]]; then
    vlog "Backup check: $target exists as symlink"
  elif [[ -e "$target" ]]; then
    vlog "Backup check: $target exists as regular path"
  else
    vlog "Backup check: $target missing; skipping backup"
  fi

  [[ -e "$target" || -L "$target" ]] || return 0

  mv -f "$target" "$backup"
  ok "Backed up: $target -> $backup"
}

# reconcile_json_with_repo_precedence() <repo_jsonc> <dst_json> <dst_jsonc> <out_json> <out_jsonc>
# Reconcile OpenCode config by copying repo config as authoritative source.
# This approach avoids complex merges and ensures predictable behavior, especially with template strings.
reconcile_json_with_repo_precedence() {
  local repo_jsonc="$1"
  local dst_json="$2"
  local dst_jsonc="$3"
  local out_json="$4"
  local out_jsonc="$5"

  # Simple copy-only approach: repo config is always authoritative.
  # Ensures predictable behavior and avoids merge failures on template strings.
  mkdir -p "$(dirname "$out_json")"
  mkdir -p "$(dirname "$out_jsonc")"
  
  # Copy repo config as-is to jsonc output
  cp "$repo_jsonc" "$out_jsonc"
  
  # Convert repo config to clean JSON for runtime
  node "$ROOT_DIR/scripts/reconcile_jsonc.js" --to-json "$repo_jsonc" "$out_json"
}



[[ -d "$OPENCODE_SRC_DIR" ]] || die "Missing OpenCode source directory: $OPENCODE_SRC_DIR"
[[ -f "$OPENCODE_SRC_CONFIG_JSONC" ]] || die "Missing OpenCode config source file: $OPENCODE_SRC_CONFIG_JSONC"
[[ -f "$OPENCODE_SRC_OMO_CONFIG_JSON" ]] || die "Missing OMO config source file: $OPENCODE_SRC_OMO_CONFIG_JSON"
require_cmd rsync
ensure_dir "$OPENCODE_DST_DIR"
BACKUP_TIMESTAMP="$(date +%Y%m%d%H%M%S)"

tmp_json="${OPENCODE_DST_CONFIG_JSON}.tmp"
tmp_jsonc="${OPENCODE_DST_CONFIG_JSONC}.tmp"
rm -f "$tmp_json" "$tmp_jsonc"

log "Reconciling OpenCode config by copying authoritative repo config..."
reconcile_json_with_repo_precedence \
  "$OPENCODE_SRC_CONFIG_JSONC" \
  "$OPENCODE_DST_CONFIG_JSON" \
  "$OPENCODE_DST_CONFIG_JSONC" \
  "$tmp_json" \
  "$tmp_jsonc"

backup_config_to_bak "$OPENCODE_DST_CONFIG_JSON"
backup_config_to_bak "$OPENCODE_DST_CONFIG_JSONC"
backup_config_to_bak "$OPENCODE_DST_OMO_CONFIG_JSON"

mv -f "$tmp_json" "$OPENCODE_DST_CONFIG_JSON"
mv -f "$tmp_jsonc" "$OPENCODE_DST_CONFIG_JSONC"
cp "$OPENCODE_SRC_OMO_CONFIG_JSON" "$OPENCODE_DST_OMO_CONFIG_JSON"

log "Copying missing OpenCode support files (excluding config files; never overwrite existing user files)..."
rsync -a --ignore-existing --exclude 'opencode.json' --exclude 'opencode.jsonc' --exclude 'oh-my-opencode.json' "$OPENCODE_SRC_DIR/" "$OPENCODE_DST_DIR/"

log "Force-deploying repo-owned OpenCode assets (rules, command, agents, hooks, skills)..."

# Force-deploy repo-owned directories (rules, command, agents, hooks, skills) to ensure updates are always applied.
# These are authoritative repo assets and should always overwrite stale installed copies.
# We exclude config files to avoid overwriting user customizations.
for repo_dir in rules command agents hooks skills; do
  src_dir="$OPENCODE_SRC_DIR/$repo_dir"
  dst_dir="$OPENCODE_DST_DIR/$repo_dir"
  
  if [[ -d "$src_dir" ]]; then
    ensure_dir "$dst_dir"
    rsync -a --exclude 'opencode.json' --exclude 'opencode.jsonc' --exclude 'oh-my-opencode.json' "$src_dir/" "$dst_dir/"
    ok "Deployed $repo_dir: $dst_dir"
  fi
done

ok "OpenCode config reconciled (repo authority applied; support files copy-only)."
