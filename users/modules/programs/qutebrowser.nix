{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  options = {
    modules.qutebrowser = {
      enable = lib.mkEnableOption "whether or not to enable qutebrowser";
    };
  };
  config = let
    # base16-qutebrowser provides the scheme
    base16-qutebrowser = "${inputs.base16-qutebrowser}/templates/default.mustache";
  in
    lib.mkIf config.modules.qutebrowser.enable {
      programs.qutebrowser = {
        enable = true;
        # I'm using unstable for now because the stable version has a rendering bug
        # where some bitmap fonts (including creep) aren't rendered
        package = pkgs.qutebrowser;
        settings = let
          describeFont = font: "${toString font.size}px ${font.family}";
        in {
          fonts = {
            default_family = config.utils.fonts.active.primary.family;
            prompts = "default_size default_family";
            tabs.selected = describeFont config.utils.fonts.active.secondary;
            tabs.unselected = describeFont config.utils.fonts.active.secondary;
          };
          # TODO make helper to create python dict from attrset
          tabs = {
            "padding[\"bottom\"]" = 4;
            "padding[\"top\"]" = 4;
            position = "top";
            max_width = 160;
          };
          statusbar = {
            "padding[\"bottom\"]" = 4;
            "padding[\"top\"]" = 4;
            position = "bottom";
          };
          content.javascript.clipboard = "access";
          zoom.default = "90%";
          scrolling.bar = "when-searching";
          hints.chars = "arstneiodh"; # colemak!
          content.blocking = {
            enabled = true;
            method = "both";
          };
        };
        keyBindings = {
          normal = let
            rofi = "${pkgs.rofi}/bin/rofi -dmenu";
            spawn = ''
              spawn --userscript qute-pass -U secret -u "login: (.+)" -d "${rofi}"'';
          in {
            "xs" = "config-cycle tabs.position top left";
            "zl" = "${spawn}";
            "zul" = "${spawn} --username-only";
            "zpl" = "${spawn} --password-only";
          };
        };
        extraConfig = let
          themeFile = pkgs.writeTextFile {
            name = "theme.py";
            text =
              config.utils.mustache.eval-base16
              (builtins.readFile base16-qutebrowser);
          };
        in ''
          config.source("${themeFile}")
          # load the selected tab foreground after the theme
          c.colors.tabs.even.bg = "#${config.colorscheme.palette.base01}";
          c.colors.tabs.odd.bg = "#${config.colorscheme.palette.base02}";
          c.colors.tabs.selected.even.bg = "#${config.colorscheme.palette.base0D}";
          c.colors.tabs.selected.odd.bg = "#${config.colorscheme.palette.base0D}";
          c.colors.tabs.selected.even.fg = "#${config.colorscheme.palette.base02}";
          c.colors.tabs.selected.odd.fg = "#${config.colorscheme.palette.base02}";
        '';
      };
    };
}
