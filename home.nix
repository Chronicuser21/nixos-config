{ config, pkgs, ... }:

{
  home.username = "b";
  home.homeDirectory = "/home/b";
  home.stateVersion = "23.11";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initExtra = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Load p10k config
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      
      # Load fast-syntax-highlighting
      source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
    };
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Maple Mono NF" "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Maple Mono NF" ];
      serif = [ "Maple Mono NF" ];
    };
  };
  
  home.packages = with pkgs; [
    zsh-powerlevel10k
    zsh-fast-syntax-highlighting
    maple-mono.NF
    (nerd-fonts.fira-code)
    (nerd-fonts.jetbrains-mono)
  ];
}
