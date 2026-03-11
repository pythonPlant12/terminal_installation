#!/bin/bash

# Apply Zed Configuration Script
# Copies Zed settings, keymap, tasks, and theme to ~/.config/zed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running in correct directory
check_directory() {
    if [[ ! -f "apply_zed_config.sh" ]]; then
        print_error "Please run this script from the terminal_installation directory"
        exit 1
    fi

    if [[ ! -d "zed" ]]; then
        print_error "zed/ directory not found. Are you in the right place?"
        exit 1
    fi
}

# Backup existing Zed config
backup_existing() {
    local backup_dir="$HOME/.zed_config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    local backed_up=false

    for file in settings.json keymap.json tasks.json; do
        if [[ -f "$HOME/.config/zed/$file" ]]; then
            cp "$HOME/.config/zed/$file" "$backup_dir/$file"
            backed_up=true
        fi
    done

    if [[ -f "$HOME/.config/zed/themes/islands-dark.json" ]]; then
        cp "$HOME/.config/zed/themes/islands-dark.json" "$backup_dir/islands-dark.json"
        backed_up=true
    fi

    if [[ "$backed_up" == true ]]; then
        print_info "Existing config backed up to $backup_dir"
    fi
}

# Apply Zed configuration files
apply_config() {
    print_step "Applying Zed configuration..."

    mkdir -p "$HOME/.config/zed/themes"

    cp "zed/settings.json" "$HOME/.config/zed/settings.json"
    print_success "settings.json applied"

    cp "zed/keymap.json" "$HOME/.config/zed/keymap.json"
    print_success "keymap.json applied"

    cp "zed/tasks.json" "$HOME/.config/zed/tasks.json"
    print_success "tasks.json applied"

    cp "zed/themes/islands-dark.json" "$HOME/.config/zed/themes/islands-dark.json"
    print_success "themes/islands-dark.json applied"
}

# Verify the result
verify() {
    print_step "Verifying..."

    local all_ok=true

    for file in settings.json keymap.json tasks.json; do
        if [[ -f "$HOME/.config/zed/$file" ]]; then
            print_success "$file: present"
        else
            print_error "$file: missing"
            all_ok=false
        fi
    done

    if [[ -f "$HOME/.config/zed/themes/islands-dark.json" ]]; then
        print_success "themes/islands-dark.json: present"
    else
        print_error "themes/islands-dark.json: missing"
        all_ok=false
    fi

    if [[ "$all_ok" == true ]]; then
        print_success "All Zed config files applied successfully"
    else
        print_error "Some files are missing — check the output above"
        exit 1
    fi
}

main() {
    echo "⌨️  Apply Zed Configuration"
    echo "==========================="
    echo ""

    check_directory
    backup_existing
    apply_config
    verify

    echo ""
    print_success "Done! Restart Zed for changes to take effect."
    echo ""
    print_warning "Remember to install these Zed extensions manually (cmd-shift-p → 'zed: extensions'):"
    echo "  - Groovy"
    echo "  - Bookmark language server"
    echo ""
}

main "$@"
