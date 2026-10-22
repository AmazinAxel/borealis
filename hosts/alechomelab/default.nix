{ inputs, ... }: {
  imports = [
    ./services.nix
    ./books.nix
    ../common.nix
    ../../modules/pi.nix
    inputs.plan.nixosModules.default
  ];

  services.plan = {
    enable = true;
    dataDir = "/media/plan";
  };

  systemd.tmpfiles.rules = [
    "d /run/samba/lock 0755 root root -"
    "d /run/samba/cache 0755 root root -"
    "d /run/samba/state 0755 root root -"
  ];

  users.extraGroups = {
    gpio = { };
    spi = { };
  };
  users.users.alec.extraGroups = [ "gpio" "spi" ];
  security.sudo.wheelNeedsPassword = false;

  hardware = {
    # custom spi dts for waveshare display output
    deviceTree = {
      enable = true;
      filter = "*rpi-zero-2*.dtb";
      overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
    };
  };
  boot = {
    kernelModules = [ "spidev" ];
    extraModprobeConfig = ''
      options spidev bufsiz=65536
    '';
    blacklistedKernelModules = [ "snd_bcm2835" "btbcm" "hci_uart" "bluetooth" ]; # dont need audio or bluetooth
  };

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 ];
    useNetworkd = false; # use nm
    networkmanager = {
      enable = true;
      wifi.powersave = false; # Stops network drops
      settings.device."wifi.scan-rand-mac-address" = "no"; # helps with drops
    };
    wireless.iwd.enable = false; # use nm
  };

  # must run 'sudo smbpasswd -a alec' to log in!!
  services = {
    samba = { # USB NAS
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server min protocol" = "SMB3";
          "server max protocol" = "SMB3";

          "lock directory" = "/run/samba/lock";
          "cache directory" = "/run/samba/cache";
          "state directory" = "/run/samba/state";

          "log level" = "0";
          "logging" = "syslog"; # on RAM
        };
        "USB" = {
          path = "/media";
          writable = true;
          "valid users" = [ "alec" ];
          "admin users" = [ "alec" ]; # Full read/write access
        };
      };
    };
    openssh.settings.Macs = [ "hmac-sha2-512" ]; # fix ios pass
    avahi = { # need for my iot services and wintergreen!
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        userServices = true; # NAS
      };

      extraServiceFiles.smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
    samba-wsdd = { # Auto-disovery
      enable = true;
      openFirewall = true;
    };
  };

  fileSystems."/media" = { # Attached USB drive
    device = "/dev/disk/by-label/AlecHomelabDrive";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  environment = {
    persistence."/persist" = {
      directories = [
        "/var/lib/samba" # NAS login
        "/etc/homelab" # Airnow token
        "/etc/NetworkManager/system-connections" # networkmanager wifi
      ];
      users.alec.files = [ "GithubToken" ]; # githubBackup
    };
  };

  swapDevices = [{
    device = "/media/swapfile";
    size = 1024;
    priority = 0;
    options = [ "nofail" ];
  }];
  system.stateVersion = "25.11";

  /*
  [all]
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
