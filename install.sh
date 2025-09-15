#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}JaKooLit's NixOS-Hyprland Setup for Asahi Linux${NC}"
echo -e "${BLUE}================================================${NC}"

# Check if running on Asahi Linux
if [[ $(uname -m) != "aarch64" ]]; then
    echo -e "${RED}Error: This configuration is designed for Asahi Linux (aarch64)${NC}"
    exit 1
fi

# Check if NixOS
if [[ ! -f /etc/NIXOS ]]; then
    echo -e "${RED}Error: This script is designed for NixOS${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Updating hardware configuration...${NC}"
# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/asahi/hardware-configuration.nix

echo -e "${YELLOW}Step 2: Creating flake.lock...${NC}"
cd /etc/nixos && sudo nix flake update

echo -e "${YELLOW}Step 3: Building and switching to new configuration...${NC}"
sudo nixos-rebuild switch --flake /etc/nixos#asahi

echo -e "${YELLOW}Step 4: Setting up user configuration...${NC}"
# Ensure home-manager is available
nix run home-manager/master -- switch --flake /etc/nixos#b

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}Please reboot to ensure all changes take effect.${NC}"
echo -e "${BLUE}After reboot, you can log in and start Hyprland.${NC}"

echo -e "\n${YELLOW}Post-installation notes:${NC}"
echo -e "- Edit home/b.nix to customize your user configuration"
echo -e "- Edit hosts/asahi/configuration.nix for system-wide changes"
echo -e "- Run 'rebuild' alias to apply changes after modifications"
echo -e "- Hyprland keybindings: SUPER+Q (terminal), SUPER+R (launcher), SUPER+E (file manager)"
