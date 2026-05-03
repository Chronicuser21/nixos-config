{
  pkgs,
  lib,
  config,
  ...
}:
let
  keybinds = config.utils.keybinds or {};
  xfce-config = keybinds.xfce or {};
  exo = xfce-config.exo or {};
  xfwm4 = xfce-config.xfwm4 or {};
  custom = xfce-config.custom or {};

  invertAttrs = lib.mapAttrs' (name: value: (lib.nameValuePair value name));

  exo-commands =
    lib.mapAttrs (keystroke: cmd: "exo-open --launch ${cmd}") (invertAttrs exo);
in {
  commands.custom = exo-commands;
  xfwm4.custom = invertAttrs xfwm4;
}