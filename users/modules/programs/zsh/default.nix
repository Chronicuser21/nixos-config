{
  pkgs,
  config,
  lib,
  ...
}: {
  # should this be here?
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # home.shell.enableBashIntegration = true;
  # home.shell.enableZshIntegration = true;

  # For some reason we need bash in order for firefox to pick up on the smooth
  # scrolling environment variable
  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    autosuggestion.strategy = [
      "history"
      "completion"
    ];
    shellAliases = {
      open = "xdg-open";
    };
    initContent = lib.mkAfter ''
      # load fetch (areofyl-fetch)
      if type fetch >/dev/null 2>&1; then
        fetch
      fi

      if [[ -d "${config.home.homeDirectory}/.zsh_custom/themes" ]]; then
        for theme_file in "${config.home.homeDirectory}"/.zsh_custom/themes/*.zsh-theme; do
          [[ -f "$theme_file" ]] && source "$theme_file"
        done
      fi

      # Autocomplete settings
      zstyle ":completion:*" menu select
      zstyle ":completion:*" matcher "" "m:{a-zA-Z}={A-Za-z}"
      zstyle ":completion:*" ignore-parents parent pwd ..
      zstyle ":completion:*" special-dirs true
    '';
    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.8.0";
          sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
        };
      }
      {
        name = "zsh-you-should-use";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-you-should-use";
          rev = "1.9.0";
          sha256 = "sha256-+3iAmWXSsc4OhFZqAMTwOL7AAHBp5ZtGGtvqCnEOYc0=";
        };
      }
      {
        name = "zsh-autocomplete";
        file = "zsh-autocomplete.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "25.03.19";
          sha256 = "sha256-eb5a5WMQi8arZRZDt4aX1IV+ik6Iee3OxNMCiMnjIx4=";
        };
      }
    ];
  };

  home.packages = [ pkgs.fzf pkgs.zsh-fzf-tab ];
  home.file.".zsh_custom" = {
    source = ./zsh_custom;
    recursive = true;
  };
}
