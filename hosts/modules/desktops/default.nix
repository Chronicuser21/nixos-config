{ pkgs, lib, config, ... }:
let
  cfg = config.modules.desktops;
in {
  imports = [
    ./dbus.nix
  ];

  options.modules.desktops = {
    wayland.enable = lib.mkEnableOption "enable Wayland desktop environments";
    xorg.enable = lib.mkEnableOption "enable X.org desktop environments";
  };

  config = {
    services.xserver.displayManager.lightdm = {
      enable = true;
      greeters.gtk.enable = true;
    };

    security.polkit.enable = true;
    programs.dconf.enable = true;
    environment.systemPackages = [ pkgs.polkit_gnome ];

    xdg.portal = {
      enable = true;
      wlr.enable = cfg.wayland.enable;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config = {
        common.default = [ "gtk" ];
        niri = lib.mkIf cfg.wayland.enable {
          default = [ "wlr" "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        sway = lib.mkIf cfg.wayland.enable {
          default = [ "wlr" "gtk" ];
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