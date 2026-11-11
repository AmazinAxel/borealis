{ lib, config, ... }: {
  imports = [ ./tmpfs-root.nix ];
  home-manager.users.${config.borealis.user} = {
    imports = [ ../home-manager/fish.nix ];
    programs.man.enable = false; # HM default-on, pulls man-db + groff
    programs.fish.generateCompletions = false; # parses man pages via man-db
    manual.manpages.enable = false;
    xdg.mime.enable = false; # headless, pulls shared-mime-info
  };

  # Trim closure for slow remote deploys
  system.disableInstallerTools = true; # nixos-generate-config pulls perl, btrfs/bcachefs tools
  programs.nano.enable = false;
  xdg.mime.enable = false; # headless, pulls shared-mime-info

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

  nixpkgs = {
    hostPlatform = "aarch64-linux";
    flake = { # faster rebuilds since we dont have to upload the nixpkgs source
      setNixPath = false;
      setFlakeRegistry = false;
    };
  };

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
