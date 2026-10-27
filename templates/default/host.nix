{
  borealis.user = "me"; # password hash goes in /persist/passwords/me (mkpasswd)
  networking.hostName = "nixos";
  time.timeZone = "UTC";
  programs.git.config.user = { name = "Me"; email = "me@example.com"; };

  home-manager.users.me.programs.flurry.settings.sideview.plan = "https://example.com";
}
