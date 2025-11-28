#!/bin/bash

# Void Linux Installer for Asahi M1 Mac - Optimized
# Follows official Asahi Void installation guide

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MOUNT_DIR="/mnt"
USE_LUKS="no"
ROOT_DEVICE=""

print_msg() { echo -e "${GREEN}[*]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_root() {
  if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root"
    exit 1
  fi
}

check_asahi() {
  if [ "$(uname -m)" != "aarch64" ]; then
    print_error "This script is for ARM64 (aarch64) architecture only"
    exit 1
  fi
  
  if ! lsblk | grep -q "nvme"; then
    print_error "No NVMe device found. Ensure you're running on Apple Silicon Mac"
    exit 1
  fi
}

cleanup_on_error() {
  print_error "Installation failed. Cleaning up..."
  [ -n "$LUKS_OPEN" ] && [ "$USE_LUKS" = "yes" ] && cryptsetup close void_root 2>/dev/null || true
  umount -R "$MOUNT_DIR" 2>/dev/null || true
  exit 1
}

trap cleanup_on_error ERR

select_partition() {
  local title="$1"
  local partitions=()

  print_msg "Available partitions:"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "(nvme|disk|part)"
  
  while IFS= read -r line; do
    local name size
    name=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')

    if [[ "$name" =~ ^nvme.*p[0-9]+$ ]] && [[ ! "$name" =~ p1$ ]]; then
      partitions+=("$name" "$size")
    fi
  done < <(lsblk -ln -o NAME,SIZE,TYPE | grep "part")

  if [ ${#partitions[@]} -eq 0 ]; then
    print_error "No suitable partitions found! Use Asahi installer first."
    exit 1
  fi

  echo
  echo "Available partitions for $title:"
  for ((i=0; i<${#partitions[@]}; i+=2)); do
    echo "$((i/2+1)). ${partitions[i]} (${partitions[i+1]})"
  done
  
  read -r -p "Select partition number: " choice
  local idx=$(((choice-1)*2))
  echo "${partitions[idx]}"
}

get_input() {
  local prompt="$1" default="$2"
  read -r -p "$prompt [$default]: " input
  echo "${input:-$default}"
}

get_password() {
  local prompt="$1"
  read -r -s -p "$prompt: " pass1
  echo
  read -r -s -p "Confirm password: " pass2
  echo
  while [ "$pass1" != "$pass2" ]; do
    print_error "Passwords do not match!"
    read -r -s -p "$prompt: " pass1
    echo
    read -r -s -p "Confirm password: " pass2
    echo
  done
  echo "$pass1"
}

main_setup() {
  print_msg "Void Linux Installer for Asahi M1 Mac"
  print_warn "This installer follows the official Asahi Void installation guide"
  print_warn "Ensure you have run Asahi installer first and have free space"
  echo
  
  # Find Asahi EFI partition
  EFI_PART=$(lsblk -o NAME,PARTTYPE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print $1}' | head -n1 | sed 's/[├─└│]//g' | tr -d ' ')
  if [ -z "$EFI_PART" ]; then
    print_error "Asahi EFI partition not found! Run Asahi installer first."
    exit 1
  fi
  print_msg "Found Asahi EFI partition: /dev/$EFI_PART"

  ROOT_PART=$(select_partition "Root partition (free space from Asahi)")
  [ -z "$ROOT_PART" ] && exit 1

  read -r -p "Use LUKS encryption? (y/N): " luks_choice
  [ "$luks_choice" = "y" ] || [ "$luks_choice" = "Y" ] && USE_LUKS="yes"

  HOSTNAME=$(get_input "Hostname" "void-asahi")
  USERNAME=$(get_input "Username" "user")
  
  USER_PASS=$(get_password "User password")
  ROOT_PASS=$(get_password "Root password")
  
  if [ "$USE_LUKS" = "yes" ]; then
    LUKS_PASS=$(get_password "LUKS passphrase")
  fi

  LOCALE=$(get_input "Locale" "en_US.UTF-8")
  TIMEZONE=$(get_input "Timezone" "UTC")

  echo
  print_msg "Installation Summary:"
  echo "Root: /dev/$ROOT_PART"
  echo "EFI: /dev/$EFI_PART (Asahi)"
  echo "LUKS: $USE_LUKS"
  echo "Hostname: $HOSTNAME"
  echo "Username: $USERNAME"
  echo
  read -r -p "Continue? (y/N): " confirm
  [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && exit 0
}

install_system() {
  print_msg "Starting installation..."

  # Setup LUKS if requested
  if [ "$USE_LUKS" = "yes" ]; then
    print_msg "Setting up LUKS encryption..."
    echo -n "$LUKS_PASS" | cryptsetup luksFormat --type luks2 "/dev/$ROOT_PART" -
    echo -n "$LUKS_PASS" | cryptsetup open "/dev/$ROOT_PART" void_root -
    ROOT_DEVICE="/dev/mapper/void_root"
    LUKS_OPEN="yes"
  else
    ROOT_DEVICE="/dev/$ROOT_PART"
  fi

  # Format root partition
  print_msg "Formatting root partition..."
  mkfs.ext4 -F "$ROOT_DEVICE"

  # Mount partitions following Asahi guide
  print_msg "Mounting partitions..."
  mkdir -p "$MOUNT_DIR"
  mount "$ROOT_DEVICE" "$MOUNT_DIR"
  mkdir -p "$MOUNT_DIR/boot/efi"
  mount "/dev/$EFI_PART" "$MOUNT_DIR/boot/efi"

  # Download and extract base system
  print_msg "Downloading Void Linux base system..."
  cd /tmp
  if [ ! -f void-aarch64-ROOTFS.tar.xz ]; then
    wget -O void-aarch64-ROOTFS.tar.xz "https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS-$(date +%Y%m%d).tar.xz" || \
    wget -O void-aarch64-ROOTFS.tar.xz "https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS-20240314.tar.xz"
  fi

  print_msg "Extracting base system..."
  tar xf void-aarch64-ROOTFS.tar.xz -C "$MOUNT_DIR"

  # Prepare chroot
  print_msg "Preparing chroot environment..."
  mount --rbind /sys "$MOUNT_DIR/sys" && mount --make-rslave "$MOUNT_DIR/sys"
  mount --rbind /dev "$MOUNT_DIR/dev" && mount --make-rslave "$MOUNT_DIR/dev"
  mount --rbind /proc "$MOUNT_DIR/proc" && mount --make-rslave "$MOUNT_DIR/proc"
  cp /etc/resolv.conf "$MOUNT_DIR/etc/"

  # Install base system and Asahi packages (following official guide)
  print_msg "Installing base-system and asahi-base..."
  cat << 'CHROOT_EOF' > "$MOUNT_DIR/tmp/install.sh"
#!/bin/bash
set -e
xbps-install -Syu xbps
xbps-install -Syu
xbps-install -y base-system asahi-base
xbps-install -y cryptsetup grub-arm64-efi
xbps-install -y NetworkManager dhcpcd
ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
CHROOT_EOF

  chmod +x "$MOUNT_DIR/tmp/install.sh"
  xchroot "$MOUNT_DIR" /tmp/install.sh

  # Configure system
  print_msg "Configuring system..."
  echo "$HOSTNAME" > "$MOUNT_DIR/etc/hostname"
  
  cat > "$MOUNT_DIR/etc/hosts" << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

  echo "LANG=$LOCALE" > "$MOUNT_DIR/etc/locale.conf"
  echo "$LOCALE UTF-8" >> "$MOUNT_DIR/etc/default/libc-locales"
  xchroot "$MOUNT_DIR" xbps-reconfigure -f glibc-locales
  xchroot "$MOUNT_DIR" ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

  # Setup LUKS in system if used
  if [ "$USE_LUKS" = "yes" ]; then
    ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    echo "void_root UUID=$ROOT_UUID none luks" > "$MOUNT_DIR/etc/crypttab"
    
    # Configure GRUB for LUKS
    LUKS_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$LUKS_UUID:void_root /" "$MOUNT_DIR/etc/default/grub"
    echo "GRUB_ENABLE_CRYPTODISK=y" >> "$MOUNT_DIR/etc/default/grub"
    
    # Configure dracut for LUKS
    mkdir -p "$MOUNT_DIR/etc/dracut.conf.d"
    echo 'add_dracutmodules+=" crypt dm "' > "$MOUNT_DIR/etc/dracut.conf.d/10-crypt.conf"
  fi

  # Setup fstab
  if [ "$USE_LUKS" = "yes" ]; then
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
  else
    ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
  fi
  EFI_UUID=$(blkid -s UUID -o value "/dev/$EFI_PART")

  cat > "$MOUNT_DIR/etc/fstab" << EOF
UUID=$ROOT_UUID / ext4 defaults 0 1
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF

  # Create users and set passwords
  print_msg "Setting up users..."
  echo "root:$ROOT_PASS" | xchroot "$MOUNT_DIR" chpasswd
  xchroot "$MOUNT_DIR" useradd -m -G wheel,audio,video,optical,storage "$USERNAME"
  echo "$USERNAME:$USER_PASS" | xchroot "$MOUNT_DIR" chpasswd
  xchroot "$MOUNT_DIR" xbps-install -y sudo
  echo "%wheel ALL=(ALL) ALL" >> "$MOUNT_DIR/etc/sudoers"

  # Install and configure bootloader (following Asahi guide)
  print_msg "Installing GRUB bootloader..."
  [ "$USE_LUKS" = "yes" ] && xchroot "$MOUNT_DIR" dracut --force --hostonly
  
  # Use --removable flag as per Asahi guide
  xchroot "$MOUNT_DIR" grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=void --removable
  xchroot "$MOUNT_DIR" grub-mkconfig -o /boot/grub/grub.cfg

  # Final reconfiguration
  print_msg "Finalizing installation..."
  xchroot "$MOUNT_DIR" xbps-reconfigure -fa
  rm -f "$MOUNT_DIR/tmp/install.sh"

  # Cleanup
  umount -R "$MOUNT_DIR"
  if [ "$USE_LUKS" = "yes" ]; then
    cryptsetup close void_root
  fi

  print_msg "Installation completed successfully!"
  print_warn "IMPORTANT: Run 'sudo update-m1n1' to update Asahi boot environment"
  print_msg "You can now reboot into Void Linux"
}

# Main execution
clear
check_root
check_asahi
main_setup
install_system
