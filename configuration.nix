{ config, lib, pkgs, inputs, system, ... }:

{
 imports = [
    ./hardware-configuration.nix
#    <home-manager/nixos>
#<apple-silicon-support/apple-silicon-support>
#./apple-silicon-support
];
boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-linux";
#nix.linux-builder.enable = true;
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
hardware.enableRedistributableFirmware = true;
services.avahi = {
enable = true;
nssmdns4 = true;
nssmdns6 = true;
publish = {
enable = true;
userServices = true;
};
};
services.flatpak.enable = true;
  boot.loader.grub.enable = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = false;
 boot.loader.systemd-boot.enable = true;
programs.nix-ld.enable = true;
  # MacBook function key support
  boot.kernelModules = [ "hid_apple" ];
  boot.kernelParams = [ "hid_apple.fnmode=2" ];
services.desktopManager.cosmic.enable = true;
#services.displayManager.cosmic-greeter.enable = true;
environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
  ];
services.ollama.enable = true;
services.usbmuxd.enable = true;

#
# Use GNOME temporarily until cosmic hash issues are resolved
# services.xserver.enable = true;  # Already enabled below
 #services.xserver.desktopManager.gnome.enable = true;
 #services.xserver.displayManager.gdm.enable = true;
  # Catppuccin theming
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";

   nix.settings = {
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    "https://cache.dataaturservice.se/spectrum/" ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "spectrum-os.org-2:foQk3r7t2VpRx92CaXb5ROyy/NBdRJQG2uX2XJMYZfU="
  ];
	};



services = {

    displayManager = {
      ly.enable = true;
    };

    xserver = {
      enable = true;
      autoRepeatDelay = 200;
      autoRepeatInterval = 35;
      desktopManager.gnome.enable = true;
      windowManager.qtile.enable = true;
      windowManager.dwm = {
        enable = true;
        package = pkgs.dwm.overrideAttrs {
          # src = ./config/dwm;
        };
      };
    };

#    picom.enable = true;
  };
  programs.zsh.enable = true;

#boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
  # LUKS theme
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.plymouth.theme = lib.mkForce "stylix";

  # TTY theme
 # console = {
  #  colors = [
   #   "1e1e2e" "f38ba8" "a6e3a1" "f9e2af"
    #  "89b4fa" "f5c2e7" "94e2d5" "bac2de"
     # "585b70" "f38ba8" "a6e3a1" "f9e2af"
#      "89b4fa" "f5c2e7" "94e2d5" "a6adc8"
 #   ];
 # };
  hardware.apple.touchBar.enable = true;

  # Display Manager and Desktop Environments - handled by JaKooLit
  services.displayManager.sddm.enable = false;
#  services.displayManager.ly.enable = true;
 # virtualisation.docker.enable = true;
    virtualisation.libvirtd.enable = true;
  # Desktop Environments
  services.desktopManager.gnome.enable = true;
 # services.desktopManager.plasma6.enable = true;

  # Stylix theming
  stylix = {
    enable = true;
    image = ./wallpaper.jpg;
    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 10;
        popups = 10;
      };
    };

    opacity = {
      applications = 1.0;
      terminal = 0.4;
      desktop = 1.0;
      popups = 1.0;
    };

    autoEnable = false;
    targets = {
      console.enable = true;
      grub.enable = false;
      nixos-icons.enable = true;
      plymouth.enable = true;
      gnome.enable = true;
      qt.enable = false;
    };
  };

  # Window Managers - handled by JaKooLit
  programs.hyprland.enable = true;

  # Proper Catppuccin configuration
  catppuccin.grub.enable = true;
  catppuccin.grub.flavor = "mocha";
  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "mocha";

  # Resolve SSH askPassword conflict
#  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";


  nix.settings.experimental-features = [ "nix-command" "flakes" ];
nixpkgs.config.allowUnFree = true;

xdg.portal  = {
enable =  true;
config.common.default = [ "hyprland" ];
extraPortals = with pkgs; [
xdg-desktop-portal-gtk
];
};

  networking.hostName = "asahi";
  nix.settings.trusted-users = [ "root" "b" ];
	networking.networkmanager.enable = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
  networking.firewall.enable = true;

  # DNS hijacking for Tails arm64 build
  #networking.extraHosts = ''
   # 192.168.68.51 chronicuser.duckdns.org
 #   151.101.66.132 deb.tails.boum.org
  #  151.101.66.132 dl.amnesia.boum.org
 # '';

  time.timeZone = "America/Chicago";

  # Enable OpenSSH daemon
  services.openssh.enable = true;

  # Create libdns_sd.so symlink for AltServer compatibility
  system.activationScripts.altserver-compat = ''
    ln -sf ${pkgs.avahi-compat}/lib/libdns_sd.so.1 /run/current-system/sw/lib/libdns_sd.so
  '';

  security.sudo.wheelNeedsPassword = false;
  # Hardware acceleration for Asahi GPU
  hardware.graphics = {
    enable = true;
  };

  # Disable VA-API for now (not fully supported on Asahi)
  #environment.variables = {
   # LIBVA_DRIVER_NAME = "none";
  #};

  users.users.b = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "docker" "libvirtd" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree
wofi
gnupg
go
gopls
nixfmt
clang
clang-tools
libtool
cmake
gnumake
direnv
curl
dbus
openssl_3
webkitgtk_4_1
nodejs
ruby
xdg-desktop-portal-gtk
sqlite
grim
qemu
pkg-config
gtk3
gdk-pixbuf
glib
openvpn
htop
tailscale
jdk17
gdb
wl-clipboard
ollama
slurp
bun
xdg-utils
oh-my-zsh
zsh-powerlevel10k
zsh-fast-syntax-highlighting
];
  };


#  programs.firefox.enable = true;

virtualisation.docker.rootless = {
enable = true;
setSocketVariable = true;
};


  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
 #   inputs.nixvim-config.packages.${system}.default
altserver-linux
avahi
nssmdns
avahi-compat
rofi
    # KDE Connect
    kdePackages.kdeconnect-kde
    # JaKooLit Hyprland essentials
    hypridle
    hyprpolkitagent
    pyprland
    hyprlang
    hyprshot
    hyprcursor
    nwg-displays
    nwg-look
    waypaper
    waybar
    wofi
    dunst
    swww
    grim
    slurp
    wl-clipboard
    kitty
     gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
    # Your existing packages
    # cloud-hypervisor  # Using patched version from modules/cloud-hypervisor-gpu.nix
    catppuccin-grub
    catppuccin-sddm-corners
    catppuccin-plymouth
    direnv
    vim
    wget
    git
    zsh-powerlevel10k
    dpkg
    debootstrap
    ruby
    bundler
    libvirt
    qemu
    pkg-config
    libvirt-glib
    vagrant
    gnupg
    python3
    python3Packages.pip
    python3Packages.setuptools
];



     # Removed: programs.neovim.enable = true;
#wayland.windowManager.hyprland = {
#enable = true;
#package = pkgs.hyprland;
#xwayland.enable = true;
#systemd.enable = true;
#};
#services.openssh.enable = true;
# Font configuration
  fonts = {
    packages = with pkgs; [
      maple-mono.NF
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Maple Mono NF" ];
      };
    };
  };
}


