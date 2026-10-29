{ pkgs, config, ... }: {
  gtk = {
    enable = true;
    gtk3.bookmarks = with config.xdg.userDirs; map (d: "file://${d}") [
      download documents music pictures extraConfig.PROJECTS videos
    ];

    font = {
      name = "Ubuntu Nerd Font Propo Medium";
      package = pkgs.nerd-fonts.ubuntu-sans;
      size = 11;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme; # flurry bakes its own icons in
    };
    theme = {
      name = "Graphite-Dark-nord";
      package = pkgs.callPackage ./graphite-gtk-theme.nix {
        tweaks = [ "nord" ];
        colorVariants = [ "light" "dark" ];
      };
    };
    gtk4.theme = config.gtk.theme;
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
      "org/nemo/window-state".start-with-status-bar = false; # this info is inaccurate
      "org/nemo/preferences".desktop-is-home-dir = true; # drop the dead ~/Desktop entry from the sidebar
    };
  };
  xdg.configFile."gtk-4.0/gtk.css".force = true; # wont build otherwise
}
