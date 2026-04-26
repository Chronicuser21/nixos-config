# Apple MacBook Pro M1 (2020, 15 inch)

{
  platform = {
    type = "aarch64-linux";
    asahi = true;

    available-features = {
      vsync = false;
      gamma-ramp = false;
      dp-alt-mode = false;
    };

    display-management = {
      displays = {
        eDP-1 = {
          fingerprint = "--CONNECTED-BUT-EDID-UNAVAILABLE--eDP-1";
          pixel-size.width = 3072;
          pixel-size.height = 1920;
          scale.xorg = 2.0;
          scale.wayland = 1.5;
        };
      };
      profiles.default.eDP-1 = {
        position = "0 0";
      };
    };
  };
}