{...}: {
  imports = [
    ./options.nix
  ];
  config = {
    modules.mail.accounts = {
      "iCloud" = {
        primary = true;
        gmail = false;
        mainAddress = "billylaw1221@icloud.com";
        realName = "b";
      };
    };
  };
}
