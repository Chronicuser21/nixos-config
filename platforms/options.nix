{ lib, ... }:

{
  options = {
    platform = {
      type = lib.mkOption {
        description = "The architecture and kernel type of this platform";
        type = lib.types.enum [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
      asahi = lib.mkEnableOption
        "Whether to enable Asahi Linux support modules";
      available-features = {
        vsync = lib.mkEnableOption
          "Whether vertical synchronization in X.Org is supported";
        gamma-ramp = lib.mkEnableOption
          "Whether gamma shifting is supported (e.g., redshift, gammastep)";
        dp-alt-mode = lib.mkEnableOption ''
          Whether DisplayPort Alt Mode is supported. If it is not, the system
          configuration should enable DisplayLink.
        '';
      };
      display-management = {
        displays = lib.mkOption {
          description = "The displays available for this system";
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              fingerprint = lib.mkOption {
                type = lib.types.str;
                description = "the fingerprint of this display";
              };
              pixel-size.width = lib.mkOption {
                type = lib.types.int;
                description = "the width of this display";
              };
              pixel-size.height = lib.mkOption {
                type = lib.types.int;
                description = "the height of this display";
              };
              scale.xorg = lib.mkOption {
                type = lib.types.float;
                description = "the scale of this display on x.org";
              };
              scale.wayland = lib.mkOption {
                type = lib.types.float;
                description = "the scale of this display on wayland";
              };
            };
          });
        };
        profiles = lib.mkOption {
          description = "The display profiles available for this system";
          type = lib.types.attrsOf (lib.types.attrsOf (lib.types.submodule {
            options = {
              position = lib.mkOption {
                description = "the position of this display in logical pixels";
              };
              primary = lib.mkEnableOption "whether this is the primary display";
            };
          }));
        };
      };
    };
  };
}
