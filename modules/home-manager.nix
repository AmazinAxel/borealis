{ borealis, config, lib, ... }: {
  home-manager = {
    users.${config.borealis.user} = {
      imports = [ ../home-manager/fish.nix ];
      home.stateVersion = lib.mkDefault "26.05";
      programs.man.enable = false; # HM default-on, pulls man-db + groff; system docs are off anyway
      manual.manpages.enable = false;
      # follow the system trims (slim.nix)
      programs.fish.generateCompletions = lib.mkDefault config.programs.fish.generateCompletions;
      xdg.mime.enable = lib.mkDefault config.xdg.mime.enable;
      systemd.user.systemctlPath = "${config.systemd.package}/bin/systemctl"; # the system's systemd, not a second copy
    };
    extraSpecialArgs = { inherit borealis; };
    useGlobalPkgs = true; # Faster eval
    useUserPackages = true; # skip nix-env profile install on boot
  };
}
