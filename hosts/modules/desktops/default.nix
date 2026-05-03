{ pkgs, lib, config, ... }:
let
  cfg = config.modules.desktops;
in {
  imports = [
    ./dbus.nix
    ./xorg-packages.nix
  ];

  options.modules.desktops = {
    wayland.enable = lib.mkEnableOption "enable Wayland desktop environments";
    xorg.enable = lib.mkEnableOption "enable X.org desktop environments";
  };

  config = {
    # Display Manager: ly
    services.displayManager.ly = {
      enable = cfg.xorg.enable;
      settings = {
        animation = "matrix";
        hide_borders = true;
        hide_key_hints = true;
        hide_version_string = true;
      };
    };

    security.polkit.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.polkit_gnome ];

     xdg.portal = {
      enable = true;
      wlr.enable = cfg.wayland.enable;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
      config = {
        common.default = [ "gtk" ];
        niri = lib.mkIf cfg.wayland.enable {
          default = [ "wlr" "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        sway = lib.mkIf cfg.wayland.enable {
          default = [ "wlr" "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        xfce = lib.mkIf cfg.xorg.enable {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };

    services.xserver = {
      enable = cfg.xorg.enable;
      displayManager.startx.enable = cfg.xorg.enable;
      desktopManager.session = lib.mkIf cfg.xorg.enable [{
        name = "xfce";
        prettyName = "Xfce";
        desktopNames = [ "XFCE" ];
        bgSupport = true;
        start = ''
          ${pkgs.runtimeShell} ${pkgs.xfce.xfce4-session.xinitrc} &
          waitPID=$!
        '';
      }];
      updateDbusEnvironment = cfg.xorg.enable;
    };

    services.xserver.desktopManager.runXdgAutostartIfNone = cfg.xorg.enable;

    services.displayManager.sessionPackages = with pkgs;
      lib.mkIf cfg.wayland.enable [ niri sway hyprland ];
  };
}