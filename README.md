# Terminal Installation Package

A complete terminal setup with modern tools for enhanced productivity and beautiful interface.

## Overview

This package contains configurations and installation guides for:

- **🚀 Starship** - Cross-shell prompt with programming language detection
- **🎯 Oh My Zsh** - Zsh framework with plugins and themes
- **💡 zsh-autosuggestions** - Fish-like command suggestions
- **⚡ zsh-autocomplete** - Real-time autocomplete with menu selection
- **🖥️ Tmux + Oh My Tmux** - Terminal multiplexer with beautiful configuration

## Quick Installation

### Prerequisites

Ensure you have these installed:
- **Zsh shell** (default on macOS, install on Linux)
- **Git** 
- **curl** or **wget**
- **A Nerd Font** (for icons and symbols)

### One-Command Setup

```bash
# Clone this repository
git clone <this-repo-url> ~/terminal-setup
cd ~/terminal-setup

# Run the installation script
chmod +x install.sh
./install.sh
```

### Manual Installation

Follow the installation order below for best results:

## Installation Order

### 1. Install Oh My Zsh
```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copy configuration
cp oh-my-zsh/.zshrc ~/.zshrc
```

### 2. Install Zsh Plugins
```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-autocomplete
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete

# zsh-syntax-highlighting (if not already installed)
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### 3. Install Starship
```bash
# Install Starship
curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Copy configuration
mkdir -p ~/.config
cp starship/starship.toml ~/.config/starship.toml
```

### 4. Install Tmux (Optional)
```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt install tmux

# Install Oh My Tmux
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp tmux/.tmux.conf.local ~/.tmux.conf.local
```

### 5. Apply Configuration
```bash
# Reload shell configuration
source ~/.zshrc

# Or restart terminal
```

## Features

### 🎨 Beautiful Prompt
- **Programming language detection** - Shows Node.js, Rust, Python, Go versions
- **Git integration** - Branch name and status
- **Right-aligned time** - Clean command line
- **Custom icons** - Modern look with Nerd Font symbols
- **AWS module disabled** - No more eu-west-3 display

### ⚡ Enhanced Productivity
- **Real-time autocomplete** - Dropdown menu as you type
- **Command suggestions** - Based on history and completions
- **Syntax highlighting** - Color-coded commands
- **Git shortcuts** - Aliases for common git operations
- **Extract function** - Universal archive extraction

### 🖥️ Terminal Multiplexing
- **Multiple sessions** - Organize your work
- **Pane splitting** - Vertical and horizontal splits
- **Session persistence** - Resume work after disconnection
- **Mouse support** - Click to navigate
- **Beautiful status bar** - System information display

## Directory Structure

```
terminal_installation/
├── README.md                 # This file
├── install.sh               # Automated installation script
├── oh-my-zsh/
│   ├── .zshrc               # Zsh configuration
│   └── README.md            # Oh My Zsh installation guide
├── starship/
│   ├── starship.toml        # Starship configuration
│   └── README.md            # Starship installation guide
├── zsh-autosuggestions/
│   ├── zsh-autosuggestions/ # Plugin source code
│   └── README.md            # Installation guide
├── zsh-autocomplete/
│   ├── zsh-autocomplete/    # Plugin source code
│   └── README.md            # Installation guide
├── tmux/
│   ├── oh-my-tmux/          # Oh My Tmux source
│   ├── .tmux.conf.local     # Tmux configuration
│   └── README.md            # Tmux installation guide
└── configs/
    └── .p10k.zsh            # Powerlevel10k config (backup)
