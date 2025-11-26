#!/bin/bash

# Void Linux Installer for M1 Mac (Asahi Linux)
# With LUKS Encryption Support and TUI Interface
# This script assumes you’ve already partitioned your drive using macOS Disk Utility
# and are running from an Asahi Linux live environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
MOUNT_DIR="/mnt"
LUKS_OPEN=""
ROOT_DEVICE=""
HOME_DEVICE=""
USE_LUKS="no"
ENCRYPT_HOME="no"
SEPARATE_HOME="no"
INSTALL_DE="no"
SELECTED_DE=""

# Functions

print_msg() {
  echo -e "${GREEN}[*]${NC} $1"
}

print_warn() {
  echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
  if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
  fi
}

check_architecture() {
  if [ "$(uname -m)" != "aarch64" ]; then
    print_error "This script is for ARM64 (aarch64) architecture only"
    exit 1
  fi
}

check_dependencies() {
  local missing_deps=()

  for dep in dialog cryptsetup wget tar xchroot; do
    if ! command -v "$dep" &> /dev/null; then
      missing_deps+=("$dep")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    print_msg "Installing missing dependencies: ${missing_deps[*]}"
    xbps-install -Sy "${missing_deps[@]}" || {
      print_error "Failed to install dependencies"
      exit 1
    }
  fi
}

cleanup_on_error() {
  print_error "Installation failed. Cleaning up..."
  if [ -n "$LUKS_OPEN" ] && [ "$USE_LUKS" = "yes" ]; then
    cryptsetup close void_root 2>/dev/null || true
    [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close void_home 2>/dev/null || true
  fi
  umount -R "$MOUNT_DIR" 2>/dev/null || true
  exit 1
}

trap cleanup_on_error ERR

# Dialog functions

show_welcome() {
  dialog --title "Void Linux Installer for M1 Mac" \
    --msgbox "Welcome to the Void Linux installer for Apple Silicon Macs!\n\n\
This installer will help you install Void Linux with:\n\
• Full LUKS encryption support\n\
• Asahi Linux kernel and drivers\n\
• Desktop environment options\n\
• M1/M2 optimized packages\n\n\
Prerequisites:\n\
• Partitioned disk via macOS Disk Utility\n\
• Active internet connection\n\
• Running from Asahi Linux live environment" 20 70
}

select_partition() {
  local title="$1"
  local partitions=()

  while IFS= read -r line; do
    local name=$(echo "$line" | awk '{print $1}')
    local size=$(echo "$line" | awk '{print $2}')
    local type=$(echo "$line" | awk '{print $3}')
    if [[ "$name" =~ ^nvme.*p[0-9]+$ ]] || [[ "$name" =~ ^sd[a-z][0-9]+
