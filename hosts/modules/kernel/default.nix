{config, ...}:

{
  # Enable asahi if needed by the system
  hardware.asahi.enable = config.platform.asahi;

  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
}
