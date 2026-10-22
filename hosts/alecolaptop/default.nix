{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/laptop.nix
  ];

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 10 * 1024; }];

  # keep more swap in memory instead of in swapfile
  zramSwap.memoryPercent = 200;

  environment.systemPackages = [ pkgs.platformio-core ];

  boot.initrd.kernelModules = [ "amdgpu" ];
}
