{ config, pkgs, lib, ... }: {
  # programs.kdeconnect minus its global firewall ranges: kde connect ports on the tailnet only
  environment.systemPackages = [ pkgs.valent ];
  hardware.uinput.enable = lib.mkDefault true; # remote input plugin
  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = rec {
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
  environment.persistence."/persist".users.${config.borealis.user}.directories = [ ".config/valent" ];
}
