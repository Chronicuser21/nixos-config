{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix 
#<apple-silicon-support/apple-silicon-support>
#./apple-silicon-support
];

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
#nix.linux-builder.enable = true;  
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
#services.snap.enable = true;
services.flatpak.enable = true;  
  boot.loader.grub.enable = false;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = false;
 boot.loader.systemd-boot.enable = true;
  # Catppuccin theming
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
   nix.settings.substituters = [ "https://cache.dataaturservice.se/spectrum/" 
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "spectrum-os.org-2:foQk3r7t2VpRx92CaXb5ROyy/NBdRJQG2uX2XJMYZfU="
  ];
#  services.virby.enable = true;  
  
  # LUKS theme
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.plymouth.theme = "catppuccin-mocha";
  
  # TTY theme
  console = {
    colors = [
      "1e1e2e" "f38ba8" "a6e3a1" "f9e2af"
      "89b4fa" "f5c2e7" "94e2d5" "bac2de"
      "585b70" "f38ba8" "a6e3a1" "f9e2af"
      "89b4fa" "f5c2e7" "94e2d5" "a6adc8"
    ];
  };

  # Display Manager and Desktop Environments
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  
  # Desktop Environments
  services.desktopManager.gnome.enable = true;
  services.desktopManager.plasma6.enable = false;
  
  # Window Managers
  programs.hyprland.enable = true;
  services.xserver.windowManager.i3.enable = true;
  
  # Proper Catppuccin configuration
  catppuccin.grub.enable = true;
  catppuccin.grub.flavor = "mocha";
  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "mocha";

  # Resolve SSH askPassword conflict
#  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
nix.settings.auto-optimise-store = true;
#nix.gc = {
#automatic = "true";
#dates = "weekly";
#options = "--delete-older-than 30d";
#};
nixpkgs.config.allowUnFree = true;

xdg.portal  = {
enable =  true;
config.common.default = [ "hyprland" ];
extraPortals = with pkgs; [
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
];
};

  networking.hostName = "asahi";
  networking.networkmanager.enable = true;
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
  networking.firewall.enable = false;
  
  # DNS hijacking for Tails arm64 build
#  networking.extraHosts = ''
 #   151.101.66.132 deb.tails.boum.org
  #  151.101.66.132 dl.amnesia.boum.org
 # '';
  
  time.timeZone = "America/Chicago";
  
  services.openssh.enable = true;

  security.sudo.wheelNeedsPassword = false;
  
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
rustup
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
xdg-desktop-portal-hyprland
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
killall

];
  };
  

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "gh" "you-should-use" "fast-syntax-highlighting"  ];
      theme = "powerlevel10k/powerlevel10k";
    };
  };
  
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];
  
  programs.firefox.enable = true;
  
#  virtualisation.docker.enable = true;
#virtualisation.docker.rootless = {
#enable = true;
#setSocketVariable = true;
#};

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.package = pkgs.qemu;
  programs.virt-manager.enable = true;
  security.polkit.enable = true;
  
  environment.systemPackages = with pkgs; [
    cloud-hypervisor
    catppuccin-grub
    catppuccin-sddm-corners
    catppuccin-plymouth
    direnv
home-manager
    vim
    wget
    git
    rustup
    cargo
    zsh-powerlevel10k
    dpkg
    debootstrap
    ruby
    bundler
    rake
    libvirt
    qemu
    pkg-config
    libvirt-glib
    vagrant
    gnupg
    python3
    python3Packages.pip
    python3Packages.setuptools
    jq
    psmisc
    libcap
    cdrkit
     ];



services.logind = {
lidSwitch = "suspend";
lidSwitchDocked = "suspend";
};
programs.neovim.enable = true;
#wayland.windowManager.hyprland = {
#enable = true;
#package = pkgs.hyprland;
#xwayland.eanble = true;
#systemd.enable = true;
#};

#hardware.graphics = {
#enable = true;
#enable32bit = true;
#};
#hardwrae.enableAllFirmware = true;
#hardware.bluetooth.enable = true;
#hardware.bluetooth.poweronBoot = false;
}
