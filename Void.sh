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

  for dep in dialog cryptsetup wget tar xchroot xbps-install grub-install; do
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
  umount_virtuals
  if [ -n "$LUKS_OPEN" ] && [ "$USE_LUKS" = "yes" ]; then
    cryptsetup close void_root 2>/dev/null || true
    [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close void_home 2>/dev/null || true
  fi
  umount_root
  exit 1
}

umount_virtuals() {
  # Unmount virtual filesystems in correct order
  umount -l "$MOUNT_DIR/proc" 2>/dev/null || true
  umount -l "$MOUNT_DIR/sys" 2>/dev/null || true
  umount -l "$MOUNT_DIR/dev" 2>/dev/null || true
  umount -l "$MOUNT_DIR/run" 2>/dev/null || true
}

umount_root() {
  umount -l -R "$MOUNT_DIR" 2>/dev/null || true
}

trap cleanup_on_error ERR

# Dialog functions (omitted unchanged for brevity)...

# Modified select_partition with mmcblk inclusion
select_partition() {
  local title="$1"
  local partitions=()

  while IFS= read -r line; do
    local name=$(echo "$line" | awk '{print $1}')
    local size=$(echo "$line" | awk '{print $2}')
    local type=$(echo "$line" | awk '{print $3}')
    if [[ "$name" =~ ^nvme.*p[0-9]+$ ]] || [[ "$name" =~ ^sd[a-z][0-9]+$ ]] || [[ "$name" =~ ^mmcblk[0-9]+p[0-9]+$ ]]; then
      partitions+=("$name" "$size $type")
    fi
  done < <(lsblk -ln -o NAME,SIZE,TYPE | grep -E "part|disk")

  if [ ${#partitions[@]} -eq 0 ]; then
    dialog --title "Error" --msgbox "No partitions found!" 7 40
    return 1
  fi

  local selection
  selection=$(dialog --stdout --title "$title" \
    --menu "Select partition:" 20 60 10 \
    "${partitions[@]}")

  echo "$selection"
}

select_locale() {
  local locale
  locale=$(dialog --stdout --title "Locale Selection" \
    --menu "Choose system locale:" 20 60 10 \
    "en_US.UTF-8" "English (United States)" \
    "en_GB.UTF-8" "English (United Kingdom)" \
    "en_CA.UTF-8" "English (Canada)" \
    "de_DE.UTF-8" "German (Germany)" \
    "fr_FR.UTF-8" "French (France)" \
    "es_ES.UTF-8" "Spanish (Spain)" \
    "it_IT.UTF-8" "Italian (Italy)" \
    "ja_JP.UTF-8" "Japanese (Japan)" \
    "zh_CN.UTF-8" "Chinese (China)" \
    "custom" "Enter custom locale")

  if [ -z "$locale" ] || [ "$locale" = "custom" ]; then
    locale=$(get_text_input "Custom Locale" "Enter locale (e.g., pt_BR.UTF-8):" "")
  fi

  # Fallback to en_US.UTF-8 if empty
  if [ -z "$locale" ]; then
    locale="en_US.UTF-8"
  fi

  echo "$locale"
}

select_timezone() {
  local region continent

  continent=$(dialog --stdout --title "Timezone - Continent" \
    --menu "Select continent:" 20 60 10 \
    "America" "" "Europe" "" "Asia" "" "Africa" "" \
    "Australia" "" "Pacific" "" "Atlantic" "" "UTC" "")

  # Fallback if cancel or empty
  if [ -z "$continent" ] || [ "$continent" = "UTC" ]; then
    echo "UTC"
    return
  fi

  local cities=()
  while IFS= read -r city; do
    cities+=("$city" "")
  done < <(find "/usr/share/zoneinfo/$continent" -type f -printf "%f\n" 2>/dev/null | sort)

  if [ ${#cities[@]} -eq 0 ]; then
    echo "UTC"
    return
  fi

  region=$(dialog --stdout --title "Timezone - City" \
    --menu "Select city/region:" 20 60 15 \
    "${cities[@]}")

  if [ -z "$region" ]; then
    echo "UTC"
  else
    echo "$continent/$region"
  fi
}

# Append sudoers wheel group carefully
configure_sudoers() {
  local sudoers_dropin="$MOUNT_DIR/etc/sudoers.d/wheel"
  if [ ! -f "$sudoers_dropin" ]; then
    echo "%wheel ALL=(ALL) ALL" > "$sudoers_dropin"
    chmod 440 "$sudoers_dropin"
  fi
}

# Replace installation subshell with function for better error visibility
perform_installation_tasks() {

  echo "10" ; echo "# Setting up LUKS encryption..."

  # Setup LUKS if requested
  if [ "$USE_LUKS" = "yes" ]; then
    echo -n "$LUKS_PASS" | cryptsetup luksFormat --type luks2 "/dev/$ROOT_PART" -
    echo -n "$LUKS_PASS" | cryptsetup open "/dev/$ROOT_PART" void_root -
    ROOT_DEVICE="/dev/mapper/void_root"
    LUKS_OPEN="yes"

    if [ "$ENCRYPT_HOME" = "yes" ]; then
      echo -n "$LUKS_HOME_PASS" | cryptsetup luksFormat --type luks2 "/dev/$HOME_PART" -
      echo -n "$LUKS_HOME_PASS" | cryptsetup open "/dev/$HOME_PART" void_home -
      HOME_DEVICE="/dev/mapper/void_home"
    fi
  else
    ROOT_DEVICE="/dev/$ROOT_PART"
    [ "$SEPARATE_HOME" = "yes" ] && HOME_DEVICE="/dev/$HOME_PART"
  fi

  echo "20" ; echo "# Formatting partitions..."

  # Format partitions
  case $FS_TYPE in
    ext4) mkfs.ext4 -F "$ROOT_DEVICE" ;;
    btrfs) mkfs.btrfs -f "$ROOT_DEVICE" ;;
    xfs) mkfs.xfs -f "$ROOT_DEVICE" ;;
    f2fs) mkfs.f2fs -f "$ROOT_DEVICE" ;;
  esac

  [ "$SEPARATE_HOME" = "yes" ] && mkfs.ext4 -F "$HOME_DEVICE"

  echo "30" ; echo "# Mounting partitions..."

  # Mount partitions
  mkdir -p "$MOUNT_DIR"
  mount "$ROOT_DEVICE" "$MOUNT_DIR"

  if [ "$SEPARATE_HOME" = "yes" ]; then
    mkdir -p "$MOUNT_DIR/home"
    mount "$HOME_DEVICE" "$MOUNT_DIR/home"
  fi

  mkdir -p "$MOUNT_DIR/boot/efi"
  mount "/dev/$EFI_PART" "$MOUNT_DIR/boot/efi"

  echo "40" ; echo "# Downloading base system..."

  cd /tmp
  if [ ! -f void-rootfs.tar.xz ]; then
    wget -O void-rootfs.tar.xz "https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS-20240314.tar.xz"
  fi

  echo "50" ; echo "# Extracting base system..."
  tar xf void-rootfs.tar.xz -C "$MOUNT_DIR"

  echo "60" ; echo "# Preparing chroot environment..."

  mount --rbind /sys "$MOUNT_DIR/sys"
  mount --make-rslave "$MOUNT_DIR/sys"
  mount --rbind /dev "$MOUNT_DIR/dev"
  mount --make-rslave "$MOUNT_DIR/dev"
  mount --rbind /proc "$MOUNT_DIR/proc"
  mount --make-rslave "$MOUNT_DIR/proc"

  cp /etc/resolv.conf "$MOUNT_DIR/etc/"

  echo "70" ; echo "# Installing packages..."

  cat << 'CHROOT_EOF' > "$MOUNT_DIR/tmp/setup.sh"
#!/bin/bash
set -e
xbps-install -Syu xbps
xbps-install -Syu
xbps-install -y base-system
xbps-install -y linux-asahi linux-firmware-asahi
xbps-install -y mesa-asahi speakersafetyd asahi-audio
xbps-install -y cryptsetup lvm2
xbps-install -y grub-arm64-efi
xbps-install -y NetworkManager dhcpcd iwd wpa_supplicant
xbps-install -y vim nano wget curl git htop tmux
xbps-install -y e2fsprogs dosfstools ntfs-3g exfatprogs
ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
CHROOT_EOF

  chmod +x "$MOUNT_DIR/tmp/setup.sh"
  xchroot "$MOUNT_DIR" /tmp/setup.sh

  echo "80" ; echo "# Installing desktop environment..."

  if [ "$INSTALL_DE" = "yes" ]; then
    case $SELECTED_DE in
      xfce)
        xchroot "$MOUNT_DIR" xbps-install -y xfce4 xfce4-plugins lightdm lightdm-gtk-greeter
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/lightdm /etc/runit/runsvdir/default/
        ;;
      kde)
        xchroot "$MOUNT_DIR" xbps-install -y kde5 sddm
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/sddm /etc/runit/runsvdir/default/
        ;;
      gnome)
        xchroot "$MOUNT_DIR" xbps-install -y gnome gdm
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/gdm /etc/runit/runsvdir/default/
        ;;
      mate)
        xchroot "$MOUNT_DIR" xbps-install -y mate mate-extra lightdm lightdm-gtk-greeter
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/lightdm /etc/runit/runsvdir/default/
        ;;
      cinnamon)
        xchroot "$MOUNT_DIR" xbps-install -y cinnamon lightdm lightdm-gtk-greeter
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/lightdm /etc/runit/runsvdir/default/
        ;;
      lxqt)
        xchroot "$MOUNT_DIR" xbps-install -y lxqt sddm
        xchroot "$MOUNT_DIR" ln -sf /etc/sv/sddm /etc/runit/runsvdir/default/
        ;;
      sway)
        xchroot "$MOUNT_DIR" xbps-install -y sway swaylock swayidle waybar foot
        ;;
    esac
  fi

  echo "85" ; echo "# Configuring system..."

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

  if [ "$USE_LUKS" = "yes" ]; then
    ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    echo "void_root UUID=$ROOT_UUID none luks" > "$MOUNT_DIR/etc/crypttab"

    if [ "$ENCRYPT_HOME" = "yes" ]; then
      HOME_UUID=$(blkid -s UUID -o value "/dev/$HOME_PART")
      echo "void_home UUID=$HOME_UUID none luks" >> "$MOUNT_DIR/etc/crypttab"
    fi
  fi

  if [ "$USE_LUKS" = "yes" ]; then
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
  else
    ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
  fi
  EFI_UUID=$(blkid -s UUID -o value "/dev/$EFI_PART")

  cat > "$MOUNT_DIR/etc/fstab" << EOF
