#!/bin/bash
# Void Linux Installer for Asahi M1 – fixed device handling

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_msg()   { echo -e "${GREEN}[*]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Globals (device *paths*)
MOUNT_DIR="/mnt/void"
USE_LUKS="no"
SEPARATE_HOME="no"
ENCRYPT_HOME="no"
LUKS_OPEN="no"
ROOT_DEV=""
HOME_DEV=""
EFI_DEV=""
FS_TYPE=""
HOSTNAME=""
USERNAME=""
USER_PASS=""
ROOT_PASS=""
LUKS_PASS=""
LUKS_HOME_PASS=""
LOCALE=""
TIMEZONE=""
INSTALL_DE="no"
SELECTED_DE=""
LUKS_ROOT_NAME="void_crypt_root"
LUKS_HOME_NAME="void_crypt_home"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_arch() {
    if [ "$(uname -m)" != "aarch64" ]; then
        print_error "This script is for ARM64 (aarch64) only"
        exit 1
    fi
}

cleanup_on_error() {
    print_error "Installation failed. Cleaning up..."

    if [ "${LUKS_OPEN:-no}" = "yes" ] && [ "${USE_LUKS:-no}" = "yes" ]; then
        cryptsetup close "$LUKS_ROOT_NAME" 2>/dev/null || true
        [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close "$LUKS_HOME_NAME" 2>/dev/null || true
    fi

    umount -R "$MOUNT_DIR" 2>/dev/null || true
    exit 1
}

trap cleanup_on_error ERR

select_partition() {
    # outputs a full device path like /dev/nvme0n1p8
    local title="$1"
    local parts=()
    while IFS= read -r line; do
        # NAME SIZE TYPE
        set -- $line
        local name="$1" size="$2" type="$3"
        [ "$type" = "part" ] || continue
        parts+=("/dev/$name" "$size")
    done < <(lsblk -ln -o NAME,SIZE,TYPE)

    if [ ${#parts[@]} -eq 0 ]; then
        print_error "No partitions found"
        exit 1
    fi

    echo
    echo "== $title =="
    local i idx=1
    for ((i=0; i<${#parts[@]}; i+=2)); do
        printf " %2d) %-15s %s\n" "$idx" "${parts[i]}" "${parts[i+1]}"
        idx=$((idx+1))
    done
    echo -n "Enter choice number: "
    read -r choice
    if ! [ "$choice" -ge 1 ] 2>/dev/null; then
        print_error "Invalid choice"
        exit 1
    fi
    local index=$(( (choice-1)*2 ))
    echo "${parts[index]}"
}

ask_basic_info() {
    echo
    echo "=== Void Linux Installer for Asahi M1 ==="
    echo

    ROOT_DEV=$(select_partition "Select ROOT partition")
    echo "Selected ROOT: $ROOT_DEV"

    echo -n "Use LUKS encryption for root? (y/N): "
    read -r ans
    [ "${ans,,}" = "y" ] && USE_LUKS="yes"

    echo -n "Separate /home partition? (y/N): "
    read -r ans
    if [ "${ans,,}" = "y" ]; then
        SEPARATE_HOME="yes"
        HOME_DEV=$(select_partition "Select /home partition")
        echo "Selected HOME: $HOME_DEV"

        if [ "$USE_LUKS" = "yes" ]; then
            echo -n "Encrypt /home with LUKS too? (y/N): "
            read -r ans
            [ "${ans,,}" = "y" ] && ENCRYPT_HOME="yes"
        fi
    fi

    echo
    echo "Detecting EFI partition (FAT32)..."
    EFI_DEV=$(lsblk -no NAME,FSTYPE,PARTTYPE | awk '/vfat/ {print "/dev/"$1; exit}')
    if [ -z "$EFI_DEV" ]; then
        print_warn "Could not auto-detect EFI; please select manually."
        EFI_DEV=$(select_partition "Select EFI partition")
    fi
    echo "EFI: $EFI_DEV"

    echo
    echo "Filesystem options: ext4, btrfs, xfs, f2fs"
    echo -n "Root filesystem type [ext4]: "
    read -r FS_TYPE
    FS_TYPE=${FS_TYPE:-ext4}

    echo -n "Hostname [void-asahi]: "
    read -r HOSTNAME
    HOSTNAME=${HOSTNAME:-void-asahi}

    echo -n "Username: "
    read -r USERNAME
    [ -z "$USERNAME" ] && { print_error "Username required"; exit 1; }

    echo -n "User password: "
    read -rs USER_PASS; echo
    echo -n "Confirm user password: "
    read -rs tmp; echo
    [ "$USER_PASS" != "$tmp" ] && { print_error "User passwords do not match"; exit 1; }

    echo -n "Root password: "
    read -rs ROOT_PASS; echo
    echo -n "Confirm root password: "
    read -rs tmp; echo
    [ "$ROOT_PASS" != "$tmp" ] && { print_error "Root passwords do not match"; exit 1; }

    if [ "$USE_LUKS" = "yes" ]; then
        echo -n "LUKS passphrase for root: "
        read -rs LUKS_PASS; echo
        echo -n "Confirm LUKS passphrase: "
        read -rs tmp; echo
        [ "$LUKS_PASS" != "$tmp" ] && { print_error "LUKS passphrases do not match"; exit 1; }

        if [ "$ENCRYPT_HOME" = "yes" ]; then
            echo -n "Use same passphrase for /home? (Y/n): "
            read -r ans
            if [ "${ans,,}" = "n" ]; then
                echo -n "LUKS passphrase for /home: "
                read -rs LUKS_HOME_PASS; echo
            else
                LUKS_HOME_PASS="$LUKS_PASS"
            fi
        fi
    fi

    LOCALE="en_US.UTF-8"
    TIMEZONE="UTC"

    echo
    echo "Summary:"
    echo "  ROOT: $ROOT_DEV ($FS_TYPE)"
    [ "$SEPARATE_HOME" = "yes" ] && echo "  HOME: $HOME_DEV"
    echo "  EFI : $EFI_DEV"
    echo "  LUKS root : $USE_LUKS"
    echo "  LUKS home : $ENCRYPT_HOME"
    echo "  Hostname  : $HOSTNAME"
    echo "  Username  : $USERNAME"
    echo
    echo -n "Continue? (y/N): "
    read -r ans
    if [ "${ans,,}" != "y" ]; then
        cleanup_on_error
    fi
}

format_and_mount() {
    echo
    print_msg "Setting up encryption and filesystems..."

    local root_map home_map

    if [ "$USE_LUKS" = "yes" ]; then
        echo "Encrypting root on $ROOT_DEV ..."
        echo -n "$LUKS_PASS" | cryptsetup luksFormat -y --type luks2 "$ROOT_DEV" -
        echo -n "$LUKS_PASS" | cryptsetup open "$ROOT_DEV" "$LUKS_ROOT_NAME" -
        root_map="/dev/mapper/$LUKS_ROOT_NAME"
        LUKS_OPEN="yes"

        if [ "$ENCRYPT_HOME" = "yes" ] && [ "$SEPARATE_HOME" = "yes" ]; then
            echo "Encrypting /home on $HOME_DEV ..."
            echo -n "$LUKS_HOME_PASS" | cryptsetup luksFormat -y --type luks2 "$HOME_DEV" -
            echo -n "$LUKS_HOME_PASS" | cryptsetup open "$HOME_DEV" "$LUKS_HOME_NAME" -
            home_map="/dev/mapper/$LUKS_HOME_NAME"
        fi
    fi

    ROOT_DEV=${root_map:-$ROOT_DEV}
    HOME_DEV=${home_map:-$HOME_DEV}

    echo "Formatting root $ROOT_DEV as $FS_TYPE ..."
    case "$FS_TYPE" in
        ext4) mkfs.ext4 -F "$ROOT_DEV" ;;
        btrfs) mkfs.btrfs -f "$ROOT_DEV" ;;
        xfs) mkfs.xfs -f "$ROOT_DEV" ;;
        f2fs) mkfs.f2fs -f "$ROOT_DEV" ;;
        *) print_error "Unknown FS type '$FS_TYPE'"; exit 1 ;;
    esac

    if [ "$SEPARATE_HOME" = "yes" ]; then
        echo "Formatting /home on $HOME_DEV as ext4 ..."
        mkfs.ext4 -F "$HOME_DEV"
    fi

    echo "Mounting..."
    mkdir -p "$MOUNT_DIR"
    mount "$ROOT_DEV" "$MOUNT_DIR"
    if [ "$SEPARATE_HOME" = "yes" ]; then
        mkdir -p "$MOUNT_DIR/home"
        mount "$HOME_DEV" "$MOUNT_DIR/home"
    fi
    mkdir -p "$MOUNT_DIR/boot/efi"
    mount "$EFI_DEV" "$MOUNT_DIR/boot/efi"
}

install_void_rootfs() {
    print_msg "Installing Void base rootfs..."
    cd /tmp
    if [ ! -f void-aarch64-ROOTFS.tar.xz ]; then
        wget -O void-aarch64-ROOTFS.tar.xz \
            "https://repo-default.voidlinux.org/live/current/void-aarch64-ROOTFS.tar.xz"
    fi
    tar xf void-aarch64-ROOTFS.tar.xz -C "$MOUNT_DIR" --exclude usr/share/gettext
}

prepare_chroot() {
    print_msg "Preparing chroot..."
    mount --rbind /sys "$MOUNT_DIR/sys"  ; mount --make-rslave "$MOUNT_DIR/sys"
    mount --rbind /dev "$MOUNT_DIR/dev"  ; mount --make-rslave "$MOUNT_DIR/dev"
    mount --rbind /proc "$MOUNT_DIR/proc"; mount --make-rslave "$MOUNT_DIR/proc"
    cp /etc/resolv.conf "$MOUNT_DIR/etc/"
}

run_chroot_setup() {
    print_msg "Running package setup in chroot..."

    cat > "$MOUNT_DIR/tmp/setup.sh" << 'CHROOT_EOF'
#!/bin/bash
set -e
xbps-install -Syu
xbps-install -y base-system asahi-base linux-asahi linux-firmware-asahi
xbps-install -y mesa-asahi speakersafetyd asahi-audio cryptsetup lvm2 grub-arm64-efi efibootmgr
xbps-install -y NetworkManager dhcpcd iwd wpa_supplicant vim nano sudo htop
xbps-install -y e2fsprogs dosfstools ntfs-3g
ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
ln -sf /etc/sv/dbus /etc/runit/runsvdir/default/
CHROOT_EOF

    chmod +x "$MOUNT_DIR/tmp/setup.sh"
    xchroot "$MOUNT_DIR" /tmp/setup.sh
}

configure_system() {
    print_msg "Configuring system..."

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

    # fstab
    local ROOT_UUID EFI_UUID HOME_UUID
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEV")
    EFI_UUID=$(blkid -s UUID -o value "$EFI_DEV")

    cat > "$MOUNT_DIR/etc/fstab" << EOF
UUID=$ROOT_UUID / $FS_TYPE defaults 0 1
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF

    if [ "$SEPARATE_HOME" = "yes" ]; then
        HOME_UUID=$(blkid -s UUID -o value "$HOME_DEV")
        echo "UUID=$HOME_UUID /home ext4 defaults 0 2" >> "$MOUNT_DIR/etc/fstab"
    fi

    # Users
    echo "root:$ROOT_PASS" | xchroot "$MOUNT_DIR" chpasswd
    xchroot "$MOUNT_DIR" useradd -m -G wheel,audio,video,optical,storage "$USERNAME"
    echo "$USERNAME:$USER_PASS" | xchroot "$MOUNT_DIR" chpasswd
    echo "%wheel ALL=(ALL) ALL" >> "$MOUNT_DIR/etc/sudoers"
}

install_bootloader() {
    print_msg "Installing GRUB bootloader..."

    mkdir -p "$MOUNT_DIR/boot/efi/EFI/void"
    xchroot "$MOUNT_DIR" grub-install --target=arm64-efi \
        --efi-directory=/boot/efi --bootloader-id=void --no-nvram
    xchroot "$MOUNT_DIR" grub-mkconfig -o /boot/grub/grub.cfg

    # Create NVRAM entry
    local disk partnum
    disk=$(echo "$EFI_DEV" | sed 's/p[0-9]\+$//')
    partnum=$(echo "$EFI_DEV" | grep -o '[0-9]\+$')
    efibootmgr --create --disk "$disk" --part "$partnum" \
        --label "Void Linux" --loader "\\EFI\\void\\grubaa64.efi"
}

final_cleanup() {
    print_msg "Final cleanup..."
    umount -R "$MOUNT_DIR"
    if [ "$USE_LUKS" = "yes" ]; then
        cryptsetup close "$LUKS_ROOT_NAME" 2>/dev/null || true
        [ "$ENCRYPT_HOME" = "yes" ] && cryptsetup close "$LUKS_HOME_NAME" 2>/dev/null || true
    fi
}

### MAIN

check_root
check_arch

ask_basic_info
format_and_mount
install_void_rootfs
prepare_chroot
run_chroot_setup
configure_system
install_bootloader
final_cleanup

print_msg "Installation complete. Reboot and pick 'Void Linux' from the boot picker."
