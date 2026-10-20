{ inputs, lib, config, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    hideMounts = true;
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/root/.cache/nix" # flake cache
      "/etc/ssh" # host keys for ssh
      "/var/lib/tailscale"
      "/var/log/journal" # logs survive reboot
    ] ++ lib.optional config.networking.wireless.iwd.enable "/var/lib/iwd"; # saved wifi networks
    files = [
      "/etc/machine-id" # stable id
    ];

    users.alec.directories = [
      ".local/share/fish" # shell history
      ".local/share/git" # github login
    ];
  };
}
