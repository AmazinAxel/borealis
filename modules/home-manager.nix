{ borealis, ... }: {
  home-manager = {
    extraSpecialArgs = { inherit borealis; };
    useGlobalPkgs = true; # Faster eval
    useUserPackages = true; # skip nix-env profile install on boot
  };
}
