{ lib, ... }: {
  # Generic aarch64 SD-card device: u-boot extlinux, tmpfs root, /persist on the card
  imports = [ ./tmpfs-root.nix ./slim.nix ];

  boot = {
    loader = { # u-boot extlinux boot
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
    };

    supportedFilesystems = lib.mkForce [ "ext4" ]; # dont build zfs!!
    initrd.supportedFilesystems = lib.mkForce [ "ext4" ];

    kernel.sysctl = {
      "vm.dirty_background_bytes" = 32 * 1024 * 1024; # start background writeback
      "vm.dirty_bytes" = 96 * 1024 * 1024; # only block the writer here
      "vm.dirty_expire_centisecs" = 6000; # a page may sit dirty 60s before forced out
      "vm.vfs_cache_pressure" = 50; # keep dentry/inode cache, avoids re-reads
    };
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  services = {
    openssh.enable = true;
    journald.settings.Journal.Storage = "volatile";
  };

  fileSystems = {
    "/persist" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      neededForBoot = true;
      options = [ "noatime" "commit=600" "errors=remount-ro" ];
    };
    "/boot" = { # extlinux kernels
      device = "/persist/boot";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
      depends = [ "/persist" ];
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    randomizedDelaySec = "30m";
  };
}
