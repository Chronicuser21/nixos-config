{ config, pkgs, ... }:

{
  home.username = "b";
  home.homeDirectory = "/home/b";
  home.stateVersion = "23.11";

  home.sessionPath = [
    "$HOME/.local/bin"
    "/usr/local/bin"
  ];

  home.packages = with pkgs; [
    bottom
  ];

  home.shellAliases = {
    altserver-gui = "/home/b/launch_altserver_gui.sh";
    carbonyl = "carbonyl";
    r-hyprconfig = "r-hyprconfig";
  };

  programs.home-manager.enable = true;
}
