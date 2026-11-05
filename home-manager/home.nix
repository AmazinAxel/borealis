{ pkgs, config, ... }: {
  imports = [
    ./sway/keybinds.nix
    ./sway/sway.nix

    ./flurry.nix
    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./mimeapps.nix
    ./mpd.nix
    ./swappy.nix
  ];

  home = {
    # Global cursor
    pointerCursor = {
      enable = true;
      name = "Bibata-Modern-Ice";
      # only the theme used (the package holds 12, 322M)
      package = pkgs.runCommand "bibata-modern-ice" {} ''
        mkdir -p $out/share/icons
        cp -r ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice $out/share/icons/
      '';
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };
  };

  programs.man.enable = false; # HM default-on; system docs are off anyway

  xdg = {
    configFile."xdg-terminals.list".text = "footclient.desktop\n"; # open in Terminal

    dataFile."fonts".source = ./fonts; # Symlink fonts

    userDirs = {
      enable = true;
      createDirectories = true; # Auto-creates all directories
      desktop = config.home.homeDirectory; # don't want this folder
      publicShare = null;
      templates = null;
      extraConfig = {
        PROJECTS = "${config.home.homeDirectory}/Projects";
        CAPTURES = "${config.xdg.userDirs.videos}/Captures";
        CLIPS = "${config.xdg.userDirs.videos}/Clips";
      };
    };
  };
}
