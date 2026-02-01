#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/config"

# Auto-detect the latest PyCharm version directory
PYCHARM_BASE="$HOME/Library/Application Support/JetBrains"
PYCHARM_DIR=$(find "$PYCHARM_BASE" -maxdepth 1 -type d -name "PyCharm*" | sort -V | tail -1)

if [[ -z "$PYCHARM_DIR" ]]; then
    echo "Error: No PyCharm configuration directory found under $PYCHARM_BASE"
    echo "Make sure PyCharm has been launched at least once."
    exit 1
fi

echo "Detected PyCharm config: $PYCHARM_DIR"
echo ""

# --- Install keymaps ---
echo "Installing keymaps..."
mkdir -p "$PYCHARM_DIR/keymaps"
cp "$CONFIG_SRC/keymaps/"*.xml "$PYCHARM_DIR/keymaps/"

# --- Install codestyles ---
echo "Installing codestyles..."
mkdir -p "$PYCHARM_DIR/codestyles"
cp "$CONFIG_SRC/codestyles/"*.xml "$PYCHARM_DIR/codestyles/"

# --- Install color schemes ---
echo "Installing color schemes..."
mkdir -p "$PYCHARM_DIR/colors"
cp "$CONFIG_SRC/colors/"*.icls "$PYCHARM_DIR/colors/"

# --- Install inspection profiles ---
echo "Installing inspection profiles..."
mkdir -p "$PYCHARM_DIR/inspection"
cp "$CONFIG_SRC/inspection/"*.xml "$PYCHARM_DIR/inspection/"

# --- Install options ---
echo "Installing options..."
mkdir -p "$PYCHARM_DIR/options"
cp "$CONFIG_SRC/options/"*.xml "$PYCHARM_DIR/options/"

if [[ -d "$CONFIG_SRC/options/mac" ]]; then
    mkdir -p "$PYCHARM_DIR/options/mac"
    cp "$CONFIG_SRC/options/mac/"* "$PYCHARM_DIR/options/mac/"
fi

# --- Install .ideavimrc ---
echo "Installing .ideavimrc..."
cp "$CONFIG_SRC/ideavimrc" "$HOME/.ideavimrc"

echo ""
echo "Done! All PyCharm configuration files have been installed."
echo "Restart PyCharm for changes to take effect."
