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
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };
  };

  services.wl-clip-persist.enable = true; # always paste instantly!

  # Flurry clipboard management
  services.cliphist = {
    enable = true;
    extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "5" ];
  };

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
