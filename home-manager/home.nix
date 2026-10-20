{ pkgs, ... }: {
  imports = [
    ./sway/keybinds.nix
    ./sway/sway.nix

    ./ags.nix
    ./aseprite.nix
    ./claude.nix
    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./helix.nix
    ./mimeapps.nix
    ./mpd.nix
    ./prismlauncher.nix
    ./spicetify.nix
    ./swappy.nix
    ./vscode.nix
    ./zen.nix
  ];

  systemd.user.startServices = "sd-switch"; # Better system unit reloads

  home = {
    stateVersion = "26.05";

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

  # Astal clipboard management
  services.cliphist = {
    enable = true;
    extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "5" ];
  };

  xdg = {
    configFile."xdg-terminals.list".text = "footclient.desktop\n"; # open in Terminal

    dataFile."fonts" = { # Symlink fonts
      target = "./fonts";
      source = ./fonts;
    };

    userDirs = {
      enable = true;
      createDirectories = true; # Auto-creates all directories
      desktop = "/home/alec"; # don't want this folder
      publicShare = null;
      templates = null;
      extraConfig = {
        PROJECTS = "/home/alec/Projects";
        CAPTURES = "/home/alec/Videos/Captures";
        CLIPS = "/home/alec/Videos/Clips";
      };
    };
  };
}
