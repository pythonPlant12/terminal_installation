# Tmux & Oh My Tmux Installation

## Description
Tmux is a terminal multiplexer that allows multiple terminal sessions within a single window. Oh My Tmux provides a beautiful and feature-rich tmux configuration.

## Installation

### Prerequisites
- A terminal emulator
- Git (for Oh My Tmux)

### Step 1: Install Tmux

#### macOS (Homebrew)
```bash
brew install tmux
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install tmux
```

#### Linux (CentOS/RHEL/Fedora)
```bash
# CentOS/RHEL
sudo yum install tmux

# Fedora
sudo dnf install tmux
```

#### Linux (Arch)
```bash
sudo pacman -S tmux
```

### Step 2: Install Oh My Tmux

```bash
# Clone Oh My Tmux
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
```

## Configuration

### Copy Configuration Files
Use the included configuration files:

```bash
# Copy Oh My Tmux directory
cp -r oh-my-tmux ~/.tmux

# Create symlink to main config
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf

# Copy local configuration
cp .tmux.conf.local ~/.tmux.conf.local
```

### Configuration Features
The included configuration provides:

#### Key Bindings
- **Prefix key**: `Ctrl+a` (instead of `Ctrl+b`)
- **Split panes**: 
  - `Prefix + |` for vertical split
  - `Prefix + -` for horizontal split
- **Navigate panes**: `Prefix + hjkl` (Vim-style)
- **Resize panes**: `Prefix + HJKL`
- **New window**: `Prefix + c`
- **Switch windows**: `Prefix + 1,2,3...`

#### Visual Features
- **Status bar**: Customized with system information
- **Color scheme**: Beautiful and readable colors
- **Window indicators**: Clear active/inactive distinction
- **System monitoring**: CPU, memory, time display

#### Mouse Support
- Mouse scrolling in panes
- Click to select panes and windows
- Resize panes with mouse

## Basic Usage

### Session Management
```bash
# Start new session
tmux

# Start named session
tmux new -s session_name

# List sessions
tmux ls

# Attach to session
tmux attach -t session_name

# Detach from session
Prefix + d
```

### Window Management
```bash
# Create new window
Prefix + c

# Switch to window by number
Prefix + 0,1,2...

# Switch to next/previous window
Prefix + n  # next
Prefix + p  # previous

# Rename window
Prefix + ,

# Close window
Prefix + &
```

### Pane Management
```bash
# Split vertically
Prefix + |

# Split horizontally
Prefix + -

# Navigate panes
Prefix + h,j,k,l

# Resize panes
Prefix + H,J,K,L

# Close pane
Prefix + x

# Toggle pane zoom
Prefix + z
```

### Copy Mode (Scrollback)
```bash
# Enter copy mode
Prefix + [

# Navigate with arrow keys or hjkl
# Search with / (forward) or ? (backward)
# Start selection with Space
# Copy selection with Enter
# Exit copy mode with q

# Paste
Prefix + ]
```

## Configuration Customization

### Edit Local Configuration
```bash
nano ~/.tmux.conf.local
```

### Common Customizations

#### Change Prefix Key
```bash
# In .tmux.conf.local
tmux_conf_copy_to_os_clipboard=true
```

#### Enable Mouse Support
```bash
# Already enabled in provided config
set -g mouse on
```

#### Custom Status Bar
```bash
# Customize status bar in .tmux.conf.local
tmux_conf_theme_status_left=' ❐ #S | ↑#{?uptime_y, #{uptime_y}y,}#{?uptime_d, #{uptime_d}d,}#{?uptime_h, #{uptime_h}h,}#{?uptime_m, #{uptime_m}m,} '
```

## Plugins (TPM - Tmux Plugin Manager)

### Install TPM
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Popular Plugins
Add to `.tmux.conf.local`:
```bash
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Initialize TMUX plugin manager (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
```

### Install Plugins
- `Prefix + I` - Install plugins
- `Prefix + U` - Update plugins
- `Prefix + alt + u` - Uninstall plugins

## Integration with Zsh

### Terminal Integration
Tmux works seamlessly with:
- Oh My Zsh
- Starship prompt
- Zsh plugins
- All terminal configurations

### Auto-start Tmux
Add to `~/.zshrc`:
```bash
# Auto-start tmux
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi
```

## Compatibility
- ✅ macOS
- ✅ Linux (all distributions)
- ✅ Windows (WSL)
- ✅ Works with all terminal emulators
- ✅ Compatible with SSH sessions
- ✅ Works with Zsh, Bash, Fish

## Troubleshooting

### Common Issues

#### Colors not working
```bash
# Add to shell profile
export TERM=screen-256color
```

#### Copy/paste issues
```bash
# macOS - install reattach-to-user-namespace
brew install reattach-to-user-namespace

# Linux - ensure xclip is installed
sudo apt install xclip  # Ubuntu/Debian
```

#### Session not restored
```bash
# Check if tmux-resurrect is working
Prefix + Ctrl+s  # Save session
Prefix + Ctrl+r  # Restore session
```

### Performance Issues
```bash
# Reduce status bar update frequency
set -g status-interval 60

# Disable automatic window renaming
set -g automatic-rename off
```

## Key Bindings Reference

### Session
- `Prefix + d` - Detach session
- `Prefix + s` - List sessions
- `Prefix + $` - Rename session

### Windows
- `Prefix + c` - Create window
- `Prefix + ,` - Rename window
- `Prefix + &` - Kill window
- `Prefix + n/p` - Next/Previous window

### Panes
- `Prefix + |` - Split vertically
- `Prefix + -` - Split horizontally
- `Prefix + hjkl` - Navigate panes
- `Prefix + HJKL` - Resize panes
- `Prefix + z` - Toggle zoom
- `Prefix + x` - Kill pane

### Copy Mode
- `Prefix + [` - Enter copy mode
- `Space` - Start selection
- `Enter` - Copy selection
- `Prefix + ]` - Paste

### Configuration
- `Prefix + :` - Command prompt
- `Prefix + r` - Reload config

## Documentation
- Tmux manual: `man tmux`
- Oh My Tmux: https://github.com/gpakosz/.tmux
- Tmux wiki: https://github.com/tmux/tmux/wiki
- Awesome Tmux: https://github.com/rothgar/awesome-tmux