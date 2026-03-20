#!/usr/bin/env zsh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

BIN_DST="$HOME/.local/bin"
ensure_dir "$BIN_DST"

for f in "$ROOT_DIR/bin/"*; do
  base="$(basename "$f")"

  if [[ "${AIRCONSOLE_WITH_RECOVERY_CLI:-1}" != "1" ]]; then
    case "$base" in
      ai-setup-export|ai-setup-import|ai-setup-rollback|ai-setup-snapshot)
        vlog "Skipping recovery CLI link for $base (disabled by configuration)"
        continue
        ;;
    esac
  fi

  link_file "$f" "$BIN_DST/$base"
  chmod +x "$f" || true
done

ok "Bin scripts linked into $BIN_DST"

if [[ ":$PATH:" != *":$BIN_DST:"* ]]; then
  if ! grep -qF '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
    log "Adding $BIN_DST to PATH in ~/.zshrc"
    {
      print -r -- ""
      print -r -- "# Added by ai-setup bootstrap"
      print -r -- 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$HOME/.zshrc"
    ok "$BIN_DST added to PATH in ~/.zshrc"
  else
    vlog "$BIN_DST PATH export already present in ~/.zshrc"
  fi
  warn "Run \`source ~/.zshrc\` or start a new terminal to add $BIN_DST to PATH"
else
  vlog "$BIN_DST is already in PATH"
fi