{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.bun ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".bun" ];
}
