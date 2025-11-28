#!/usr/bin/env bash

# NixOS Configuration Manager for Asahi Linux
# Manages NixOS system and home-manager configurations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_DIR="/home/$(whoami)/nixos-config"
HM_CONFIG_DIR="/home/$(whoami)/.config/home-manager"

print_msg() { echo -e "${GREEN}[*]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

check_nixos() {
    if ! command -v nixos-rebuild &> /dev/null; then
        print_error "This script requires NixOS"
        exit 1
    fi
}

backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$CONFIG_DIR/backups/$timestamp"
    
    print_msg "Creating backup at $backup_dir"
    mkdir -p "$backup_dir"
    
    [ -f /etc/nixos/configuration.nix ] && cp /etc/nixos/configuration.nix "$backup_dir/"
    [ -f /etc/nixos/hardware-configuration.nix ] && cp /etc/nixos/hardware-configuration.nix "$backup_dir/"
    [ -f "$HM_CONFIG_DIR/home.nix" ] && cp "$HM_CONFIG_DIR/home.nix" "$backup_dir/"
    [ -f "$HM_CONFIG_DIR/flake.nix" ] && cp "$HM_CONFIG_DIR/flake.nix" "$backup_dir/"
    
    print_info "Backup created successfully"
}

rebuild_system() {
    print_msg "Rebuilding NixOS system configuration..."
    sudo nixos-rebuild switch
}

rebuild_home() {
    print_msg "Rebuilding home-manager configuration..."
    cd "$HM_CONFIG_DIR" && home-manager switch --flake .
}

update_system() {
    print_msg "Updating NixOS channels..."
    sudo nix-channel --update
    rebuild_system
}

update_home() {
    print_msg "Updating home-manager..."
    cd "$HM_CONFIG_DIR"
    nix flake update
    rebuild_home
}

cleanup_system() {
    print_msg "Cleaning up old generations..."
    sudo nix-collect-garbage -d
    nix-collect-garbage -d
}

show_status() {
    print_info "=== System Status ==="
    echo "NixOS Version: $(nixos-version)"
    echo "Current Generation: $(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1)"
    echo "Home Manager: $(home-manager --version 2>/dev/null || echo 'Not available')"
    echo ""
    
    print_info "=== Disk Usage ==="
    df -h / | tail -1
    echo "Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1)"
    echo ""
}

interactive_menu() {
    while true; do
        clear
        echo -e "${BLUE}NixOS Configuration Manager${NC}"
        echo "=========================="
        echo "1) Rebuild system configuration"
        echo "2) Rebuild home-manager configuration"
        echo "3) Update system"
        echo "4) Update home-manager"
        echo "5) Backup configurations"
        echo "6) Cleanup old generations"
        echo "7) Show system status"
        echo "8) Exit"
        echo ""
        read -p "Select option [1-8]: " choice
        
        case $choice in
            1) rebuild_system; read -p "Press Enter to continue..." ;;
            2) rebuild_home; read -p "Press Enter to continue..." ;;
            3) update_system; read -p "Press Enter to continue..." ;;
            4) update_home; read -p "Press Enter to continue..." ;;
            5) backup_config; read -p "Press Enter to continue..." ;;
            6) cleanup_system; read -p "Press Enter to continue..." ;;
            7) show_status; read -p "Press Enter to continue..." ;;
            8) exit 0 ;;
            *) print_error "Invalid option" ;;
        esac
    done
}

main() {
    check_nixos
    
    case "${1:-}" in
        "rebuild"|"switch") rebuild_system ;;
        "home") rebuild_home ;;
        "update") update_system ;;
        "update-home") update_home ;;
        "backup") backup_config ;;
        "cleanup") cleanup_system ;;
        "status") show_status ;;
        "menu"|"") interactive_menu ;;
        *)
            echo "Usage: $0 [rebuild|home|update|update-home|backup|cleanup|status|menu]"
            echo ""
            echo "Commands:"
            echo "  rebuild     - Rebuild NixOS system"
            echo "  home        - Rebuild home-manager"
            echo "  update      - Update system"
            echo "  update-home - Update home-manager"
            echo "  backup      - Backup configurations"
            echo "  cleanup     - Clean old generations"
            echo "  status      - Show system status"
            echo "  menu        - Interactive menu (default)"
            ;;
    esac
}

main "$@"
