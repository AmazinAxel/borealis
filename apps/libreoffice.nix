{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.libreoffice ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/libreoffice" ];
}
