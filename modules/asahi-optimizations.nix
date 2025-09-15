{ config, pkgs, lib, ... }:

{
  hardware.asahi = {
    enable = true;
    setupAsahiSound = true;
    extractPeripheralFirmware = false;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  hardware.graphics.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
}
