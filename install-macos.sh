#!/bin/bash

# Terminal Installation Script for macOS
# Installs Oh My Zsh, Starship, Zsh plugins, and Tmux with configurations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is for macOS only. Use install-ubuntu.sh for Ubuntu."
        exit 1
    fi
    print_success "Running on macOS"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if running in correct directory
    if [[ ! -f "install-macos.sh" ]]; then
        print_error "Please run this script from the terminal_installation directory"
        exit 1
    fi
    
    # Check for required commands
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed. Please install Git first."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Check/Install Homebrew
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for M1 Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed"
    else
        print_success "Homebrew found"
    fi
    
    # Check for Zsh (should be default on macOS)
    if ! command -v zsh &> /dev/null; then
        print_warning "Zsh not found. Installing via Homebrew..."
        brew install zsh
        print_success "Zsh installed"
    else
        print_success "Zsh found"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_step "Installing Oh My Zsh..."
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_warning "Oh My Zsh already installed. Backing up existing installation..."
        mv "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Install Oh My Zsh (non-interactive)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    print_success "Oh My Zsh installed"
}

# Install Zsh plugins
install_zsh_plugins() {
    print_step "Installing Zsh plugins..."
    
    # Create custom plugins directory
    mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # Install zsh-autosuggestions
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_warning "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        print_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_warning "zsh-syntax-highlighting already installed"
    fi
    
    # Install zsh-autocomplete
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete" ]]; then
        print_info "Installing zsh-autocomplete..."
        git clone https://github.com/marlonrichert/zsh-autocomplete.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete"
        print_success "zsh-autocomplete installed"
    else
        print_warning "zsh-autocomplete already installed"
    fi
}

# Install Starship
install_starship() {
    print_step "Installing Starship..."
    
    if command -v starship &> /dev/null; then
        print_warning "Starship already installed. Updating..."
    fi
    
    # Install Starship
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    print_success "Starship installed"
}

# Install Tmux and Oh My Tmux
install_tmux() {
    print_step "Installing Tmux and Oh My Tmux..."
    
    # Install tmux via Homebrew
    if ! command -v tmux &> /dev/null; then
        print_info "Installing tmux via Homebrew..."
        brew install tmux
        print_success "Tmux installed"
    else
        print_success "Tmux already installed"
    fi
    
    # Install Oh My Tmux
    if [[ -d "$HOME/.tmux" ]]; then
        print_warning "Oh My Tmux already installed. Backing up..."
        mv "$HOME/.tmux" "$HOME/.tmux.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    print_info "Installing Oh My Tmux..."
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
    print_success "Oh My Tmux installed"
}

# Copy configurations
copy_configurations() {
    print_step "Copying configurations..."
    
    # Backup existing configurations
    backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/"
        print_info "Backed up existing .zshrc"
    fi
    
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$backup_dir/"
        print_info "Backed up existing starship.toml"
    fi
    
    if [[ -f "$HOME/.tmux.conf.local" ]]; then
        cp "$HOME/.tmux.conf.local" "$backup_dir/"
        print_info "Backed up existing .tmux.conf.local"
    fi
    
    # Copy new configurations
    print_info "Copying .zshrc configuration..."
    cp "oh-my-zsh/.zshrc" "$HOME/.zshrc"
    
    print_info "Copying Starship configuration..."
    mkdir -p "$HOME/.config"
    cp "starship/starship.toml" "$HOME/.config/starship.toml"
    
    if [[ -f "tmux/.tmux.conf.local" ]]; then
        print_info "Copying Tmux configuration..."
        cp "tmux/.tmux.conf.local" "$HOME/.tmux.conf.local"
    fi

    if [[ -f "tmux/.tmux-tab-style.conf" ]]; then
        print_info "Copying Tmux tab style configuration..."
        cp "tmux/.tmux-tab-style.conf" "$HOME/.tmux-tab-style.conf"
    fi
    
    print_success "Configurations copied (backups in $backup_dir)"
}

# Install Nerd Font (optional)
install_nerd_font() {
    print_step "Installing Nerd Font (FiraCode)..."
    
    if brew list --cask font-fira-code-nerd-font &> /dev/null; then
        print_warning "FiraCode Nerd Font already installed"
    else
        print_info "Installing FiraCode Nerd Font via Homebrew..."
        brew tap homebrew/cask-fonts
        brew install --cask font-fira-code-nerd-font
        print_success "FiraCode Nerd Font installed"
        print_warning "Please configure your terminal to use 'FiraCode Nerd Font'"
    fi
}

# Set Zsh as default shell
set_default_shell() {
    print_step "Setting Zsh as default shell..."
    
    current_shell=$(echo $SHELL)
    zsh_path=$(which zsh)
    
    if [[ "$current_shell" != "$zsh_path" ]]; then
        print_info "Changing default shell to Zsh..."
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
        fi
        
        chsh -s "$zsh_path"
        print_success "Default shell changed to Zsh"
        print_warning "You may need to restart your terminal or reboot"
    else
        print_success "Zsh is already the default shell"
    fi
}

