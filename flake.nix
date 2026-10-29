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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit.follows = ""; # for development only
      };
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.flake-compat.follows = "";
    };

    # shell
    flurry = {
      url = "github:AmazinAxel/flurry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # apps
    helix.url = "github:helix-editor/helix"; # no follows since we use cache
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
    inherit (inputs.nixpkgs) lib;
    keyed = name: imports: { key = "borealis/${name}"; inherit imports; };
    base = { key = "borealis"; _module.args.borealis = inputs; imports = [ ./modules/base.nix ]; };
    hm = keyed "home-manager" [ inputs.home-manager.nixosModules.home-manager ./modules/home-manager.nix ];
    persist = keyed "impermanence" [ inputs.impermanence.nixosModules.impermanence ];
    lanzaboote = keyed "lanzaboote" [ inputs.lanzaboote.nixosModules.lanzaboote ];
    profile = imports: { imports = [ base hm persist ] ++ imports; };
  in {
    nixosModules = {
      default = base;
      desktop = profile [ lanzaboote ./modules/desktop.nix ];
      laptop = profile [ lanzaboote ./modules/laptop.nix ];
      pi = profile [ ./modules/pi.nix ];
    } // lib.mapAttrs' (file: _: let app = lib.removeSuffix ".nix" file; in # opt-in apps, with a profile
      lib.nameValuePair app (keyed app [ ./apps/${file} ])
    ) (builtins.readDir ./apps);

    templates.default = {
      path = ./templates/default;
      description = "Borealis template";
    };
  };
}
