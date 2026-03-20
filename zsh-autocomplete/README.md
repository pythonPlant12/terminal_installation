# Zsh Autocomplete Installation

## Description
`zsh-autocomplete` by Marlon Richert provides real-time autocomplete suggestions with a dropdown menu as you type commands.

## Installation

### Prerequisites
- Zsh shell
- Oh My Zsh (recommended) or manual zsh configuration

### Method 1: Oh My Zsh Plugin (Recommended)

```bash
# Clone the repository
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# Add to plugins in ~/.zshrc
plugins=(
  # ... other plugins
  zsh-autocomplete
  # ... other plugins
)
```

### Method 2: Manual Installation

```bash
# Clone to any directory
git clone https://github.com/marlonrichert/zsh-autocomplete.git ~/zsh-autocomplete

# Add to ~/.zshrc
source ~/zsh-autocomplete/zsh-autocomplete.plugin.zsh
```

## Post-Install: Catppuccin Mocha History Highlight

The plugin hardcodes a bright yellow background for history search matches.
A patch is included to replace it with Catppuccin Mocha Surface2 (`#585b70`) bg-only highlight.

```bash
cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git apply ~/programming/personal/terminal_installation/zsh-autocomplete/catppuccin-history-highlight.patch
```

> **Note:** This patch modifies plugin source code. It will be overwritten if you
> update the plugin via `git pull`. Re-apply the patch after each update.

## Configuration

Add these configurations to your `~/.zshrc` after sourcing Oh My Zsh:

```bash
# Zsh-autocomplete configuration
zstyle ':autocomplete:*' min-delay 0.1
zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:*' max-lines 10
zstyle ':autocomplete:*' insert-unambiguous yes
zstyle ':autocomplete:*' widget-style menu-select
```

### Configuration Options
- `min-delay`: Minimum delay before showing completions (in seconds)
- `min-input`: Minimum characters needed to trigger completion
- `max-lines`: Maximum number of completion lines to show
- `insert-unambiguous`: Auto-insert unambiguous completions
- `widget-style`: Completion display style

## Usage
- Type commands and see real-time completions
- Use arrow keys to navigate the completion menu
- Press Tab to accept a completion
- Press Ctrl+Space to toggle the completion menu

## Compatibility
- ✅ macOS
- ✅ Linux
- ✅ Works with Oh My Zsh
- ✅ Compatible with other zsh plugins

## Troubleshooting
- If completions are slow, increase `min-delay`
- If too many suggestions appear, decrease `max-lines`
- Restart your shell after configuration changes
- If history highlight reverts to yellow after plugin update, re-apply the Catppuccin patch
