#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"

# Install Ghostty if not already installed
if ! command -v ghostty &>/dev/null; then
    echo "Installing Ghostty..."
    brew install --cask ghostty
else
    echo "Ghostty is already installed."
fi

# Apply configuration
mkdir -p "$GHOSTTY_DIR"
cp "$SCRIPT_DIR/config" "$GHOSTTY_DIR/config"

echo "Done! Ghostty installed and configured."
echo "Press Cmd+Shift+, in Ghostty or restart it to apply."
