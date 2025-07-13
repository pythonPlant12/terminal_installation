# Zsh Autosuggestions Installation

## Description
`zsh-autosuggestions` suggests commands as you type based on command history and completions, displaying them in a muted color.

## Installation

### Prerequisites
- Zsh shell
- Oh My Zsh (recommended) or manual zsh configuration

### Method 1: Oh My Zsh Plugin (Recommended)

```bash
# Clone the repository
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Add to plugins in ~/.zshrc
plugins=(
  # ... other plugins
  zsh-autosuggestions
  # ... other plugins
)
```

### Method 2: Manual Installation

```bash
# Clone to any directory
git clone https://github.com/zsh-users/zsh-autosuggestions ~/zsh-autosuggestions

# Add to ~/.zshrc
source ~/zsh-autosuggestions/zsh-autosuggestions.zsh
```

### Method 3: Package Managers

#### macOS (Homebrew)
```bash
brew install zsh-autosuggestions
# Add to ~/.zshrc
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

#### Ubuntu/Debian
```bash
sudo apt install zsh-autosuggestions
# Add to ~/.zshrc
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

## Configuration

Add these configurations to your `~/.zshrc` after sourcing Oh My Zsh:

```bash
# Zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#606060,bg=none,bold,underline"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
```

### Configuration Options
- `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`: Style for suggestion text
- `ZSH_AUTOSUGGEST_STRATEGY`: Strategy for generating suggestions
  - `history`: From command history
  - `completion`: From zsh completions
  - `match_prev_cmd`: From history matching previous command
- `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE`: Maximum buffer size for suggestions

### Color Options
```bash
# Different highlight styles
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"              # Gray
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff"        # Magenta
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan,bold"      # Bold cyan
```

## Usage
- Type commands and see gray suggestions appear
- Press **Right Arrow** or **End** to accept the entire suggestion
- Press **Ctrl+F** to accept the suggestion (alternative)
- Press **Alt+F** to accept the next word of the suggestion
- Continue typing to filter suggestions

## Key Bindings
- `→` (Right Arrow): Accept suggestion
- `End`: Accept suggestion  
- `Ctrl+F`: Accept suggestion
- `Alt+F`: Accept next word
- `Ctrl+G`: Clear suggestion

## Compatibility
- ✅ macOS
- ✅ Linux
- ✅ Works with Oh My Zsh
- ✅ Compatible with other zsh plugins
- ✅ Works with Starship prompt

## Troubleshooting
- If suggestions don't appear, check plugin loading order
- If performance is slow, try `ZSH_AUTOSUGGEST_STRATEGY=(history)`
- Restart your shell after configuration changes
- Clear history with `history -c` if getting unwanted suggestions