{ pkgs, lib, config, inputs, ... }:

{
  imports = [ ./modules/common.nix ];

  # Enable zsh
  programs.zsh.enable = true;

  # Create /bin/bash symlink for compatibility (e.g., Homebrew)
  system.activationScripts.binBash = {
    deps = [];
    text = ''
      mkdir -p /bin
      ln -sf ${pkgs.bashInteractive}/bin/bash /bin/bash
    '';
  };

  # Networking
  networking.hostName = "asahi";
  networking.networkmanager.enable = true;

  # Desktop support
  modules.desktops.xorg.enable = true;
  modules.desktops.wayland.enable = true;

  # Configure users
  users.mutableUsers = true;
  users.users.b = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager" # Allow the user to access the network manager
      "audio" # Needed for supercollider/tidal
#      "jackaudio" # Needed for services.jack (I think)
      "video"
      "input" # above needed for brightnessctl
      "docker"
      # something to do with pio
  #    "uucp"
 #     "lock"
    ];
  };

  # Configure system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    base16-schemes
    skwd-wall
    gsettings-desktop-schemas
    (chromium.override { enableWideVine = true; })
  ];

  # Fonts
  fonts.packages = with pkgs; [ maple-mono.NF ];
  fonts.fontconfig.defaultFonts.monospace = [ "Maple Mono NF" ];

  # Ensure Maple Mono NF is the default monospace font
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <alias>
        <family>monospace</family>
        <prefer>
          <family>Maple Mono NF</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  # This has to go here for some reason
  programs.ladybird.enable = true;

  # required udev rules for platformio
  services.udev.packages = [pkgs.platformio-core.udev pkgs.openocd];
 services.xserver.libinput.enable = true;
services.xserver.libinput.touchpad.tapping = true;
services.libinput.touchpad.tapping = true;  
# swap
  swapDevices = [{
    device = "/swapfile";
    size = 8192; # 8GB
  }];

  # Stylix theming (includes plymouth boot splash and systemd-boot theme)
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tarot.yaml";

  # virtualization
 virtualisation.docker.enable = true;
  # enable x86 emulation if we're on an aarch64 system
  boot.binfmt.emulatedSystems = lib.mkIf
    (config.platform.type == "aarch64-linux") ["x86_64-linux"];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this
  # particular machine, and is used to maintain compatibility with application
  # data (e.g. databases) created on older NixOS versions. For more information,
  # see `man configuration.nix` or
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

  # Allow unfree packages (chromium, etc.)
  nixpkgs.config.allowUnfree = true;

  # Enable OpenClaw with Ollama
  services.openclaw.enable = true;
  services.openclaw.ollama.enable = false;
  services.openclaw.ollamaModel = "llama3.2";

  # Allow insecure OpenClaw package
  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.4.21" ];

  # Nix settings for binary caches
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cachix.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
    ];
  };
}

