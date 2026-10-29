{ borealis, config, lib, ... }: {
  home-manager = {
    users.${config.borealis.user}.home.stateVersion = lib.mkDefault "26.05";
    extraSpecialArgs = { inherit borealis; };
    useGlobalPkgs = true; # Faster eval
    useUserPackages = true; # skip nix-env profile install on boot
  };
}
