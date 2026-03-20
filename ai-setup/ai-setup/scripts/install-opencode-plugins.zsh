#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

require_cmd node
require_cmd bun

extract_plugin_specs() {
  local config_file="$1"

  node - "$config_file" <<'NODE'
const fs = require('fs');

const configFile = process.argv[2];
const text = fs.readFileSync(configFile, 'utf8');
const pluginMatch = text.match(/"plugin"\s*:\s*\[([\s\S]*?)\]/m);

if (!pluginMatch) {
  process.exit(0);
}

const specs = [...pluginMatch[1].matchAll(/"([^"]+)"/g)]
  .map((match) => match[1])
  .filter(Boolean);

for (const spec of specs) {
  console.log(spec);
}
NODE
}

plugin_package_name() {
  local spec="$1"

  if [[ "$spec" == @*/* ]]; then
    if [[ "$spec" == @*/*@* ]]; then
      print -r -- "${spec%@*}"
    else
      print -r -- "$spec"
    fi
    return 0
  fi

  if [[ "$spec" == *@* ]]; then
    print -r -- "${spec%%@*}"
    return 0
  fi

  print -r -- "$spec"
}

PLUGIN_CONFIG_FILE="$ROOT_DIR/opencode/opencode.jsonc"
[[ -f "$PLUGIN_CONFIG_FILE" ]] || die "Missing OpenCode config: $PLUGIN_CONFIG_FILE"

typeset -a plugin_specs=()
while IFS= read -r spec; do
  [[ -n "$spec" ]] || continue
  plugin_specs+=("$spec")
done < <(extract_plugin_specs "$PLUGIN_CONFIG_FILE")

if (( ${#plugin_specs[@]} == 0 )); then
  warn "No npm plugins declared in $PLUGIN_CONFIG_FILE"
  exit 0
fi

local_cache_dir="$HOME/.cache/opencode"
ensure_dir "$local_cache_dir"

if [[ ! -f "$local_cache_dir/package.json" ]]; then
  cat >"$local_cache_dir/package.json" <<'EOF'
{
  "name": "opencode-plugin-cache",
  "private": true
}
EOF
fi

if command -v opencode >/dev/null 2>&1; then
  opencode --version >/dev/null 2>&1 || true
fi

log "Installing OpenCode npm plugins from repo config..."
(cd "$local_cache_dir" && bun add "${plugin_specs[@]}")

typeset -a missing_packages=()
for spec in "${plugin_specs[@]}"; do
  package_name="$(plugin_package_name "$spec")"
  if [[ ! -d "$local_cache_dir/node_modules/$package_name" ]]; then
    missing_packages+=("$package_name")
  fi
done

if (( ${#missing_packages[@]} > 0 )); then
  die "Plugin install incomplete. Missing packages: ${(j:, :)missing_packages}"
fi

ok "OpenCode npm plugins installed: ${(j:, :)plugin_specs}"
