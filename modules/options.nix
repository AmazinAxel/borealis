{ lib, config, ... }: {
  options.borealis = {
    user = lib.mkOption { type = lib.types.str; };
    flake = lib.mkOption { # nx-switch target
      type = lib.types.str;
      default = "/home/${config.borealis.user}/Projects/flake";
    };
  };
}
