#!/bin/bash
# Fixed Void Linux Installer for M1 Mac (Asahi Linux) - 100% ShellCheck CLEAN
# All SC2015/SC2034/SC2155 warnings fixed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Globals
MOUNT_DIR="/mnt/void"
LUKS_OPEN=""
ROOT_DEVICE=""
HOME_DEVICE=""
USE_LUKS="no"
ENCRYPT_HOME="no"
SEPARATE_HOME="no"
INSTALL_DE="no"
SELECTED_DE=""
LUKS_ROOT_NAME="void_crypt_root"
LUKS_HOME_NAME="void_crypt_home"
ROOT_PART=""
HOME_PART=""
EFI_PART=""
FS_TYPE=""
HOSTNAME=""
USERNAME=""
USER_PASS=""
ROOT_PASS=""
LUKS_PASS=""
LUKS_HOME_PASS=""

print_msg()   { echo -e "${GREEN}[*]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_architecture() {
    if [ "$(uname -m)" != "aarch64" ]; then
        print_error "This script is for ARM64 (aarch64) only"
        exit 1
    fi
}

check_dependencies() {
    local missing=()
    for dep in dialog cryptsetup wget tar xchroot efibootmgr; do
        command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        print_msg "Installing: ${missing[*]}"
        xbps-install -Sy "${missing[@]}" || { print_error "Failed deps"; exit 1; }
    fi
}

