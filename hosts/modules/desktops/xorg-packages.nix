{ pkgs, lib, config, ... }:
let
  cfg = config.modules.desktops.xorg;
in {
  options.modules.desktops.xorg.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [
      # Base development tools
      pkgs.gcc
      pkgs.gnumake
      pkgs.cmake
      pkgs.pkg-config
      pkgs.automake
      pkgs.autoconf

      # Utilities
      pkgs.git
      pkgs.curl
      pkgs.moreutils
      pkgs.perl

      # Window Managers
      pkgs.bspwm
      pkgs.berry
      pkgs.sxhkd
      pkgs.i3
      pkgs.leftwm

      # Status bars / Launchers
      pkgs.polybar
      pkgs.rofi
      pkgs.rofi-emoji

      # Terminals / Compositors / Notifications
      pkgs.alacritty
      pkgs.picom
      pkgs.dunst

      # Multimedia
      pkgs.pipewire
      pkgs.wireplumber
      pkgs.alsa-utils
      pkgs.pamixer

      # Bluetooth
      pkgs.bluez

      # Music
      pkgs.mpd
      pkgs.mpdris2

      # Hardware / System
      pkgs.brightnessctl
      pkgs.playerctl
      pkgs.light
      pkgs.lm_sensors
      pkgs.feh
      pkgs.i3lock-color
      pkgs.yad
      pkgs.xclip
      pkgs.maim
      pkgs.slop
      pkgs.gpick
      pkgs.xfce.xfce4-power-manager
      pkgs.zscroll

      # Editors / Viewers
      pkgs.neovim
      pkgs.viewnior

      # Fonts (system-wide)
      pkgs.roboto
      pkgs.sarasa-gothic
      pkgs.jetbrains-mono
      pkgs.material-icons

      # GTK / Themes
      pkgs.gtk3
      pkgs.gtk4
      pkgs.gtk-engine-murrine
      pkgs.gnome-themes-extra
      pkgs.papirus-icon-theme
    ];
    description = "Packages to install for Xorg desktop environments";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = cfg.packages;

    # Enable required services for xorg
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    security.rtkit.enable = true;

    # Font configuration
    fonts.packages = [
      pkgs.roboto
      pkgs.sarasa-gothic
      pkgs.jetbrains-mono
      pkgs.material-icons
    ];
  };
}
