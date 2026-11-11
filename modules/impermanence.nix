{ lib, config, ... }: {
  # Host keys live in /persist directly. Persisting all of /etc/ssh instead mounts an empty directory over it on a
  # fresh install, hiding the sshd_config NixOS links there, and sshd fails to start.
  services.openssh.hostKeys = map (k: removeAttrs k [ "name" ] // { path = "/persist/etc/ssh/ssh_host_${k.name}_key"; }) [
    { name = "rsa"; type = "rsa"; bits = 4096; }
    { name = "ed25519"; type = "ed25519"; }
    { name = "mldsa44_ed25519"; type = "mldsa44-ed25519"; }
  ];

  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/root/.cache/nix" # flake cache
    ] ++ lib.optional ((config.services.journald.settings.Journal.Storage or null) != "volatile") "/var/log/journal" # logs survive reboot
      ++ lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd"; # saved wifi networks
    files = [
      "/etc/machine-id" # stable id
    ];

    users.${config.borealis.user}.directories = [
      ".local/share/git" # github login
    ];
  };
}
