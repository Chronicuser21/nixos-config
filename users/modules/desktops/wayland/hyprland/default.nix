{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  options = {
    modules.desktops.hyprland.wallpaper = lib.mkOption {
      description = "Wallpaper to use for Hyprland";
      type = lib.types.path;
      default = ./../../wallpapers/DSCN0737.JPG;
    };
  };
config = let
    useHyprland = config.modules.desktops.wayland.enable
      && (config.modules.desktops.window_manager == "hyprland"
        || config.modules.desktops.window_manager == "all");
  in
    lib.mkIf useHyprland {
      home.packages = with pkgs; [
        swaybg
        fuzzel
        hyprpicker
        xwayland-satellite
        hyprland
        mako
      ];

      xdg.configFile."hypr/conf/binds.main.conf".text = ''
        $mod = SUPER

        # Main
        bind = $mod, Q, killactive
        bind = $mod, E, exit
        bind = $mod, Return, exec, alacritty
        bind = $mod, F, fullscreen
        bind = $mod, B, exec, fuzzel

        # Workspaces
        bind = $mod, 1, workspace, 1
        bind = $mod, 2, workspace, 2
        bind = $mod, 3, workspace, 3
        bind = $mod, 4, workspace, 4
        bind = $mod, 5, workspace, 5
        bind = $mod, 6, workspace, 6

        # Move windows
        bind = $mod SHIFT, 1, movetoworkspace, 1
        bind = $mod SHIFT, 2, movetoworkspace, 2
        bind = $mod SHIFT, 3, movetoworkspace, 3
        bind = $mod SHIFT, 4, movetoworkspace, 4
        bind = $mod SHIFT, 5, movetoworkspace, 5
        bind = $mod SHIFT, 6, movetoworkspace, 6

        # Volume / Brightness
        bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
        bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
      '';

      xdg.configFile."hypr/conf/window.rules.conf".text = ''
        windowrulevl = float, class:^(audacious)$
        windowrulevl = float, class:^(pavucontrol)$
        windowrulevl = float, class:^(nm-connection-editor)$
      '';

      xdg.configFile."hypr/conf/startup.conf".text = ''
        exec swaybg -i ${config.modules.desktops.hyprland.wallpaper} -m fill
        exec mako --default-timeout 5000
      '';
    };
}