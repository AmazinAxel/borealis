{ config, pkgs, ... }: {
  environment.systemPackages = [ (pkgs.discord.override { useFHSEnv = false; }) ]; # FHS env pulls gcc + all glibc locales (~530M)
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/discord" ];
}
