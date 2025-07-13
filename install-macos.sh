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
}

# Run main function
main "$@"