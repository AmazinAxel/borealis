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
    plan.url = "github:AmazinAxel/plan";

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

  outputs = { nixpkgs, ... }@inputs: {
    # headless devices
    # nixos-rebuild switch --flake .#<hostname> --sudo --ask-sudo-password --build-host alec@alecpc --target-host alec@<hostname>
    nixosConfigurations = nixpkgs.lib.genAttrs [
      "alecslaptop" # Primary laptop
      "alecolaptop" # Old laptop
      "alecpc" # Desktop/compute server
      "alechomelab" # Homelab (Zero 2W)
      "alecdev" # Pi 4B dev server
      "alecvps" # VPS
    ] (host: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/${host}/default.nix ];
    });
  };
}
