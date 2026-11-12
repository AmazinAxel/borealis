{
  # Trim closure for slow remote deploys (arm, headless); HM follows these (home-manager.nix)
  system.disableInstallerTools = true; # nixos-rebuild runs on the build host, nixos-generate-config pulls perl
  xdg.mime.enable = false; # pulls shared-mime-info
  programs.fish.generateCompletions = false; # parses man pages of every package at build time
  nixpkgs.flake = { # dont ship the nixpkgs source
    setNixPath = false;
    setFlakeRegistry = false;
  };
}
