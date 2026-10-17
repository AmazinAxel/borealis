{ pkgs, config, ... }: {
  gtk = {
    enable = true;
    gtk3.bookmarks = [
      "file:///home/alec/Downloads"
      "file:///home/alec/Documents"
      "file:///home/alec/Music"
      "file:///home/alec/Pictures"
      "file:///home/alec/Projects"
      "file:///home/alec/Videos"
    ];

    font = {
      name = "Ubuntu Nerd Font Propo Medium";
      package = pkgs.nerd-fonts.ubuntu-sans;
      size = 11;
    };
    iconTheme = {
      name = "MoreWaita";
      package = pkgs.morewaita-icon-theme;
    };
    theme = {
    name = "Graphite-Dark-nord";
    package = pkgs.callPackage ./graphite-gtk-theme.nix {
      tweaks = [ "nord" ];
      colorVariants = [ "light" "dark" ];
    };
    };
    # gtk3.extraConfig.gtk-im-module = "fcitx";
    gtk4 = {
      theme = config.gtk.theme;
      # extraConfig.gtk-im-module = "fcitx";
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Graphite-Dark-nord";
      };
      "org/gnome/SoundRecorder".audio-profile = "mp3";
      "org/nemo/window-state".start-with-status-bar = false; # this info is inaccurate
      "org/nemo/preferences".desktop-is-home-dir = true; # drop the dead ~/Desktop entry from the sidebar
    };
  };
  xdg.configFile."gtk-4.0/gtk.css".force = true; # wont build otherwise
}
