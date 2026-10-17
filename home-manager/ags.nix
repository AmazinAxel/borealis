{ inputs, pkgs, lib, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
  astal = inputs.astal.packages.${system};

  extraPackages = with pkgs; [
    astal.apps # App launcher
    astal.auth
    astal.battery
    astal.bluetooth
    astal.mpris
    astal.notifd
    astal.wireplumber
    astal.wl4
    webkitgtk_6_0 # webview
    glib-networking # TLS stuff for webview
    brightnessctl
    sway # swaymsg IPC
    iwd # wifi control
    mpc # MPD
    cliphist
    wl-clipboard # wl-copy
    swappy
    swaybg
    procps # pkill for gpu-screenrec
    ffmpeg-headless # clipboard video thumbnails & compression
  ];

  # CLI
  ags = inputs.ags.packages.${system}.default.override { inherit extraPackages; };

  shell = pkgs.stdenv.mkDerivation {
    name = "ags-shell";
    src = ../ags;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ags ];
    buildInputs = extraPackages ++ [ pkgs.glib pkgs.gjs astal.io astal.astal4 ];
    installPhase = ''
      mkdir -p $out/bin
      HOME=$TMPDIR ags bundle app.ts $out/bin/ags-shell
    '';
    preFixup = ''
      gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath extraPackages})
    '';
  };
in {
  home.packages = [ ags ];

  systemd.user.services.ags = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      ExecStart = "${shell}/bin/ags-shell";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