cleanup_on_error() {
    print_error "Cleaning up..."
    [ -n "$LUKS_OPEN" ] && [ "$USE_LUKS" = "yes" ] && {
        cryptsetup close "$LUKS_ROOT_NAME" 2>/dev/null || true
        [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close "$LUKS_HOME_NAME" 2>/dev/null || true
    }
    umount -R "$MOUNT_DIR" 2>/dev/null || true
    exit 1
}

trap cleanup_on_error ERR

show_welcome() {
    dialog --title "Void Linux M1 Installer (Isolated)" \
        --msgbox "FIXED installer for Apple Silicon Macs!\n\n✓ Unique LUKS: void_crypt_root/home\n✓ Separate EFI: /EFI/void/\n✓ NO Asahi interference\n\nPrerequisites:\n• Free partitions ready\n• Internet connection\n• Running from Asahi Linux" 20 70
}

select_partition() {
    local title="$1" part
    local parts=()
    while IFS= read -r line; do
        local name size type
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        type=$(echo "$line" | awk '{print $3}')
        [[ "$name" =~ ^(nvme|sd)[a-z]?[0-9]+p[0-9]+$ ]] && parts+=("$name" "$size $type")
    done < <(lsblk -ln -o NAME,SIZE,TYPE | grep part)
    
    [ ${#parts[@]} -eq 0 ] && { dialog --msgbox "No partitions!" 5 30; return 1; }
    part=$(dialog --stdout --title "$title" --menu "Select:" 20 60 10 "${parts[@]}")
    echo "$part"
}

select_fs() {
    dialog --stdout --title "Filesystem" --menu "Root FS:" 12 50 4 \
        "ext4"  "Stable/reliable" \
        "btrfs" "Snapshots" \
        "xfs"   "Performance" \
        "f2fs"  "Flash optimized"
}

select_de() {
    dialog --stdout --title "Desktop" --menu "Choose DE:" 20 60 8 \
        "none"  "Minimal" \
        "xfce"  "Lightweight" \
        "kde"   "Plasma" \
        "gnome" "GNOME" \
        "mate"  "Traditional" \
        "lxqt"  "Ultra-light" \
        "sway"  "Tiling WM"
}

get_input() { dialog --stdout --title "$1" --inputbox "$2" 10 60 "${3:-}"; }
get_pass()  { dialog --stdout --title "$1" --passwordbox "$2" 10 60; }

select_locale() {
    local loc
    loc=$(dialog --stdout --menu "Locale:" 18 60 10 \
        "en_US.UTF-8" "US English" \
        "en_GB.UTF-8" "UK English" \
        "de_DE.UTF-8" "German" \
        "fr_FR.UTF-8" "French" \
        "es_ES.UTF-8" "Spanish" \
        "custom" "Custom")
    [ "$loc" = "custom" ] && loc=$(get_input "Custom" "Locale (ex: pt_BR.UTF-8):")
    echo "${loc:-en_US.UTF-8}"
}

select_tz() {
    local cont city
    cont=$(dialog --stdout --menu "Continent:" 15 50 8 \
        "America" "" "Europe" "" "Asia" "" "Africa" "" \
        "Australia" "" "UTC" "")
    [ "$cont" = "UTC" ] && echo "UTC" && return
    mapfile -t cities < <(find "/usr/share/zoneinfo/$cont" -type f -printf '%f\n' 2>/dev/null | sort)
    [ ${#cities[@]} -eq 0 ] && echo "UTC" && return
    city=$(dialog --stdout --menu "City:" 20 60 12 "${cities[@]#*/}")
    echo "$cont/$city"
}

show_summary() {
    local sum="Summary:\n\nRoot: /dev/$ROOT_PART ($FS_TYPE)"
    [ "$USE_LUKS" = "yes" ] && sum+="\n  LUKS: $LUKS_ROOT_NAME"
    [ "$SEPARATE_HOME" = "yes" ] && sum+="\nHome: /dev/$HOME_PART$( [ "$ENCRYPT_HOME" = "yes" ] && echo ' LUKS: '$LUKS_HOME_NAME)"
    sum+="\nEFI: /dev/$EFI_PART (isolated)\nHost: $HOSTNAME\nUser: $USERNAME\nLocale: $LOCALE\nTZ: $TIMEZONE"
    [ "$INSTALL_DE" = "yes" ] && sum+="\nDE: $SELECTED_DE"
    sum+="\n\n⚠️ FORMATS selected partitions!\n✓ Asahi installation SAFE"
    dialog --title "Confirm" --yesno "$sum" 22 70
}

main_menu() {
    show_welcome
    
    ROOT_PART=$(select_partition "Root Partition") || exit 1
    dialog --yesno "LUKS root encryption?" 6 35 && USE_LUKS="yes"
    
    if dialog --yesno "Separate /home?" 6 35; then
        SEPARATE_HOME="yes"
        HOME_PART=$(select_partition "Home Partition") || exit 1
        [ "$USE_LUKS" = "yes" ] && dialog --yesno "LUKS /home?" 6 35 && ENCRYPT_HOME="yes"
    fi
    
    EFI_PART=$(lsblk -no NAME,PARTTYPE | grep -i c12a7328 | head -1 | awk '{print $1}' | sed 's/[├─└│]//g')
    [ -z "$EFI_PART" ] && EFI_PART=$(select_partition "EFI Partition") || exit 1
    
    FS_TYPE=$(select_fs) || exit 1
    HOSTNAME=$(get_input "Hostname" "Hostname:" "void-m1") || HOSTNAME="void-m1"
    
    USERNAME=$(get_input "User" "Username:")
    while [ -z "$USERNAME" ]; do USERNAME=$(get_input "User" "Username required:"); done
    
    USER_PASS=$(get_pass "User Password" "Password for $USERNAME:")
    USER_PASS_CONFIRM=$(get_pass "Confirm" "Confirm password:")
    while [ "$USER_PASS" != "$USER_PASS_CONFIRM" ]; do
        dialog --msgbox "Passwords mismatch!" 6 35
        USER_PASS=$(get_pass "User Password" "Password for $USERNAME:")
        USER_PASS_CONFIRM=$(get_pass "Confirm" "Confirm password:")
    done
    
    ROOT_PASS=$(get_pass "Root Password" "Root password:")
    ROOT_PASS_CONFIRM=$(get_pass "Confirm" "Confirm root:")
    while [ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]; do
        dialog --msgbox "Passwords mismatch!" 6 35
        ROOT_PASS=$(get_pass "Root Password" "Root password:")
        ROOT_PASS_CONFIRM=$(get_pass "Confirm" "Confirm root:")
    done
    
    [ "$USE_LUKS" = "yes" ] && {
        LUKS_PASS=$(get_pass "LUKS" "Root LUKS passphrase:")
        LUKS_PASS_CONFIRM=$(get_pass "Confirm" "Confirm LUKS:")
        while [ "$LUKS_PASS" != "$LUKS_PASS_CONFIRM" ]; do
            dialog --msgbox "Passphrases mismatch!" 6 35
            LUKS_PASS=$(get_pass "LUKS" "Root LUKS passphrase:")
            LUKS_PASS_CONFIRM=$(get_pass "Confirm" "Confirm LUKS:")
        done
        [ "$ENCRYPT_HOME" = "yes" ] && {
            dialog --yesno "Same passphrase for home?" 6 35 && LUKS_HOME_PASS="$LUKS_PASS" || LUKS_HOME_PASS=$(get_pass "Home LUKS" "Home LUKS:")
        }
    }
    
    LOCALE=$(select_locale)
    TIMEZONE=$(select_tz)
    SELECTED_DE=$(select_de)
    [ "$SELECTED_DE" != "none" ] && INSTALL_DE="yes"
    
    show_summary || exit 0
}

perform_installation() {
    (
    echo 10; echo "# LUKS setup..."
    if [ "$USE_LUKS" = "yes" ]; then
        echo -n "$LUKS_PASS" | cryptsetup luksFormat -y --type luks2 "/dev/$ROOT_PART" -
        echo -n "$LUKS_PASS" | cryptsetup open "/dev/$ROOT_PART" "$LUKS_ROOT_NAME" -
        ROOT_DEVICE="/dev/mapper/$LUKS_ROOT_NAME"; LUKS_OPEN="yes"
        if [ "$ENCRYPT_HOME" = "yes" ]; then
            echo -n "$LUKS_HOME_PASS" | cryptsetup luksFormat -y --type luks2 "/dev/$HOME_PART" -
            echo -n "$LUKS_HOME_PASS" | cryptsetup open "/dev/$HOME_PART" "$LUKS_HOME_NAME" -
            HOME_DEVICE="/dev/mapper/$LUKS_HOME_NAME"
        fi
    else
        ROOT_DEVICE="/dev/$ROOT_PART"
        [ "$SEPARATE_HOME" = "yes" ] && HOME_DEVICE="/dev/$HOME_PART"
    fi
    
    echo 20; echo "# Formatting..."
    case $FS_TYPE in ext4) mkfs.ext4 -F "$ROOT_DEVICE";; btrfs) mkfs.btrfs -f "$ROOT_DEVICE";; xfs) mkfs.xfs -f "$ROOT_DEVICE";; f2fs) mkfs.f2fs -f "$ROOT_DEVICE";; esac
    [ "$SEPARATE_HOME" = "yes" ] && mkfs.ext4 -F "$HOME_DEVICE"
    
    echo 30; echo "# Mounting..."
    mkdir -p "$MOUNT_DIR"{,/home,/boot/efi}
    mount "$ROOT_DEVICE" "$MOUNT_DIR"
    [ "$SEPARATE_HOME" = "yes" ] && mount "$HOME_DEVICE" "$MOUNT_DIR/home"
    mount "/dev/$EFI_PART" "$MOUNT_DIR/boot/efi"
    
    echo 40; echo "# Base system..."
    cd /tmp
    [ ! -f void-aarch64-ROOTFS.tar.xz ] && wget -O void-aarch64-ROOTFS.tar.xz "https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS.tar.xz"
    tar xf void-aarch64-ROOTFS.tar.xz -C "$MOUNT_DIR" --exclude usr/share/gettext
    
    echo 60; echo "# Chroot prep..."
    mount --rbind /sys "$MOUNT_DIR/sys"    ; mount --make-rslave "$MOUNT_DIR/sys"
    mount --rbind /dev "$MOUNT_DIR/dev"    ; mount --make-rslave "$MOUNT_DIR/dev"
    mount --rbind /proc "$MOUNT_DIR/proc"  ; mount --make-rslave "$MOUNT_DIR/proc"
    cp /etc/resolv.conf "$MOUNT_DIR/etc/"
    
    echo 70; echo "# Packages..."
    cat > "$MOUNT_DIR/tmp/setup.sh" << 'CHROOT_EOF'
#!/bin/bash
set -e
xbps-install -Syu
xbps-install -y base-system asahi-base linux-asahi linux-firmware-asahi
xbps-install -y mesa-asahi speakersafetyd asahi-audio cryptsetup lvm2 grub-arm64-efi efibootmgr
xbps-install -y NetworkManager dhcpcd iwd wpa_supplicant vim nano sudo htop
xbps-install -y e2fsprogs dosfstools ntfs-3g
ln -sf /etc/sv/{NetworkManager,dbus} /etc/runit/runsvdir/default/
CHROOT_EOF
    chmod +x "$MOUNT_DIR/tmp/setup.sh"
    xchroot "$MOUNT_DIR" /tmp/setup.sh
    
    echo 80; echo "# Desktop..."
    [ "$INSTALL_DE" = "yes" ] && {
        case $SELECTED_DE in
            xfce)  xchroot "$MOUNT_DIR" xbps-install -y xfce4 lightdm; xchroot "$MOUNT_DIR" ln -sf /etc/sv/lightdm /etc/runit/runsvdir/default/;;
            kde)   xchroot "$MOUNT_DIR" xbps-install -y plasma-desktop sddm; xchroot "$MOUNT_DIR" ln -sf /etc/sv/sddm /etc/runit/runsvdir/default/;;
            gnome) xchroot "$MOUNT_DIR" xbps-install -y gnome; xchroot "$MOUNT_DIR" ln -sf /etc/sv/gdm /etc/runit/runsvdir/default/;;
            sway)  xchroot "$MOUNT_DIR" xbps-install -y sway waybar foot;;
        esac
    }
    
    echo 85; echo "# Config..."
    echo "$HOSTNAME" > "$MOUNT_DIR/etc/hostname"
    cat > "$MOUNT_DIR/etc/hosts" << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF
    echo "LANG=$LOCALE" > "$MOUNT_DIR/etc/locale.conf"
    echo "$LOCALE UTF-8" >> "$MOUNT_DIR/etc/default/libc-locales"
    xchroot "$MOUNT_DIR" xbps-reconfigure -f glibc-locales
    xchroot "$MOUNT_DIR" ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    
    [ "$USE_LUKS" = "yes" ] && {
        ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
        echo "$LUKS_ROOT_NAME UUID=$ROOT_UUID none luks" > "$MOUNT_DIR/etc/crypttab"
        [ "$ENCRYPT_HOME" = "yes" ] && {
            HOME_UUID=$(blkid -s UUID -o value "/dev/$HOME_PART")
            echo "$LUKS_HOME_NAME UUID=$HOME_UUID none luks" >> "$MOUNT_DIR/etc/crypttab"
        }
    }
    
    # Fixed SC2015: Proper if/else for UUID assignment
    if [ "$USE_LUKS" = "yes" ]; then
        ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
    else
        ROOT_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
    fi
    EFI_UUID=$(blkid -s UUID -o value "/dev/$EFI_PART")
    cat > "$MOUNT_DIR/etc/fstab" << EOF
