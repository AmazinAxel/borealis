{ borealis, config, pkgs, ... }: let
  inherit (config.borealis) user;
  spicePkgs = borealis.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  environment.persistence."/persist".users.${user}.directories = [
    ".config/spotify"
    ".cache/spotify"
  ];

  home-manager.users.${user} = {
    imports = [ borealis.spicetify-nix.homeManagerModules.default ];

    programs.spicetify = {
      enable = true;

      # fix wayland
      spotifyPackage = pkgs.spotify.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/spotify --unset DISPLAY
        '';
      });

      theme = spicePkgs.themes.hazy;

      enabledExtensions = with spicePkgs.extensions; [
        autoSkipVideo
        adblock # blocks ads on homescreen?
        keyboardShortcut
        aiBandBlocker
        shuffle
        sideHide
        hidePodcasts
      ];
    };
  };
}
