{ config, pkgs, ... }: {
  programs.kdeconnect = {
    enable = true;
    package = pkgs.valent;
  };
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/valent" ];
}
