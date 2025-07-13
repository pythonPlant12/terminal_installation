# Oh My Zsh Installation

## Description
Oh My Zsh is a framework for managing your Zsh configuration. It comes bundled with thousands of helpful functions, helpers, plugins, and themes.

## Installation

### Prerequisites
- Zsh shell installed
- Git installed
- curl or wget

### Method 1: Install Script (Recommended)

#### Via curl
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### Via wget
```bash
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### Via fetch
```bash
sh -c "$(fetch -o - https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Method 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

# Create a new zsh configuration file
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Change default shell to zsh
chsh -s $(which zsh)
```

## Configuration

### Copy Configuration File
Use the included `.zshrc` configuration:
```bash
cp .zshrc ~/.zshrc
```

### Configuration Highlights
The included configuration includes:

#### Essential Plugins
```bash
plugins=(
  git                    # Git aliases and functions
  zsh-autocomplete      # Real-time autocomplete
  zsh-autosuggestions   # Command suggestions
  zsh-syntax-highlighting # Syntax highlighting
  brew                  # Homebrew aliases
  macos                 # macOS specific functions
  colored-man-pages     # Colorized man pages
  extract               # Universal extract function
  web-search            # Web search from terminal
  copypath              # Copy current path
  copyfile              # Copy file contents
)
```

#### Theme Configuration
```bash
# Disabled in favor of Starship
# ZSH_THEME="powerlevel10k/powerlevel10k"
```

#### Additional Features
- **Command correction**: `ENABLE_CORRECTION="true"`
- **Completion dots**: `COMPLETION_WAITING_DOTS="true"`
- **Starship integration**: Modern prompt replacement
- **Plugin configurations**: Optimized settings

## Plugins Installation

### Core Plugins (Included)
These plugins come with Oh My Zsh:
- `git` - Git integration
- `brew` - Homebrew shortcuts
- `macos` - macOS specific tools
- `colored-man-pages` - Colorized documentation
- `extract` - Archive extraction
- `web-search` - Search engines integration

### Custom Plugins
Install additional plugins in `$ZSH_CUSTOM/plugins/`:

#### zsh-autosuggestions
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### zsh-syntax-highlighting
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### zsh-autocomplete
```bash
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
```

## Themes

### Default Themes
Oh My Zsh comes with 100+ themes. Popular choices:
- `robbyrussell` (default)
- `agnoster`
- `powerlevel10k`
- `spaceship`

### Starship Integration
The included configuration uses Starship instead of Oh My Zsh themes:
```bash
# Initialize Starship prompt
eval "$(starship init zsh)"
```

## Custom Configuration

### Environment Variables
```bash
# Oh My Zsh path
export ZSH="$HOME/.oh-my-zsh"

# Editor preferences
export EDITOR='nvim'
export VISUAL='nvim'
```

### Plugin Configurations
```bash
# Zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#606060,bg=none,bold,underline"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Zsh-autocomplete
zstyle ':autocomplete:*' min-delay 0.1
zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:*' max-lines 10
```

## Directory Structure
```
~/.oh-my-zsh/
├── custom/
│   ├── plugins/
│   │   ├── zsh-autosuggestions/
│   │   ├── zsh-autocomplete/
│   │   └── zsh-syntax-highlighting/
│   └── themes/
├── plugins/
├── themes/
└── tools/
```

## Useful Commands

### Oh My Zsh Management
```bash
# Update Oh My Zsh
omz update

# List available plugins
omz plugin list

# List available themes
omz theme list

# Enable/disable plugins
omz plugin enable <plugin-name>
omz plugin disable <plugin-name>
```

### Configuration Management
```bash
# Edit configuration
nano ~/.zshrc

# Reload configuration
source ~/.zshrc

# Show current theme
echo $ZSH_THEME
```

## Compatibility
- ✅ macOS
- ✅ Linux (all distributions)
- ✅ Windows (WSL)
- ✅ Works with tmux
- ✅ Compatible with all terminal emulators

## Troubleshooting

### Common Issues

#### Slow startup
```bash
# Profile zsh startup
time zsh -i -c exit

# Disable heavy plugins temporarily
# Comment out plugins in ~/.zshrc
```

#### Plugin conflicts
```bash
# Load plugins in specific order
plugins=(
  git
  zsh-autocomplete     # Load before autosuggestions
  zsh-autosuggestions
  zsh-syntax-highlighting  # Load last
)
```

#### Permission issues
```bash
# Fix Oh My Zsh permissions
chmod 755 ~/.oh-my-zsh
compaudit | xargs chmod g-w,o-w
```

### Performance Optimization
```bash
# Reduce plugin load time
zstyle ':omz:plugins:git' aliases false

# Skip verification
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
```

## Updates

### Automatic Updates
Oh My Zsh checks for updates every 2 weeks by default.

### Manual Update
```bash
omz update
```

### Disable Updates
```bash
# Add to ~/.zshrc
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
```

## Uninstallation
```bash
uninstall_oh_my_zsh
```

## Documentation
- Official website: https://ohmyz.sh/
- GitHub repository: https://github.com/ohmyzsh/ohmyzsh
- Plugin directory: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
- Theme gallery: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes