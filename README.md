# NixOS Hyprland Configuration for Asahi Linux

My personal NixOS configuration featuring JaKooLit's Hyprland setup with Catppuccin theming, optimized for Asahi Linux (Apple Silicon).

## Features

- **Hyprland** - Wayland compositor with beautiful animations
- **Catppuccin Mocha** - Consistent theming across all applications
- **Asahi Linux optimizations** - Apple Silicon specific configurations
- **Home Manager** - Declarative user environment management
- **CrowdSec** - Security engine with firewall bouncer
- **Enhanced Security** - Firewall enabled with proper port management

## Applications with Catppuccin Theming

- Firefox, Kitty, Waybar, tmux, yazi
- btop, fzf, bat, zsh syntax highlighting
- System-wide theming (boot, console, cursors)

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/Chronicuser21/nixos-config.git /etc/nixos
   cd /etc/nixos
   ```

2. **Generate hardware configuration:**
   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/asahi/hardware-configuration.nix
   ```

3. **Build and switch:**
   ```bash
   sudo nixos-rebuild switch --flake .#asahi
   ```

## Security Setup

After installation, configure CrowdSec:
```bash
sudo cscli collections install crowdsecurity/linux
sudo cscli collections install crowdsecurity/sshd
sudo cscli bouncers add firewall-bouncer
```

## Structure

- `flake.nix` - Main flake configuration
- `hosts/asahi/` - Host-specific configuration
- `modules/` - Reusable NixOS modules
- `home/` - Home Manager configurations

## Hardware Requirements

- Apple Silicon Mac (M1/M2/M3)
- Asahi Linux installation
- NixOS with flakes enabled