# Install and configure Ghostty
install_ghostty() {
    print_step "Installing and configuring Ghostty..."

    if ! command -v ghostty &> /dev/null; then
        print_info "Installing Ghostty via Homebrew..."
        brew install --cask ghostty
        print_success "Ghostty installed"
    else
        print_success "Ghostty already installed"
    fi

    GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    mkdir -p "$GHOSTTY_DIR"
    if [[ -f "$GHOSTTY_DIR/config" ]]; then
        print_info "Backed up existing Ghostty config"
        cp "$GHOSTTY_DIR/config" "$backup_dir/ghostty-config" 2>/dev/null || true
    fi
    cp "ghostty/config" "$GHOSTTY_DIR/config"
    print_success "Ghostty configured"
}

install_zed() {
    print_step "Installing and configuring Zed..."

    if ! command -v zed &> /dev/null; then
        print_info "Installing Zed via Homebrew..."
        brew install --cask zed
        print_success "Zed installed"
    else
        print_success "Zed already installed"
    fi

    local zed_backup_dir="${backup_dir:-$HOME/.zed_config_backup_$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$HOME/.config/zed/themes" "$zed_backup_dir"

    if [[ -f "$HOME/.config/zed/settings.json" ]]; then
        cp "$HOME/.config/zed/settings.json" "$zed_backup_dir/settings.json" 2>/dev/null || true
    fi

    if [[ -f "$HOME/.config/zed/keymap.json" ]]; then
        cp "$HOME/.config/zed/keymap.json" "$zed_backup_dir/keymap.json" 2>/dev/null || true
    fi

    if [[ -f "$HOME/.config/zed/tasks.json" ]]; then
        cp "$HOME/.config/zed/tasks.json" "$zed_backup_dir/tasks.json" 2>/dev/null || true
    fi

    if [[ -f "$HOME/.config/zed/themes/islands-dark.json" ]]; then
        cp "$HOME/.config/zed/themes/islands-dark.json" "$zed_backup_dir/islands-dark.json" 2>/dev/null || true
    fi

    cp "zed/settings.json" "$HOME/.config/zed/settings.json"
    cp "zed/keymap.json" "$HOME/.config/zed/keymap.json"
    cp "zed/tasks.json" "$HOME/.config/zed/tasks.json"
    cp "zed/themes/islands-dark.json" "$HOME/.config/zed/themes/islands-dark.json"

    print_success "Zed installed and configured"
}

