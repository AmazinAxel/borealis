{ pkgs, lib, config, ... }: let
  inherit (config.borealis) user;
in {
  # / is tmpfs, state lives on /persist (impermanence)
  environment.systemPackages = [ (pkgs.writers.writeFishBin "persist-prune" (builtins.readFile ../scripts/persist-prune.fish)) ];

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

  # Host keys live in /persist directly. Persisting all of /etc/ssh instead mounts an empty directory over it on a
  # fresh install, hiding the sshd_config NixOS links there, and sshd fails to start.
  services.openssh.hostKeys = map (k: removeAttrs k [ "name" ] // { path = "/persist/etc/ssh/ssh_host_${k.name}_key"; }) [
    { name = "rsa"; type = "rsa"; bits = 4096; }
    { name = "ed25519"; type = "ed25519"; }
    { name = "mldsa44_ed25519"; type = "mldsa44-ed25519"; }
  ];

  # tmpfs /etc: keep the password files on /persist so uids stay stable, and wait for those bind mounts
  services.userborn.passwordFilesLocation = "/var/lib/nixos";
  systemd.services = lib.genAttrs [ "userborn" "userborn-import-legacy" ] (_: {
    unitConfig.RequiresMountsFor = [ "/var/lib/nixos" "/var/lib/userborn" ];
  });

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map, userborn passwd/group/shadow
      "/var/lib/userborn" # else the legacy uid-map import reruns every boot
      "/root/.cache/nix" # flake cache
    ] ++ lib.optional ((config.services.journald.settings.Journal.Storage or null) != "volatile") "/var/log/journal" # logs survive reboot
      ++ lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd"; # saved wifi networks
    files = [
      "/etc/machine-id" # stable id
    ];

    users.${user}.directories = [
      ".local/share/git" # github login
    ];
  };
}
