{ lib, config, ... }: {
  options.borealis = {
    user = lib.mkOption { type = lib.types.str; };
    flake = lib.mkOption { # linked to /etc/nixos so plain nixos-rebuild finds it
      type = lib.types.str;
      default = "/home/${config.borealis.user}/Projects/flake";
    };
  };
}
