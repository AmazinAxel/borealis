{ inputs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true; # Faster eval
    useUserPackages = true; # skip nix-env profile install on boot
  };
}
