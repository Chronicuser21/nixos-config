{ config, pkgs, lib, inputs, host, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
      timeout = 5;
    };
    
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    
    tmp = {
      useTmpfs = false;
      tmpfsSize = "30%";
    };
    
    plymouth.enable = true;
  };

  # Networking
  networking = {
    hostName = host;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 ];
    };
  };

  # Localization
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Users
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.zsh;
  };

  # Services
  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        user = username;
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };
    
    openssh.enable = true;
    fstrim.enable = true;
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  # Programs
  programs = {
    zsh.enable = true;
    dconf.enable = true;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Catppuccin theming
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  system.stateVersion = "24.11";
}
