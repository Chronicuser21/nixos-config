# Touchbar support service
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.modules.input.tiny-dfr;
in {
  options = {
    modules.input.tiny-dfr = {
      enable = lib.mkEnableOption "Enable tiny-dfr service";
    };
  };
  config = lib.mkIf cfg.enable {
    # TODO look at https://github.com/basecamp/omarchy/issues/1840
hardware.apple.touchBar = {
      enable = true;
      package = pkgs.tiny-dfr;
    };
  };
}
