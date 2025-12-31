{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    apple-silicon.url = "github:nix-community/nixos-apple-silicon";
   catppuccin.url = "github:catppuccin/nix"; 
 };

  outputs = inputs@{ self, nixpkgs, apple-silicon, catppuccin, ... }: 
let
system = "aarch64-linux";
host = "asahi";
username = "b";
pkgs = import nixpkgs {
inherit system;
config = {
allowUnfree = true;
};
};
in 
{
nixosConfigurations = {
${host} =
nixpkgs.lib.nixosSystem rec {
specialArgs = {
inherit system;
inherit inputs;
inherit username;
inherit host;
};
modules = [ inputs.apple-silicon.nixosModules.default 
./hardware-configuration.nix
./configuration.nix
catppuccin.nixosModules.catppuccin
];
   };
     };
