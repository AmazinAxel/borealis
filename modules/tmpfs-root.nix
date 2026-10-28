{ pkgs, config, ... }: let
  inherit (config.borealis) user;
in {
  imports = [ ./impermanence.nix ];
  environment.systemPackages = [ (pkgs.writers.writeFishBin "persist-prune" (builtins.readFile ../scripts/persist-prune.fish)) ];

  # sudo grep "^$USER:" /etc/shadow | cut -d: -f2 | sudo install -Dm600 /dev/stdin /persist/passwords/<user>
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
