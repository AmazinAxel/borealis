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
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # shell
    flurry = {
      url = "github:AmazinAxel/flurry";
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

  outputs = inputs: let
    # keyed so importing several profiles pulls each in once; upstream modules live here since imports can't use module args
    keyed = name: imports: { key = "borealis/${name}"; inherit imports; };
    base = { key = "borealis"; _module.args.borealis = inputs; imports = [ ./modules/base.nix ]; };
    hm = keyed "home-manager" [ inputs.home-manager.nixosModules.home-manager ./modules/home-manager.nix ];
    persist = keyed "impermanence" [ inputs.impermanence.nixosModules.impermanence ];
    lanzaboote = keyed "lanzaboote" [ inputs.lanzaboote.nixosModules.lanzaboote ];
    profile = imports: { imports = [ base ] ++ imports; };
  in {
    nixosModules = {
      default = base;
      home-manager = profile [ hm ]; # HM without the desktop
      desktop = profile [ hm persist lanzaboote ./modules/desktop.nix ];
      laptop = profile [ hm persist lanzaboote ./modules/laptop.nix ];
      pi = profile [ persist ./modules/pi.nix ];
    };

    templates.default = {
      path = ./templates/default;
      description = "Host flake on borealis";
    };
  };
}
