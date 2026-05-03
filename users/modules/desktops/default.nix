{lib, ...}:
# settings for the desktop environment, window manager,
# compositor... y'know, the works.
{
  options = {
    modules.desktops = {
      # defines fonts and stuff
      primary_display_server = lib.mkOption {
        type = lib.types.enum ["xorg" "wayland"];
      };
      # window manager / compositor selection
      # "all" enables all options for LightDM login
      window_manager = lib.mkOption {
        type = lib.types.enum ["niri" "sway" "hyprland" "all"];
        default = "all";
      };
      # enable/disable specific desktop environments and related packages
      wayland.enable = lib.mkEnableOption "enable Wayland desktop environments";
      xorg.enable = lib.mkEnableOption "enable X.org desktop environments";
    };
  };

  imports = [./xorg ./wayland ./gtk];
}
