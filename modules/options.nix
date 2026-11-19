{ lib, config, ... }: {
  options.borealis = {
    user = lib.mkOption { type = lib.types.str; };
    flake = lib.mkOption { # nx-switch target
      type = lib.types.str;
      default = "/home/${config.borealis.user}/Projects/flake";
    };
    buildHost = lib.mkOption { # nx-switch, nde, nsp build here over ssh instead of locally
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };
  config = lib.mkIf (config.borealis.buildHost != null) (lib.mkMerge [
    { nix.gc.options = lib.mkDefault "--delete-older-than 14d"; } # nx-switch starts nix-gc after switching
    # build host serves its store over http (zstd, parallel) for nx-switch/nsp; paths carry the daemon's signatures
    (lib.mkIf (config.borealis.buildHost == config.networking.hostName) {
      services.harmonia.cache.enable = true; # [::]:5000
      networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ 5000 ];
    })
  ]);
}
