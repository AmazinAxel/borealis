{ pkgs, config, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/mcdev.nix
    ../../modules/playit.nix
  ];

  networking.hostName = "alecpc";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  mcdev = {
    enable = true;
    serverDir = "/home/alec/Projects/nocturn";
    heapMB = 4096;
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive
    gnome-sound-recorder
    gnome-disk-utility
  ];

  environment.persistence."/persist".users.alec.directories = [ ".local/share/kdenlive" ];

  services = {
    xserver.videoDrivers = [ "nvidia" ]; # Load nvidia drivers

    # ONLY TAILNET
    openssh = {
      enable = true;  # for remote builds
      openFirewall = false;
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  powerManagement.cpuFreqGovernor = "performance";

  # Nvidia options --
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    extraModprobeConfig=''
      options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x1; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compliation
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false; # GPU architecture is older than Turing
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580; # GTX 1050 Ti last supported package
  };
}
