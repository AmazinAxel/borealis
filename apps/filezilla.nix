{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.filezilla ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/filezilla" ];
}
