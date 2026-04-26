{ config, ... }:

{
  imports = [
    ./tiny-dfr.nix
  ];

  config = {
    # configure keyboard to use colemak
    services.xserver = {
      xkb = {
        layout = "us";
      };
    };

    # enable tiny-dfr, a touchbar daemon, on asahi linux
    modules.input.tiny-dfr.enable = config.platform.asahi;
  };
}
