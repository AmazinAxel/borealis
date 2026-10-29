{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.thunderbird ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".thunderbird" ];
}
