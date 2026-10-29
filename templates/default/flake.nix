{
  inputs = {
    borealis.url = "github:AmazinAxel/borealis";
    nixpkgs.follows = "borealis/nixpkgs";
  };

  outputs = { nixpkgs, borealis, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        borealis.nixosModules.laptop # or desktop
        # borealis.nixosModules.discord # apps!
        ./hardware-configuration.nix # nixos-generate-config --show-hardware-config
        ./host.nix
      ];
    };
  };
}
