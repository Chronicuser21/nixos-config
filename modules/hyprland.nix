{ config, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  environment.systemPackages = with pkgs; [
    # Catppuccin packages
    catppuccin-cursors.mochaMauve
    catppuccin-gtk
    catppuccin-kvantum
    catppuccin-papirus-folders
    # Core Hyprland ecosystem
    waybar
    wofi
    dunst
    swww
    grim
    slurp
    wl-clipboard
    cliphist
    
    # JaKooLit essentials
    kitty
    xfce.thunar
    firefox
    vscode
    
    # Media and graphics
    mpv
    imv
    gimp
    
    # System utilities
    btop
    tmux
    yazi
    neofetch
    tree
    wget
    curl
    git
    
    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    nerd-fonts.jetbrains-mono nerd-fonts.fira-code
  ];

  # XDG Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # Security
  security.pam.services.swaylock = {};
  security.polkit.enable = true;
}
