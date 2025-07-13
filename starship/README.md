# Starship Installation

## Description
Starship is a minimal, blazing-fast, and highly customizable prompt for any shell. Written in Rust, it works across all shells and operating systems.

## Installation

### Prerequisites
- A modern terminal emulator
- A [Nerd Font](https://nerdfonts.com/) installed and enabled

### Method 1: Install Script (Recommended)

#### macOS/Linux
```bash
curl -sS https://starship.rs/install.sh | sh
```

#### With auto-confirmation
```bash
curl -sS https://starship.rs/install.sh | sh -s -- --yes
```

### Method 2: Package Managers

#### macOS (Homebrew)
```bash
brew install starship
```

#### Linux (various distributions)
```bash
# Arch Linux
pacman -S starship

# Ubuntu/Debian (via snap)
snap install starship

# Fedora
dnf install starship

# openSUSE
zypper install starship
```

#### Cargo (Rust)
```bash
cargo install starship --locked
```

## Shell Integration

Add the following to your shell configuration file:

### Zsh (`~/.zshrc`)
```bash
eval "$(starship init zsh)"
```

### Bash (`~/.bashrc`)
```bash
eval "$(starship init bash)"
```

### Fish (`~/.config/fish/config.fish`)
```bash
starship init fish | source
```

### PowerShell
Add to your PowerShell profile:
```powershell
Invoke-Expression (&starship init powershell)
```

## Configuration

### Configuration File Location
- **Linux/macOS**: `~/.config/starship.toml`
- **Windows**: `C:\Users\{username}\AppData\Roaming\starship.toml`

### Create Configuration Directory
```bash
mkdir -p ~/.config
```

### Copy Configuration
Copy the included `starship.toml` to your config directory:
```bash
cp starship.toml ~/.config/starship.toml
```

## Configuration Features

### Included Configuration Highlights
- **AWS module disabled** (no more eu-west-3 display)
- **Programming languages**: Auto-detects Rust, Node.js, Python, Go, Java, PHP, Dart
- **Git integration**: Branch name and status
- **Right-aligned time**: Clean command line with time on the right
- **Custom styling**: Beautiful icons and colors
- **Context-aware**: Shows relevant information based on current directory

### Key Modules Enabled
- **Character**: Custom success/error symbols
- **Directory**: Current path with styling
- **Git**: Branch and status information
- **Languages**: Version display for detected languages
- **Package**: Shows package.json version
- **Docker**: Container context
- **Time**: Right-aligned timestamp

### Customization Examples

#### Change Success Symbol
```toml
[character]
success_symbol = '[➜](bold green)'
error_symbol = '[✗](bold red)'
```

#### Enable More Languages
```toml
[swift]
symbol = "🐦 "
style = "bold orange"

[kotlin]
symbol = "🅺 "
style = "bold blue"
```

#### Disable Modules
```toml
[aws]
disabled = true

[gcloud]
disabled = true
```

## Usage
Once installed and configured, Starship will automatically:
- Display current directory
- Show git branch and status when in a git repository
- Display programming language and version when in a project
- Show package version when in a project with package.json
- Display time on the right side of the terminal

## Nerd Fonts Setup

### Install a Nerd Font
1. Download from [Nerd Fonts](https://nerdfonts.com/)
2. Popular choices: FiraCode, Hack, JetBrains Mono
3. Install the font on your system
4. Configure your terminal to use the font

### Verify Font Installation
Check if symbols display correctly:
```bash
echo "Testing symbols: 🌱 🦀 🐍 ⬢ 📦"
```

## Compatibility
- ✅ macOS
- ✅ Linux (all major distributions)
- ✅ Windows (PowerShell, Command Prompt)
- ✅ All major shells (Zsh, Bash, Fish, PowerShell)
- ✅ Works with tmux and screen

## Performance
- **Fast**: Written in Rust for optimal performance
- **Minimal overhead**: Doesn't slow down shell startup
- **Async**: Non-blocking execution for complex modules

## Troubleshooting

### Common Issues
1. **Symbols not displaying**: Install a Nerd Font
2. **Configuration not loading**: Check file path and permissions
3. **Slow performance**: Disable heavy modules like kubernetes
4. **Colors not working**: Enable true color in terminal

### Debug Commands
```bash
# Test configuration
starship config

# Print configuration path
starship config path

# Reset to default
mv ~/.config/starship.toml ~/.config/starship.toml.backup
```

### Reset Configuration
```bash
# Backup current config
cp ~/.config/starship.toml ~/.config/starship.toml.backup

# Remove config to use defaults
rm ~/.config/starship.toml
```

## Documentation
- Official documentation: https://starship.rs/
- Configuration reference: https://starship.rs/config/
- Presets: https://starship.rs/presets/