# <file system> <dir> <type> <options> <dump> <pass>
UUID=$ROOT_UUID / $FS_TYPE defaults 0 1
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF

  if [ "$SEPARATE_HOME" = "yes" ]; then
    if [ "$ENCRYPT_HOME" = "yes" ]; then
      HOME_UUID=$(blkid -s UUID -o value "$HOME_DEVICE")
    else
      HOME_UUID=$(blkid -s UUID -o value "/dev/$HOME_PART")
    fi
    echo "UUID=$HOME_UUID /home ext4 defaults 0 2" >> "$MOUNT_DIR/etc/fstab"
  fi

  if [ "$USE_LUKS" = "yes" ]; then
    LUKS_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$LUKS_UUID:void_root /" "$MOUNT_DIR/etc/default/grub"
    echo "GRUB_ENABLE_CRYPTODISK=y" >> "$MOUNT_DIR/etc/default/grub"
    echo 'add_dracutmodules+=" crypt dm "' >> "$MOUNT_DIR/etc/dracut.conf.d/10-crypt.conf"
  fi

  echo "90" ; echo "# Setting passwords..."

  echo "root:$ROOT_PASS" | xchroot "$MOUNT_DIR" chpasswd
  xchroot "$MOUNT_DIR" useradd -m -G wheel,audio,video,optical,storage "$USERNAME"
  echo "$USERNAME:$USER_PASS" | xchroot "$MOUNT_DIR" chpasswd

  configure_sudoers

  echo "95" ; echo "# Installing bootloader..."

  [ "$USE_LUKS" = "yes" ] && xchroot "$MOUNT_DIR" dracut --force --hostonly

  xchroot "$MOUNT_DIR" grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=void --removable
  xchroot "$MOUNT_DIR" grub-mkconfig -o /boot/grub/grub.cfg

  echo "98" ; echo "# Finalizing installation..."

  xchroot "$MOUNT_DIR" xbps-reconfigure -fa

  rm -f "$MOUNT_DIR/tmp/setup.sh"

  echo "100" ; echo "# Installation complete!"
}

perform_installation() {
  perform_installation_tasks | dialog --title "Installing Void Linux" --gauge "Starting installation..." 10 70 0
  umount_virtuals
  umount_root
  if [ "$USE_LUKS" = "yes" ]; then
    cryptsetup close void_root
    [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close void_home
  fi
}

show_completion() {
  local message="Installation completed successfully!\n\n"

  if [ "$USE_LUKS" = "yes" ]; then
    message+="LUKS encryption is ENABLED.\n"
    message+="You will be prompted for your passphrase at boot.\n\n"
  fi

  message+="IMPORTANT: Update the Asahi boot environment:\n"
  message+="  sudo update-m1n1\n\n"
  message+="System Information:\n"
  message+="  Username: $USERNAME\n"
  message+="  Hostname: $HOSTNAME\n"
  [ "$INSTALL_DE" = "yes" ] && message+="  Desktop: $SELECTED_DE\n"
  message+="\nYou can now reboot into Void Linux!"

  dialog --title "Installation Complete" --msgbox "$message" 20 70
}

# Main execution

clear
check_root
check_architecture
check_dependencies

main_menu
perform_installation
show_completion

clear
print_msg "Installation complete!"
print_msg "Don't forget to run: sudo update-m1n1"
echo ""
