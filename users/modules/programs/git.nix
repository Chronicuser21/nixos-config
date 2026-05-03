{...}: {
  programs.git = {
    enable = true;
    settings = {
      user.email = "eighty_cleaver0e@icloud.com";
      user.name = "Chronicuser21";
      alias = {
        adog = "git -c core.pager='less -S' log --all --decorate --oneline --graph";
      };
      pull.rebase = false;
    };
    ignores = [
      ".ccls-cache"
      ".direnv"
      ".envrc"
    ];
  };
}
