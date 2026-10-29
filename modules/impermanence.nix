{ lib, config, ... }: {
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/root/.cache/nix" # flake cache
    ] ++ lib.optional config.services.openssh.enable "/etc/ssh" # host keys for ssh
      ++ lib.optional ((config.services.journald.settings.Journal.Storage or null) != "volatile") "/var/log/journal" # logs survive reboot
      ++ lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd"; # saved wifi networks
    files = [
      "/etc/machine-id" # stable id
    ];

    users.${config.borealis.user}.directories = [
      ".local/share/git" # github login
    ];
  };
}
