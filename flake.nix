{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playit = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # shell
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my programs
    homelab = {
      url = "github:AmazinAxel/homelab";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wintergreen = {
      url = "github:AmazinAxel/wintergreen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # apps
    helix.url = "github:helix-editor/helix"; # no follows so helix.cachix hits
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { home-manager, nixpkgs, ... }@inputs: {
    nixosConfigurations = {

      # Primary laptop
      "alecslaptop" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecslaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Old laptop
      "alecolaptop" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecolaptop/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # Desktop/compute server
      "alecpc" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecpc/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # headless devices
      # nixos-rebuild switch --flake .#<hostname> --sudo --ask-sudo-password --build-host alec@alecpc --target-host alec@<hostname>.local

      # Homelab (Zero 2W)
      "alechomelab" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./hosts/alechomelab/default.nix ];
      };

      # Pi 4B dev server
      "alecdev" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecdev/default.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # VPS
      "alecvps" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/alecvps/default.nix
        ];
      };
    };
  };
}
