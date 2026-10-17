{ pkgs, lib, ... }: {
  imports = [ ./tmpfs-root.nix ];

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages; # LTS

    loader = { # Raspi boot
      systemd-boot.enable = false;
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
    };

    initrd.systemd.enable = false; # necessary for boot, fail to start closure otherwise
    supportedFilesystems = lib.mkForce [ "ext4" ]; # dont build zfs!!
    initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  };

  networking = {
    useNetworkd = false; # use nm
    networkmanager = {
      enable = true;
      wifi.powersave = false; # Stops network drops
      settings.device."wifi.scan-rand-mac-address" = "no"; # helps with drops
    };
    wireless.iwd.enable = false; # use nm
  };
  systemd.network.enable = false; # no networkd

  # help with wifi drops
  boot.extraModprobeConfig = "options brcmfmac roamoff=1 feature_disable=0x82000";

  hardware = {
    enableRedistributableFirmware = lib.mkForce false; # not needed
    firmware = [ pkgs.raspberrypiWirelessFirmware ]; # needed for wifi to work
  };

  nixpkgs.flake = { # faster rebuilds since we dont have to upload the nixpkgs source
    setNixPath = false;
    setFlakeRegistry = false;
  };

  # avahi .local publishing comes from common.nix
  services.openssh.enable = true;

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" "nodiratime" "commit=600" "data=ordered" "errors=remount-ro" ];
  };
  fileSystems."/boot" = { # extlinux kernels
    device = "/persist/boot";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections" # networkmanager wifi
  ];

  services.journald.settings.Journal.Storage = "volatile";
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.kernel.sysctl = {
    "vm.dirty_background_bytes" = 32 * 1024 * 1024; # start background writeback
    "vm.dirty_bytes" = 96 * 1024 * 1024; # only block the writer here
    "vm.dirty_expire_centisecs" = 6000; # a page may sit dirty 60s before forced out
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50; # keep dentry/inode cache, avoids re-reads
  };


  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
      randomizedDelaySec = "30m";
    };
  };
}
