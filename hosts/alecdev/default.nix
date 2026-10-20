{ pkgs, ... }: {
  imports = [
    ../../modules/mcscripts.nix
    ../common.nix
    ../../modules/pi.nix
    ../../modules/mcdev.nix
    ../../modules/home-manager.nix
  ];

  systemd.tmpfiles.rules = [
    "w /sys/class/leds/ACT/trigger - - - - none"
    "w /sys/class/leds/PWR/trigger - - - - none"
  ]; # no power or act LEDs

  programs.fish = {
    enable = true; # enable ssh shell
    shellAliases.pf = "hx /var/lib/minecraft/plugins/Skript/scripts";
  };
  users.users.alec.shell = pkgs.fish; # use shell

  home-manager.users.alec = {
    imports = [
      ../../home-manager/fish.nix
      ../../home-manager/helix.nix
    ];
    home.stateVersion = "26.05";
  };

  mcdev = {
    enable = true;
    serverDir = "/var/lib/minecraft";
    heapMB = 2048;
  };

  environment.persistence."/persist".directories = [ "/var/lib/minecraft" ];
  powerManagement.cpuFreqGovernor = "performance"; # better performance

  # Networking
  networking.hostName = "alecdev";
  system.stateVersion = "26.05";


  /*
  [all]
  # Pi 4
  kernel=u-boot-rpi4.bin
  enable_gic=1
  armstub=armstub8-gic.bin
  arm_boost=1

  # For proper boot
  arm_64bit=1
  enable_uart=1

  # Disable hdmi output
  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2

  # Faster boot
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
