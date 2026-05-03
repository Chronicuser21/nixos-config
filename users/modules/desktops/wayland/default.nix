{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  config = let
    base00-darker = with inputs.nix-rice.lib.nix-rice;
      color.toRgbShortHex (color.darken 6
        (color.hexToRgba "#${config.colorscheme.palette.base00}"));
    base00-lighter = with inputs.nix-rice.lib.nix-rice;
      color.toRgbShortHex (color.brighten 20
        (color.hexToRgba "#${config.colorscheme.palette.base00}"));
    base00-lightest = with inputs.nix-rice.lib.nix-rice;
      color.toRgbShortHex (color.brighten 35
        (color.hexToRgba "#${config.colorscheme.palette.base00}"));
  in
    lib.mkIf config.modules.desktops.wayland.enable {
      home.packages = with pkgs; [
        swaybg # wallpaper
        fuzzel # application picker
        hyprpicker # color picker
        fastfetch # system info display
      ];

      # low battery alerts
      # services.batsignal.enable = true;
      # services.batsignal.extraArgs = [
      #   "-p" # send notifications when plugged/unplugged
      #   "-e" # notifications expire
      #   "-m"
      #   "15" # 15-second interval
      #   "-I"
      #   "${inputs.buuf-icon-theme}/128x128/battery-green-full.png" # this hack is hideous
      # ];

      # fuzzel config
      xdg.configFile."fuzzel/fuzzel.ini".text = lib.generators.toINI {} {
        main = {
          icon-theme = config.gtk.iconTheme.name;
          hide-prompt = true;
          horizontal-pad = 30;
          vertical-pad = 20;
        };
        colors = with config.colorScheme.palette; {
          background = "${base00}FF";
          text = "${base05}FF";
          prompt = "${base03}FF";
          placeholder = "${base03}FF";
          input = "${base03}FF";
          match = "${base0D}FF";
          selection = "${base01}FF";
          selection-text = "${base05}FF";
          selection-match = "${base0D}FF";
          counter = "${base05}FF";
          border = "${base00-lighter}FF";
        };
        # TODO can border/shadow be configured in niri instead?
        border = {
          width = 1;
          radius = 16;
          selection-radius = 4;
        };
      };

       # waybar config - let HM manage the files, but make them writable after
       programs.waybar = {
         enable = true;
         systemd.enable = true;
       };

       # Make waybar config files writable after HM switch
       home.activation.makeWaybarConfigWritable = lib.hm.dag.entryAfter ["writeBoundary"] ''
         waybarConfigDir="$HOME/.config/waybar"
         for f in config.jsonc style.css; do
           filepath="$waybarConfigDir/$f"
           if [ -e "$filepath" ]; then
             chmod u+w "$filepath" || chmod 644 "$filepath"
             echo "Made $filepath writable: $(ls -l "$filepath")"
           fi
         done
       '';
     };

  imports = [./niri ./sway ./hyprland];
}
