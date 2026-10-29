{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.flashprint ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".FlashPrint5" ];
}
