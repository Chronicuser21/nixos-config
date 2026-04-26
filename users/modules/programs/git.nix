{...}: {
  programs.git = {
    enable = true;
    settings = {
      user.email = "billylaw1221@icloud.com";
      user.name = "b";
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