# Install PyCharm configuration
install_pycharm_config() {
    print_step "Installing PyCharm configuration..."

    PYCHARM_BASE="$HOME/Library/Application Support/JetBrains"
    PYCHARM_DIR=$(find "$PYCHARM_BASE" -maxdepth 1 -type d -name "PyCharm*" 2>/dev/null | sort -V | tail -1)

    if [[ -z "$PYCHARM_DIR" ]]; then
        print_warning "No PyCharm config directory found. Skipping (launch PyCharm once first)."
        return
    fi

    print_info "Detected PyCharm config: $PYCHARM_DIR"

    # Keymaps
    mkdir -p "$PYCHARM_DIR/keymaps"
    cp jetbrains/pycharm/config/keymaps/*.xml "$PYCHARM_DIR/keymaps/"

    # Code styles
    mkdir -p "$PYCHARM_DIR/codestyles"
    cp jetbrains/pycharm/config/codestyles/*.xml "$PYCHARM_DIR/codestyles/"

    # Color schemes
    mkdir -p "$PYCHARM_DIR/colors"
    cp jetbrains/pycharm/config/colors/*.icls "$PYCHARM_DIR/colors/"

    # Inspection profiles
    mkdir -p "$PYCHARM_DIR/inspection"
    cp jetbrains/pycharm/config/inspection/*.xml "$PYCHARM_DIR/inspection/"

    # Options
    mkdir -p "$PYCHARM_DIR/options"
    cp jetbrains/pycharm/config/options/*.xml "$PYCHARM_DIR/options/"
    if [[ -d "jetbrains/pycharm/config/options/mac" ]]; then
        mkdir -p "$PYCHARM_DIR/options/mac"
        cp jetbrains/pycharm/config/options/mac/* "$PYCHARM_DIR/options/mac/"
    fi

    # .ideavimrc
    cp jetbrains/pycharm/config/ideavimrc "$HOME/.ideavimrc"

    print_success "PyCharm configuration installed"
}

# Install serpl (terminal search and replace tool)
install_serpl() {
    print_step "Installing serpl..."
    
    if command -v serpl &> /dev/null; then
        print_success "serpl already installed"
        return
    fi
    
    # Check if Rust/Cargo is installed
    if ! command -v cargo &> /dev/null; then
        print_error "Rust and Cargo are required but not installed."
        print_info "Please install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        print_info "Or install via Homebrew: brew install rust"
        return 1
    fi
    
    print_info "Installing serpl with AST Grep support..."
    cargo install serpl --features ast_grep
    
    # Install ast-grep separately (required dependency)
    print_info "Installing ast-grep..."
    cargo install ast-grep
    
    print_success "serpl installed with AST Grep support"
}

# Final verification
verify_installation() {
    print_step "Verifying installation..."
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh: Installed"
    else
        print_error "Oh My Zsh: Not found"
    fi
    
    # Check Starship
    if command -v starship &> /dev/null; then
        print_success "Starship: Installed ($(starship --version))"
    else
        print_error "Starship: Not found"
    fi
    
    # Check Tmux
    if command -v tmux &> /dev/null; then
        print_success "Tmux: Installed ($(tmux -V))"
    else
        print_error "Tmux: Not found"
    fi
    
    # Check plugins
    plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions: Installed"
    else
        print_error "zsh-autosuggestions: Not found"
    fi
    
    if [[ -d "$plugins_dir/zsh-autocomplete" ]]; then
        print_success "zsh-autocomplete: Installed"
    else
        print_error "zsh-autocomplete: Not found"
    fi
    
    if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting: Installed"
    else
        print_error "zsh-syntax-highlighting: Not found"
    fi
    
    # Check configurations
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        print_success "Starship config: Applied"
    else
        print_error "Starship config: Not found"
    fi
    
    if [[ -f "$HOME/.tmux.conf.local" ]]; then
        print_success "Tmux config: Applied"
    else
        print_warning "Tmux config: Not found (optional)"
    fi
    
    # Check Ghostty
    if command -v ghostty &> /dev/null; then
        print_success "Ghostty: Installed"
    else
        print_error "Ghostty: Not found"
    fi

    GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
    if [[ -f "$GHOSTTY_DIR/config" ]]; then
        print_success "Ghostty config: Applied"
    else
        print_error "Ghostty config: Not found"
    fi

    # Check PyCharm config
    PYCHARM_DIR=$(find "$HOME/Library/Application Support/JetBrains" -maxdepth 1 -type d -name "PyCharm*" 2>/dev/null | sort -V | tail -1)
    if [[ -n "$PYCHARM_DIR" ]]; then
        print_success "PyCharm config: Applied ($PYCHARM_DIR)"
    else
        print_warning "PyCharm config: Skipped (not installed)"
    fi

    if [[ -f "$HOME/.ideavimrc" ]]; then
        print_success ".ideavimrc: Applied"
    else
        print_warning ".ideavimrc: Not found"
    fi

    if command -v zed &> /dev/null; then
        print_success "Zed: Installed"
    else
        print_error "Zed: Not found"
    fi

    if [[ -f "$HOME/.config/zed/settings.json" ]]; then
        print_success "Zed config: Applied"
    else
        print_error "Zed config: Not found"
    fi

    # Check serpl
    if command -v serpl &> /dev/null; then
        print_success "serpl: Installed ($(serpl --version))"
    else
        print_warning "serpl: Not found (requires Rust/Cargo)"
    fi
    
    # Check ast-grep
    if command -v ast-grep &> /dev/null; then
        print_success "ast-grep: Installed ($(ast-grep --version | head -1))"
    else
        print_warning "ast-grep: Not found (part of serpl installation)"
    fi
}

# Main installation function
main() {
    echo "🚀 Terminal Installation Script for macOS"
    echo "========================================"
    echo ""
    
    check_macos
    check_prerequisites
    install_oh_my_zsh
    install_zsh_plugins
    install_starship
    install_tmux
    copy_configurations
    install_nerd_font
    install_ghostty
    install_zed
    install_pycharm_config
    install_serpl
    set_default_shell
    verify_installation
    
    echo ""
    echo "🎉 Installation completed!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure your terminal to use 'FiraCode Nerd Font' for best experience"
    echo "3. Enjoy your enhanced terminal! 🚀"
    echo ""
    echo "Troubleshooting:"
    echo "- If symbols don't display correctly, ensure you're using a Nerd Font"
    echo "- If plugins don't work, restart your terminal completely"
    echo "- Check individual README files in each directory for detailed guides"
    echo ""
    echo "Additional tools installed:"
    echo "- serpl & ast-grep (terminal search & replace with AST support - requires Rust)"
    echo ""
    echo "Optional tools:"
    echo "- Run ./install-k8s-docker-tools.sh for Kubernetes & Docker tools (k9s, kubectx, helm, etc.)"
}

# Run main function
main "$@"
