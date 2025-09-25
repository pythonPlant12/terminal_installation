#!/bin/bash

# Kubernetes and Docker Tools Installation Script
# Installs k9s, kubectx, kubens, helm and sets up useful aliases

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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "Detected macOS"
    elif [[ -f "/etc/debian_version" ]] || command -v apt &> /dev/null; then
        OS="ubuntu"
        print_info "Detected Ubuntu/Debian"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if running in correct directory
    if [[ ! -f "install-k8s-docker-tools.sh" ]]; then
        print_error "Please run this script from the terminal_installation directory"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        print_info "Ubuntu: sudo apt install docker.io"
        print_info "macOS: brew install --cask docker"
        DOCKER_MISSING=true
    else
        print_success "Docker found"
        DOCKER_MISSING=false
    fi
    
    # Check Kubernetes (kubectl)
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install Kubernetes CLI first."
        print_info "Ubuntu: sudo apt install kubectl"
        print_info "macOS: brew install kubectl"
        KUBECTL_MISSING=true
    else
        print_success "kubectl found"
        KUBECTL_MISSING=false
    fi
}

# Install k9s
install_k9s() {
    print_step "Installing k9s..."
    
    if command -v k9s &> /dev/null; then
        print_success "k9s already installed"
        return
    fi
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            print_info "Installing k9s via Homebrew..."
            brew install k9s
            print_success "k9s installed"
        else
            print_error "Homebrew not found. Please install Homebrew first."
            return 1
        fi
    elif [[ "$OS" == "ubuntu" ]]; then
        # Try snap first
        if command -v snap &> /dev/null; then
            print_info "Installing k9s via snap..."
            if sudo snap install k9s 2>/dev/null; then
                print_success "k9s installed via snap"
                return
            fi
        fi
        
        # Install from GitHub releases
        print_info "Installing k9s from GitHub releases..."
        K9S_VERSION=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        if [[ -n "$K9S_VERSION" ]]; then
            curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz"
            if [[ -f "k9s.tar.gz" ]]; then
                tar xf k9s.tar.gz k9s
                sudo install k9s /usr/local/bin
                rm k9s k9s.tar.gz
                print_success "k9s installed from GitHub"
            else
                print_warning "Could not install k9s automatically"
                return 1
            fi
        else
            print_warning "Could not determine latest k9s version"
            return 1
        fi
    fi
}

# Install kubectx and kubens
install_kubectx() {
    print_step "Installing kubectx and kubens..."
    
    if command -v kubectx &> /dev/null && command -v kubens &> /dev/null; then
        print_success "kubectx and kubens already installed"
        return
    fi
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            print_info "Installing kubectx via Homebrew..."
            brew install kubectx
            print_success "kubectx and kubens installed"
        else
            print_error "Homebrew not found"
            return 1
        fi
    elif [[ "$OS" == "ubuntu" ]]; then
        print_info "Installing kubectx and kubens from GitHub..."
        
        # Create temporary directory
        temp_dir=$(mktemp -d)
        
        # Download and install kubectx
        if ! command -v kubectx &> /dev/null; then
            curl -Lo "$temp_dir/kubectx" "https://github.com/ahmetb/kubectx/releases/latest/download/kubectx"
            chmod +x "$temp_dir/kubectx"
            sudo install "$temp_dir/kubectx" /usr/local/bin/
        fi
        
        # Download and install kubens
        if ! command -v kubens &> /dev/null; then
            curl -Lo "$temp_dir/kubens" "https://github.com/ahmetb/kubectx/releases/latest/download/kubens"
            chmod +x "$temp_dir/kubens"
            sudo install "$temp_dir/kubens" /usr/local/bin/
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
        print_success "kubectx and kubens installed"
    fi
}

