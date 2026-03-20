#!/usr/bin/env zsh
set -euo pipefail

# PHASE_ID: 02
# PHASE_LABEL: dependencies

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT_DIR/scripts/lib.zsh"

[[ -f "$ROOT_DIR/Brewfile" ]] || die "Missing Brewfile at repository root"

require_cmd brew

vlog "Updating Homebrew formulae..."
if ! retry_with_backoff 3 1 "brew update" -- brew update 2>&1; then
  warn "brew update failed (network issue?); proceeding with cached formula index."
fi

vlog "Checking Brewfile state..."
if brew bundle check --file "$ROOT_DIR/Brewfile" >/dev/null 2>&1; then
  ok "Brewfile dependencies already satisfied."
else
  vlog "Installing missing Brewfile dependencies..."
  if ! retry_with_backoff 3 1 "brew bundle install" -- brew bundle install --file "$ROOT_DIR/Brewfile" --no-upgrade 2>&1; then
    print -r -- "ERROR: brew bundle install --file $ROOT_DIR/Brewfile --no-upgrade"
    die "Failed to install Brewfile dependencies after retries"
  fi
  ok "Brewfile dependencies installed."
fi

# Detect node — prefer nvm over brew
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_SH="$NVM_DIR/nvm.sh"

if command -v node >/dev/null 2>&1; then
  ok "node already installed: $(node --version 2>/dev/null || echo 'unknown')"
elif [[ -s "$NVM_SH" ]]; then
  # nvm is installed — use it
  log "nvm found at $NVM_DIR, checking installed node versions..."
  # shellcheck disable=SC1090
  source "$NVM_SH"
  # Get highest installed version (nvm ls outputs sorted, last non-system line is highest)
  local nvm_node_version
  nvm_node_version=$(nvm ls --no-colors 2>/dev/null | grep -v 'system\|none\|N/A' | tail -1 | tr -d '[:space:]v->*')
  if [[ -n "$nvm_node_version" ]]; then
    nvm use "$nvm_node_version" >/dev/null 2>&1
    local major_version
    major_version=$(node --version | sed 's/v\([0-9]*\).*/\1/')
    echo "$major_version" > "$ROOT_DIR/.nvmrc"
    ok "node activated via nvm: $(node --version) (wrote .nvmrc: $major_version)"
  else
    log "nvm installed but no node versions found, installing LTS..."
    if ! retry_with_backoff 3 1 "nvm install --lts" -- nvm install --lts 2>&1; then
      die "Failed to install node via nvm"
    fi
    local major_version
    major_version=$(node --version | sed 's/v\([0-9]*\).*/\1/')
    echo "$major_version" > "$ROOT_DIR/.nvmrc"
    ok "node installed via nvm: $(node --version) (wrote .nvmrc: $major_version)"
  fi
else
  # Neither node nor nvm found — install nvm
  log "Installing nvm via official installer..."
  local nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
  if ! curl -fsSL "$nvm_install_url" | bash 2>&1; then
    print -r -- "ERROR: Failed to install nvm from $nvm_install_url"
    print -r -- "TIP: Check network access, then rerun ./bootstrap.zsh"
    die "Failed to install nvm"
  fi
  # shellcheck disable=SC1090
  source "$NVM_SH"
  log "Installing node LTS via nvm..."
  if ! retry_with_backoff 3 1 "nvm install --lts" -- nvm install --lts 2>&1; then
    die "Failed to install node via nvm"
  fi
  local major_version
  major_version=$(node --version | sed 's/v\([0-9]*\).*/\1/')
  echo "$major_version" > "$ROOT_DIR/.nvmrc"
  ok "nvm + node installed: $(node --version) (wrote .nvmrc: $major_version)"
fi

# Detect bun — check ~/.bun/bin before running installer
if command -v bun >/dev/null 2>&1; then
  ok "bun already installed: $(bun --version 2>/dev/null || echo 'unknown')"
elif [[ -x "$HOME/.bun/bin/bun" ]]; then
  export PATH="$HOME/.bun/bin:$PATH"
  ok "bun already installed (not on PATH): $(bun --version 2>/dev/null || echo 'unknown')"
else
  log "Installing bun via official installer..."
  if ! curl -fsSL https://bun.sh/install | BUN_INSTALL="$HOME/.bun" bash 2>&1; then
    print -r -- "ERROR: Failed to install bun from https://bun.sh/install"
    print -r -- "TIP: Check network access, then rerun ./bootstrap.zsh"
    die "Failed to install bun"
  fi
  export PATH="$HOME/.bun/bin:$PATH"
  ok "bun installed: $(bun --version 2>/dev/null || echo 'unknown')"
fi

ok "Manifest convergence complete."
