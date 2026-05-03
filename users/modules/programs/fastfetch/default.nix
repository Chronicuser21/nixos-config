#{
 # lib,
  #config,
 # pkgs,
 # ...
#}: {
 # options = {
   # modules.fastfetch = {
    #  image = lib.mkOption {
     #   default = ./images/10.jpg;
      #  type = lib.types.path;
 #     };
  #  };
#  };
 # config = {
 #   programs.fastfetch = let
#      name = "crop.jpg";
      # this works but it kinda sucks
  #    crop = aspect: image: "${pkgs.runCommand name {} ''
   #       mkdir $out
    #    ${pkgs.imagemagick}/bin/magick ${image} -gravity center -crop ${aspect} $out/${name}
    #  ''}/crop.jpg";
 #   in {
    #  enable = true;
     # settings = {
      #  logo = {
       #   source = lib.mkDefault (crop "9:16" config.modules.fastfetch.image); # so that we can customize per-theme
        #  type = "sixel";
         # height = 14;
   #       padding = {
    #        right = 1;
     #     };
      #  };

       # display = {
        #  separator = " ★ ";
      #  };

  #      modules = let
   #       keyPadding = 8;
    #      pad = name:
     #       name
      #      + (lib.strings.replicate (keyPadding - builtins.stringLength name)
       #       " ");
        #W  paddedModule = name: {
          #  type = name;
          # key = pad name;
  #        };
   #       paddedModuleCustom = name: format: {
    #        type = "custom";
     #3       key = pad name;
       #     inherit format;
        #  };
   #     i#n [
    #      {
     #       type = "title";
