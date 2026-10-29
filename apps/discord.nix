{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.discord ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/discord" ];
}
