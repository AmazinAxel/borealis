{ config, borealis, ... }: {
  # Trim closure for slow remote deploys (arm, headless); HM follows these (home-manager.nix)
  system.disableInstallerTools = true; # nixos-rebuild runs on the build host, nixos-generate-config pulls perl
  xdg.mime.enable = false; # pulls shared-mime-info
  programs.fish.generateCompletions = false; # parses man pages of every package at build time
  nixpkgs.flake = { # dont ship the nixpkgs source
    setNixPath = false;
    setFlakeRegistry = false;
  };
  # pin `nixpkgs` (nsp, nix shell) to the system rev by URL: fetched on demand, cache hits match the system
  nix.registry.nixpkgs.to = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    inherit (borealis.nixpkgs) rev narHash;
  };
}
