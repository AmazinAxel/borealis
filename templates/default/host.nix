{
  borealis.user = "me"; # put your passwd in /persist/passwords/<user>
  networking.hostName = "nixos";
  time.timeZone = "UTC";
  programs.git.config.user = { name = "Me"; email = "me@example.com"; };

  home-manager.users.me.programs.flurry.settings.sideview.plan = "https://example.com";
}
