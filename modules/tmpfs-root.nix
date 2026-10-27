{ config, ... }: let
  inherit (config.borealis) user;
in {
  imports = [ ./impermanence.nix ];

  # sudo install -Dm600 <(grep "^$USER:" /etc/shadow | cut -d: -f2) /passwords/<user>
  # maybe install to /persist/passwords/<user>
  users = {
    users.${user}.hashedPasswordFile = "/persist/passwords/${user}";
    mutableUsers = false;
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=4G" "mode=755" ];
  };
  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" "x-initrd.mount" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };
}
