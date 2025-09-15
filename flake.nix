{
  description = "JaKooLit's NixOS-Hyprland for Asahi Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    catppuccin.url = "github:catppuccin/nix";
    
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixos-apple-silicon, hyprland, home-manager, ... }:
    let
      system = "aarch64-linux";
      host = "asahi";
      username = "b";
      
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          nixos-apple-silicon.overlays.apple-silicon-overlay
        ];
      };
    in {
      nixosConfigurations."${host}" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { 
          inherit inputs system host username;
        };
        modules = [
          nixos-apple-silicon.nixosModules.apple-silicon-support
          ./hosts/${host}/configuration.nix
          ./modules/hyprland.nix
          ./modules/asahi-optimizations.nix
          inputs.catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${username} = import ./home/${username}.nix;
              extraSpecialArgs = { inherit inputs host username; };
            sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
            };
          }
        ];
      };
    };
}
