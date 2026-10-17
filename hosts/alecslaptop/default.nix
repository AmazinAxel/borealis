{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
    ../../modules/printing.nix
    ../../modules/bluetooth-audio.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  environment.systemPackages = with pkgs; [
    gnome-sound-recorder
    gnome-disk-utility
    kdePackages.kdenlive
    iotas
    maven
  ];
  programs.steam.enable = true; # Gaming
  services.pipewire.alsa.support32Bit = true; # 32-bit games

  # Bootloader settings
  boot = {
    kernelParams = [ "pm_debug_messages" ]; # log s2idle wake irqs
    consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam

    initrd = {
      includeDefaultModules = false;
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
    };
  };

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/flatpak" ]; # Sober
    users.alec = {
      directories = [
        ".local/share/Steam" ".steam" # Steam
        ".local/share/iotas"
        ".local/share/kdenlive"
      ];
      files = [ ".config/ponderosa/config.toml" ];
    };
  };

  services = {
    flatpak.enable = true; # For running Sober
    scx = { # scheduler for less active cores
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_lavd";
      extraArgs = [ "--autopower" ];
    };
  };
}