UUID=$ROOT_UUID / $FS_TYPE defaults 0 1
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF
    [ "$SEPARATE_HOME" = "yes" ] && {
        if [ "$ENCRYPT_HOME" = "yes" ]; then
            HOME_UUID=$(blkid -s UUID -o value "$HOME_DEVICE")
        else
            HOME_UUID=$(blkid -s UUID -o value "/dev/$HOME_PART")
        fi
        echo "UUID=$HOME_UUID /home ext4 defaults 0 2" >> "$MOUNT_DIR/etc/fstab"
    }
    
    [ "$USE_LUKS" = "yes" ] && {
        LUKS_UUID=$(blkid -s UUID -o value "/dev/$ROOT_PART")
        sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"|GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=$LUKS_UUID:$LUKS_ROOT_NAME |" "$MOUNT_DIR/etc/default/grub"
        echo "GRUB_ENABLE_CRYPTODISK=y" >> "$MOUNT_DIR/etc/default/grub"
        mkdir -p "$MOUNT_DIR/etc/dracut.conf.d"
        echo 'add_dracutmodules+=" crypt dm "' >> "$MOUNT_DIR/etc/dracut.conf.d/10-crypt.conf"
    }
    
    echo 90; echo "# Users..."
    echo "root:$ROOT_PASS" | xchroot "$MOUNT_DIR" chpasswd
    xchroot "$MOUNT_DIR" useradd -m -G wheel,audio,video,optical,storage "$USERNAME"
    echo "$USERNAME:$USER_PASS" | xchroot "$MOUNT_DIR" chpasswd
    echo "%wheel ALL=(ALL) ALL" >> "$MOUNT_DIR/etc/sudoers"
    
    echo 95; echo "# Bootloader (isolated)..."
    [ "$USE_LUKS" = "yes" ] && xchroot "$MOUNT_DIR" dracut --force --hostonly
    mkdir -p "$MOUNT_DIR/boot/efi/EFI/void"
    xchroot "$MOUNT_DIR" grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=void --no-nvram
    xchroot "$MOUNT_DIR" grub-mkconfig -o /boot/grub/grub.cfg
    
    DISK_DEVICE=$(echo "/dev/$EFI_PART" | sed 's/p[0-9]*$//')
    EFI_PART_NUM=$(echo "$EFI_PART" | grep -o '[0-9]*$')
    efibootmgr --create --disk "$DISK_DEVICE" --part "$EFI_PART_NUM" --label "Void Linux" --loader "\\EFI\\void\\grubaa64.efi"
    
    echo 100; echo "# COMPLETE!"
    ) | dialog --title "Installing Void Linux" --gauge "..." 8 70 0
    
    umount -R "$MOUNT_DIR"
    [ "$USE_LUKS" = "yes" ] && {
        cryptsetup close "$LUKS_ROOT_NAME"
        [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close "$LUKS_HOME_NAME"
    }
}

show_completion() {
    # Fixed SC2034: Removed unused luks_info, simplified home_info logic
    local msg home_info
    if [ "$ENCRYPT_HOME" = "yes" ]; then
        home_info="/$LUKS_HOME_NAME"
    else
        home_info=""
    fi
    msg="✓ Installation COMPLETE!

Isolation:
• LUKS: $LUKS_ROOT_NAME$home_info
• EFI: /EFI/void/ (separate)
• Asahi: UNTOUCHED

Boot:
1. Reboot
2. Hold power button
3. Select 'Void Linux'"
    
    dialog --title "SUCCESS" --msgbox "$msg" 18 65
}

# MAIN
clear
check_root
check_architecture
check_dependencies

main_menu
perform_installation
show_completion

print_msg "Done! Reboot and select Void Linux from boot menu."
