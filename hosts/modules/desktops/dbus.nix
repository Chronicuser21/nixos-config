{config, pkgs, lib, ...}:

{
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf pkgs.polkit_gnome ];
  };

  # system functionality
  services.upower.enable = config.powerManagement.enable;
  services.blueman.enable = config.hardware.bluetooth.enable && config.modules.desktops.wayland.enable;
  services.libinput.enable = true;
  services.accounts-daemon.enable = true;

  # file picker
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # xorg/xfce-specific 
  programs.xfconf.enable = config.modules.desktops.xorg.enable;
  services.colord.enable = config.modules.desktops.xorg.enable;
}