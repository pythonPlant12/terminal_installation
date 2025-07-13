#!/bin/bash

# Universal Terminal Installation Script
# Automatically detects OS and runs appropriate installation script

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

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if it's Ubuntu/Debian
        if command -v apt &> /dev/null; then
            echo "ubuntu"
        # Check if it's CentOS/RHEL/Fedora
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
            echo "redhat"
        # Check if it's Arch
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Display system information
show_system_info() {
    local os_type=$(detect_os)
    
    echo "🖥️  System Information"
    echo "===================="
    echo "OS Type: $OSTYPE"
    echo "Detected: $os_type"
    echo "Shell: $SHELL"
    
    if command -v uname &> /dev/null; then
        echo "Kernel: $(uname -sr)"
    fi
    
    echo ""
}

# Main function
main() {
    echo "🚀 Universal Terminal Installation Script"
    echo "========================================"
    echo ""
    
    show_system_info
    
    local os_type=$(detect_os)
    
    case $os_type in
        "macos")
            print_info "macOS detected - using macOS installation script"
            if [[ -f "install-macos.sh" ]]; then
                chmod +x install-macos.sh
                ./install-macos.sh "$@"
            else
                print_error "install-macos.sh not found in current directory"
                exit 1
            fi
            ;;
        "ubuntu")
            print_info "Ubuntu/Debian detected - using Ubuntu installation script"
            if [[ -f "install-ubuntu.sh" ]]; then
                chmod +x install-ubuntu.sh
                ./install-ubuntu.sh "$@"
            else
                print_error "install-ubuntu.sh not found in current directory"
                exit 1
            fi
            ;;
        "redhat")
            print_warning "Red Hat/CentOS/Fedora detected"
            print_info "This system is not fully supported yet, but you can try the Ubuntu script:"
            print_info "1. Install zsh, git, curl manually using yum/dnf"
            print_info "2. Run: ./install-ubuntu.sh"
            print_info "3. You may need to adapt package names for your distribution"
            exit 1
            ;;
        "arch")
            print_warning "Arch Linux detected"
            print_info "This system is not fully supported yet, but you can try:"
            print_info "1. Install base packages: sudo pacman -S zsh git curl"
            print_info "2. Run: ./install-ubuntu.sh (with manual adaptations)"
            exit 1
            ;;
        "windows")
            print_warning "Windows detected"
            print_info "For Windows, please use Windows Subsystem for Linux (WSL):"
            print_info "1. Install WSL2 with Ubuntu"
            print_info "2. Run this script inside WSL"
            print_info "3. Or use Windows Terminal with PowerShell and install components manually"
            exit 1
            ;;
        "linux")
            print_warning "Generic Linux detected"
            print_info "Your Linux distribution is not specifically supported."
            print_info "You can try the Ubuntu script, but may need to adapt package commands:"
            echo ""
            echo "Available scripts:"
            echo "- ./install-ubuntu.sh (for Debian/Ubuntu-based systems)"
            echo ""
            echo "Manual installation:"
            echo "1. Install: zsh, git, curl, build-essential"
            echo "2. Follow individual README files in each directory"
            exit 1
            ;;
        *)
            print_error "Unsupported operating system: $OSTYPE"
            print_info "Supported systems:"
            print_info "- macOS (install-macos.sh)"
            print_info "- Ubuntu/Debian (install-ubuntu.sh)"
            print_info ""
            print_info "For manual installation, check the README files in each directory."
            exit 1
            ;;
    esac
}

# Show usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --detect       Only detect OS and exit"
    echo "  --macos        Force macOS installation"
    echo "  --ubuntu       Force Ubuntu installation"
    echo ""
    echo "This script automatically detects your operating system and runs"
    echo "the appropriate installation script for your platform."
    echo ""
    echo "Supported platforms:"
    echo "  ✅ macOS (via install-macos.sh)"
    echo "  ✅ Ubuntu/Debian (via install-ubuntu.sh)"
    echo "  ⚠️  Other Linux distributions (manual adaptation required)"
    echo "  ⚠️  Windows (use WSL)"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --detect)
        echo "Detected OS: $(detect_os)"
        exit 0
        ;;
    --macos)
        print_info "Forcing macOS installation..."
        if [[ -f "install-macos.sh" ]]; then
            chmod +x install-macos.sh
            ./install-macos.sh "${@:2}"
        else
            print_error "install-macos.sh not found"
            exit 1
        fi
        ;;
    --ubuntu)
        print_info "Forcing Ubuntu installation..."
        if [[ -f "install-ubuntu.sh" ]]; then
            chmod +x install-ubuntu.sh
            ./install-ubuntu.sh "${@:2}"
        else
            print_error "install-ubuntu.sh not found"
            exit 1
        fi
        ;;
    *)
        main "$@"
        ;;
esac