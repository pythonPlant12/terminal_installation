#!/bin/bash

# Terminal Installation Script for Ubuntu
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

# Check if running on Ubuntu/Debian
check_ubuntu() {
    if ! command -v apt &> /dev/null; then
        print_error "This script is for Ubuntu/Debian systems. Use install-macos.sh for macOS."
        exit 1
    fi
    print_success "Running on Ubuntu/Debian system"
}

# Check prerequisites and install required packages
check_prerequisites() {
    print_step "Checking prerequisites and updating system..."
    
    # Check if running in correct directory
    if [[ ! -f "install-ubuntu.sh" ]]; then
        print_error "Please run this script from the terminal_installation directory"
        exit 1
    fi
    
    # Update package list
    print_info "Updating package list..."
    if ! sudo apt update 2>/dev/null; then
        print_warning "Package update failed. Trying to fix repository issues..."
        # Remove problematic lazygit PPA if it exists
        if sudo add-apt-repository --remove ppa:lazygit-team/release -y 2>/dev/null; then
            print_info "Removed problematic lazygit PPA repository"
        fi
        sudo apt update
    fi
    
    # Install required packages
    required_packages=(
        "zsh"
        "git" 
        "curl"
        "wget"
        "build-essential"
        "fontconfig"
    )
    
    print_info "Installing required packages..."
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_info "Installing $package..."
            sudo apt install -y "$package"
        else
            print_success "$package already installed"
        fi
    done
    
    print_success "Prerequisites installed"
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
        
        # Try package manager first, then git clone
        if apt list --installed 2>/dev/null | grep -q zsh-autosuggestions; then
            print_info "zsh-autosuggestions available via apt, but installing from git for consistency..."
        fi
        
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_warning "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        print_info "Installing zsh-syntax-highlighting..."
        
        # Try package manager first, then git clone
        if apt list --installed 2>/dev/null | grep -q zsh-syntax-highlighting; then
            print_info "zsh-syntax-highlighting available via apt, but installing from git for consistency..."
        fi
        
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
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "Starship installed"
}

# Install Tmux and Oh My Tmux
install_tmux() {
    print_step "Installing Tmux and Oh My Tmux..."
    
    # Install tmux via apt
    if ! command -v tmux &> /dev/null; then
        print_info "Installing tmux via apt..."
        sudo apt install -y tmux
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

# Install Nerd Font
install_nerd_font() {
    print_step "Installing Nerd Font (FiraCode)..."
    
    # Create fonts directory
    mkdir -p ~/.local/share/fonts
    
    # Check if FiraCode Nerd Font is already installed
    if fc-list | grep -i "firacode.*nerd" &> /dev/null; then
        print_warning "FiraCode Nerd Font already installed"
        return
    fi
    
    print_info "Downloading FiraCode Nerd Font..."
    
    # Download FiraCode Nerd Font
    font_version="v3.0.2"
    font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/FiraCode.zip"
    temp_dir=$(mktemp -d)
    
    curl -L "$font_url" -o "$temp_dir/FiraCode.zip"
    
    if [[ -f "$temp_dir/FiraCode.zip" ]]; then
        print_info "Extracting and installing font..."
        unzip -q "$temp_dir/FiraCode.zip" -d "$temp_dir"
        
        # Copy TTF files to fonts directory
        find "$temp_dir" -name "*.ttf" -exec cp {} ~/.local/share/fonts/ \;
        
        # Update font cache
        fc-cache -fv ~/.local/share/fonts/
        
        # Cleanup
        rm -rf "$temp_dir"
        
        print_success "FiraCode Nerd Font installed"
        print_warning "Please configure your terminal to use 'FiraCode Nerd Font'"
    else
        print_error "Failed to download FiraCode Nerd Font"
        print_info "You can manually download it from: https://github.com/ryanoasis/nerd-fonts"
    fi
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

# Install additional useful packages
install_additional_packages() {
    print_step "Installing additional useful packages..."
    
    additional_packages=(
        "tree"          # Directory tree viewer
        "htop"          # Process viewer
        "neofetch"      # System information
        "unzip"         # Archive extraction
        "zip"           # Archive creation
        "xclip"         # Clipboard utility
        "ripgrep"       # Fast grep alternative
        "fd-find"       # Fast find alternative
        "bat"           # Cat with syntax highlighting
        "exa"           # Modern ls replacement
    )
    
    for package in "${additional_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_info "Installing $package..."
            sudo apt install -y "$package" 2>/dev/null || print_warning "Could not install $package (might not be available)"
        fi
    done
    
    print_success "Additional packages installed"
}

# Install lazygit
install_lazygit() {
    print_step "Installing lazygit..."
    
    if command -v lazygit &> /dev/null; then
        print_success "lazygit already installed"
        return
    fi
    
    # Try installing via snap first (most reliable)
    if command -v snap &> /dev/null; then
        print_info "Installing lazygit via snap..."
        if sudo snap install lazygit 2>/dev/null; then
            print_success "lazygit installed via snap"
            return
        fi
    fi
    
    # Try downloading latest release from GitHub
    print_info "Installing lazygit from GitHub releases..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [[ -n "$LAZYGIT_VERSION" ]]; then
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        if [[ -f "lazygit.tar.gz" ]]; then
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
            print_success "lazygit installed from GitHub"
        else
            print_warning "Could not install lazygit automatically. Install manually if needed."
        fi
    else
        print_warning "Could not determine latest lazygit version"
    fi
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
    
    # Check font installation
    if fc-list | grep -i "firacode.*nerd" &> /dev/null; then
        print_success "FiraCode Nerd Font: Installed"
    else
        print_warning "FiraCode Nerd Font: Not found (install manually if needed)"
    fi
    
    # Check lazygit
    if command -v lazygit &> /dev/null; then
        print_success "lazygit: Installed ($(lazygit --version | head -1))"
    else
        print_warning "lazygit: Not found (install manually if needed)"
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
    echo "🚀 Terminal Installation Script for Ubuntu"
    echo "========================================="
    echo ""
    
    check_ubuntu
    check_prerequisites
    install_oh_my_zsh
    install_zsh_plugins
    install_starship
    install_tmux
    install_nerd_font
    install_additional_packages
    install_lazygit
    install_serpl
    copy_configurations
    set_default_shell
    verify_installation
    
    echo ""
    echo "🎉 Installation completed!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure your terminal to use 'FiraCode Nerd Font' for best experience"
    echo "3. Log out and log back in to apply the shell change"
    echo "4. Enjoy your enhanced terminal! 🚀"
    echo ""
    echo "Troubleshooting:"
    echo "- If symbols don't display correctly, ensure you're using a Nerd Font"
    echo "- If plugins don't work, restart your terminal completely"
    echo "- If clipboard doesn't work, make sure xclip is installed"
    echo "- Check individual README files in each directory for detailed guides"
    echo ""
    echo "Additional tools installed:"
    echo "- tree, htop, neofetch, ripgrep, fd-find, bat, exa (if available)"
    echo "- lazygit (Git TUI)"
    echo "- serpl & ast-grep (terminal search & replace with AST support - requires Rust)"
    echo ""
    echo "Optional tools:"
    echo "- Run ./install-k8s-docker-tools.sh for Kubernetes & Docker tools (k9s, kubectx, helm, etc.)"
}

# Run main function
main "$@"