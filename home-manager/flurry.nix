{ borealis, ... }: {
  imports = [ borealis.flurry.homeManagerModules.default ];

  programs.flurry.enable = true;
}