```

## Configuration Details

### Zsh Configuration Highlights

#### Enabled Plugins
```bash
plugins=(
  git                    # Git aliases and functions
  zsh-autocomplete      # Real-time autocomplete
  zsh-autosuggestions   # Command suggestions
  zsh-syntax-highlighting # Syntax highlighting
  brew                  # Homebrew aliases (macOS)
  macos                 # macOS specific functions
  colored-man-pages     # Colorized documentation
  extract               # Universal extract function
  web-search            # Search engines from terminal
  copypath              # Copy current path to clipboard
  copyfile              # Copy file contents to clipboard
)
```

#### Starship Integration
```bash
# Initialize Starship prompt (replaces Oh My Zsh themes)
eval "$(starship init zsh)"
```

#### Plugin Configurations
```bash
# Autosuggestions styling
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#606060,bg=none,bold,underline"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Autocomplete settings
zstyle ':autocomplete:*' min-delay 0.1
zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:*' max-lines 10
```

### Starship Features

- **Language Detection**: Automatically shows versions for:
  - Node.js (⬢)
  - Rust (🦀)
  - Python (🐍)
  - Go (🐹)
  - Java (☕)
  - PHP (🐘)
  - Dart (🎯)

- **Git Integration**: Branch name with status indicators
- **Docker Context**: Shows current Docker context
- **Package Version**: Displays package.json version
- **Right-aligned Time**: Keeps command line clean

## Platform Compatibility

### ✅ Supported Platforms
- **macOS** - Full support with Homebrew
- **Linux** - Ubuntu, Debian, CentOS, Fedora, Arch
- **Windows** - WSL (Windows Subsystem for Linux)

### 🔧 Terminal Emulators
- **iTerm2** (macOS) - Recommended
- **Terminal.app** (macOS)
- **Alacritty** (Cross-platform)
- **GNOME Terminal** (Linux)
- **Windows Terminal** (Windows)
- **Hyper** (Cross-platform)

## Troubleshooting

### Common Issues

#### 1. Symbols not displaying correctly
**Solution**: Install a Nerd Font
```bash
# Download and install from: https://nerdfonts.com/
# Popular choices: FiraCode Nerd Font, Hack Nerd Font
```

#### 2. Plugins not loading
**Solution**: Check plugin order and installation
```bash
# Verify plugins are in correct directory
ls ~/.oh-my-zsh/custom/plugins/

# Reload configuration
source ~/.zshrc
```

#### 3. Slow terminal startup
**Solution**: Profile and optimize
```bash
# Profile startup time
time zsh -i -c exit

# Disable heavy plugins temporarily
# Comment out plugins in ~/.zshrc
```

#### 4. Autocomplete conflicts
**Solution**: Adjust plugin order
```bash
plugins=(
  git
  zsh-autocomplete     # Load before autosuggestions
  zsh-autosuggestions
  zsh-syntax-highlighting  # Always load last
)
```

### Performance Optimization

#### Reduce Startup Time
```bash
# Skip Oh My Zsh automatic updates
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Reduce autocomplete delay
zstyle ':autocomplete:*' min-delay 0.2
```

#### Memory Usage
```bash
# Limit autosuggestion buffer
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Reduce completion lines
zstyle ':autocomplete:*' max-lines 8
```

## Customization

### Adding More Languages to Starship

Edit `~/.config/starship.toml`:
```toml
[swift]
symbol = "🐦 "
style = "bold orange"

[kotlin]
symbol = "🅺 "
style = "bold blue"

[ruby]
symbol = "💎 "
style = "bold red"
```

### Custom Zsh Aliases

Add to `~/.zshrc`:
```bash
# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
```

### Tmux Customization

Edit `~/.tmux.conf.local` for tmux customizations:
```bash
# Change prefix key
tmux_conf_copy_to_os_clipboard=true

# Custom key bindings
bind-key r source-file ~/.tmux.conf \; display-message "Config reloaded!"
```

## Maintenance

### Updates

#### Update Oh My Zsh
```bash
omz update
```

#### Update Plugins
```bash
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-autocomplete && git pull
cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && git pull
```

#### Update Starship
```bash
curl -sS https://starship.rs/install.sh | sh -s -- --yes
```

#### Update Tmux Configuration
```bash
cd ~/.tmux && git pull
```

### Backup Configuration

```bash
# Create backup
mkdir ~/terminal-backup
cp ~/.zshrc ~/terminal-backup/
cp ~/.config/starship.toml ~/terminal-backup/
cp ~/.tmux.conf.local ~/terminal-backup/
```

## Uninstallation

### Remove Oh My Zsh
```bash
uninstall_oh_my_zsh
```

### Remove Starship
```bash
rm /usr/local/bin/starship
rm ~/.config/starship.toml
```

### Remove Tmux Configuration
```bash
rm ~/.tmux.conf
rm ~/.tmux.conf.local
rm -rf ~/.tmux
```

## Support and Documentation

### Official Documentation
- [Oh My Zsh](https://ohmyz.sh/)
- [Starship](https://starship.rs/)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete)
- [Tmux](https://github.com/tmux/tmux/wiki)
- [Oh My Tmux](https://github.com/gpakosz/.tmux)

### Getting Help
- Check individual README files in each subdirectory
- Consult official documentation for advanced configuration
- Open issues in respective GitHub repositories
- Search Stack Overflow for specific problems

---

**Enjoy your enhanced terminal experience! 🚀**