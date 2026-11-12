{
  borealis.user = "me"; # first login password "nixos", change with passwd
  networking.hostName = "nixos";
  time.timeZone = "UTC";
  programs.git.config.user = { name = "Me"; email = "me@example.com"; };

  home-manager.users.me.programs.flurry.settings.sideview.plan = "https://example.com";
}
