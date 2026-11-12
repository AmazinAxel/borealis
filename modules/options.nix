{ lib, config, ... }: {
  options.borealis = {
    user = lib.mkOption { type = lib.types.str; };
    flake = lib.mkOption { # nx-switch target
      type = lib.types.str;
      default = "/home/${config.borealis.user}/Projects/flake";
    };
    buildHost = lib.mkOption { # nde builds here (eg. a box with binfmt for aarch64), null = build locally
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };
}
