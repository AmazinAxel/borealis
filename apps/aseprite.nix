{ config, pkgs, ... }: let
  inherit (config.borealis) user;
  nordTheme = pkgs.fetchFromGitHub {
    owner = "marsn3";
    repo = "aseprite-nord";
    rev = "919d9e230ef397f05a4caa870585c99639451d63";
    hash = "sha256-OXeOBBEXHDQF9qMtuOta3jjd0KpcGXQ45XanfPgxQc0=";
  };
in {
  environment.systemPackages = [ pkgs.aseprite ];
  environment.persistence."/persist".users.${user}.directories = [ ".config/aseprite" ];

  home-manager.users.${user} = { lib, ... }: {
    xdg.configFile."aseprite/extensions/aseprite-nord" = {
      source = nordTheme;
      recursive = true; # or breaks build!!
    };

    home.activation.asepriteTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${pkgs.crudini}/bin/crudini --set "$HOME/.config/aseprite/aseprite.ini" theme selected Nord
    '';
  };
}