# Install Helm
install_helm() {
    print_step "Installing Helm..."
    
    if command -v helm &> /dev/null; then
        print_success "Helm already installed"
        return
    fi
    
    if [[ "$OS" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            print_info "Installing Helm via Homebrew..."
            brew install helm
            print_success "Helm installed"
        else
            print_error "Homebrew not found"
            return 1
        fi
    elif [[ "$OS" == "ubuntu" ]]; then
        print_info "Installing Helm from official installer..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        print_success "Helm installed"
    fi
}

# Add aliases to user's .zshrc
add_aliases_to_zshrc() {
    print_step "Adding aliases to ~/.zshrc..."
    
    local zshrc_file="$HOME/.zshrc"
    
    # Backup existing .zshrc
    if [[ -f "$zshrc_file" ]]; then
        cp "$zshrc_file" "$zshrc_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing .zshrc"
    fi
    
    # Check if our aliases are already present
    if grep -q "# Kubernetes and Docker aliases and functions" "$zshrc_file" 2>/dev/null; then
        print_warning "Kubernetes and Docker aliases already present in .zshrc"
        return
    fi
    
    # Remove any existing individual Docker/Kubernetes aliases
    if [[ -f "$zshrc_file" ]]; then
        # Create temp file without the old aliases
        sed '/^# Docker and Kubernetes aliases$/,/^$/d' "$zshrc_file" | \
        sed '/^alias dk=/d' | \
        sed '/^alias k=/d' | \
        sed '/^alias kc=/d' | \
        sed '/^alias kn=/d' | \
        sed '/^dkpsip()/,/^}/d' > "$zshrc_file.tmp"
        mv "$zshrc_file.tmp" "$zshrc_file"
    fi
    
    # Add new aliases section
    cat >> "$zshrc_file" << 'EOF'

# Kubernetes and Docker aliases and functions
# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        return 1
    fi
    return 0
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Please install kubectl first."
        return 1
    fi
    return 0
}

# Docker aliases (with checks)
if command -v docker &> /dev/null; then
    alias dk='docker'
    
    # Docker container IP listing function
    dkpsip() {
        if ! check_docker; then return 1; fi
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | tail -n +2 | while read container_id container_name container_status; do
            if [[ $container_status == *"Up"* ]]; then
                ips=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$container_name" 2>/dev/null)
                echo "$container_id | $container_name | $ips"
            fi
        done
    }
else
    alias dk='echo "❌ Docker is not installed. Please install Docker first." && false'
    dkpsip() {
        echo "❌ Docker is not installed. Please install Docker first."
        return 1
    }
fi

# Kubernetes aliases (with checks)
if command -v kubectl &> /dev/null; then
    alias k='kubectl'
    
    # Additional useful kubectl aliases
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgd='kubectl get deployments'
    alias kgn='kubectl get nodes'
    alias kdp='kubectl describe pod'
    alias kds='kubectl describe service'
    alias kdd='kubectl describe deployment'
    alias kdn='kubectl describe node'
    alias klf='kubectl logs -f'
    alias kex='kubectl exec -it'
else
    alias k='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgp='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgs='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgd='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kgn='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdp='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kds='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdd='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kdn='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias klf='echo "❌ kubectl is not installed. Please install kubectl first." && false'
    alias kex='echo "❌ kubectl is not installed. Please install kubectl first." && false'
fi

# kubectx and kubens aliases (with checks)
if command -v kubectx &> /dev/null; then
    alias kc='kubectx'
else
    alias kc='echo "❌ kubectx is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

if command -v kubens &> /dev/null; then
    alias kn='kubens'
else
    alias kn='echo "❌ kubens is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

# k9s alias (with check)
if command -v k9s &> /dev/null; then
    alias k9='k9s'
else
    alias k9='echo "❌ k9s is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi

# Helm alias (with check)
if command -v helm &> /dev/null; then
    alias h='helm'
    alias hls='helm list'
    alias hin='helm install'
    alias hun='helm uninstall'
    alias hup='helm upgrade'
else
    alias h='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hls='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hin='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hun='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
    alias hup='echo "❌ Helm is not installed. Run install-k8s-docker-tools.sh to install." && false'
fi
EOF

    print_success "Aliases added to ~/.zshrc"
}

# Verification
verify_installation() {
    print_step "Verifying installation..."
    
    # Check k9s
    if command -v k9s &> /dev/null; then
        print_success "k9s: Installed ($(k9s version --short))"
    else
        print_warning "k9s: Not found"
    fi
    
    # Check kubectx
    if command -v kubectx &> /dev/null; then
        print_success "kubectx: Installed"
    else
        print_warning "kubectx: Not found"
    fi
    
    # Check kubens
    if command -v kubens &> /dev/null; then
        print_success "kubens: Installed"
    else
        print_warning "kubens: Not found"
    fi
    
    # Check helm
    if command -v helm &> /dev/null; then
        print_success "helm: Installed ($(helm version --short))"
    else
        print_warning "helm: Not found"
    fi
    
    # Check if aliases were added to .zshrc
    if grep -q "# Kubernetes and Docker aliases and functions" "$HOME/.zshrc" 2>/dev/null; then
        print_success "Aliases: Added to ~/.zshrc"
    else
        print_warning "Aliases: Not found in ~/.zshrc"
    fi
}

# Main installation function
main() {
    echo "🚀 Kubernetes & Docker Tools Installation Script"
    echo "==============================================="
    echo ""
    
    detect_os
    check_prerequisites
    
    # Only continue if we have the prerequisites or user wants to proceed anyway
    if [[ "$DOCKER_MISSING" == true ]] || [[ "$KUBECTL_MISSING" == true ]]; then
        print_warning "Some prerequisites are missing. Tools will be installed but aliases may not work until you install Docker/kubectl."
        echo ""
    fi
    
    install_k9s
    install_kubectx
    install_helm
    add_aliases_to_zshrc
    verify_installation
    
    echo ""
    echo "🎉 Installation completed!"
    echo ""
    echo "Installed tools:"
    echo "- k9s: Kubernetes cluster management TUI"
    echo "- kubectx: Switch between Kubernetes contexts"
    echo "- kubens: Switch between Kubernetes namespaces"  
    echo "- helm: Kubernetes package manager"
    echo ""
    echo "Available aliases:"
    echo "Docker:"
    echo "- dk: docker"
    echo "- dkpsip(): List container IPs"
    echo ""
    echo "Kubernetes:"
    echo "- k: kubectl"
    echo "- kc: kubectx (context switching)"
    echo "- kn: kubens (namespace switching)"
    echo "- k9: k9s (cluster TUI)"
    echo "- kgp, kgs, kgd, kgn: kubectl get (pods/services/deployments/nodes)"
    echo "- kdp, kds, kdd, kdn: kubectl describe"
    echo "- klf: kubectl logs -f"
    echo "- kex: kubectl exec -it"
    echo ""
    echo "Helm:"
    echo "- h: helm"
    echo "- hls: helm list"
    echo "- hin: helm install"
    echo "- hun: helm uninstall"
    echo "- hup: helm upgrade"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. If Docker/kubectl were missing, install them and restart your terminal"
    echo "3. Enjoy your enhanced Kubernetes and Docker workflow! 🚀"
    echo ""
}

# Run main function
main "$@"