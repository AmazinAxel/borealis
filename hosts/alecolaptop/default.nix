{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
    ../../modules/printing.nix
    ../../modules/bluetooth-audio.nix
  ];

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 10 * 1024; }];

  # keep more swap in memory instead of in swapfile
  zramSwap.memoryPercent = 200;

  environment.systemPackages = [ pkgs.platformio-core ];

  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
    };
  };
}
