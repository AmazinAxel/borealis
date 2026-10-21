{ inputs, pkgs, ... }: {
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    configDir = ../ags;
    systemd.enable = true;

    extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
      apps # App launcher
      auth
      battery
      bluetooth
      mpris
      notifd
      wireplumber
      wl4

      pkgs.webkitgtk_6_0 # webview
      pkgs.glib-networking # TLS stuff for webview
      pkgs.sway # swaymsg IPC
      pkgs.iwd # wifi control
      pkgs.mpc # MPD
      pkgs.cliphist
      pkgs.wl-clipboard # wl-copy
      pkgs.swappy
      pkgs.ffmpeg-headless # clipboard video thumbnails & compression
    ];
  };
}
