{ pkgs, lib, ... }: {
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

  # battery debug: every 2 min awake on battery, log drain, lid and top cpu users (monotonic timer pauses in suspend)
  # TODO REMOVE THIS DEBUG WHEN DONE!!
  systemd.services.battery-awake-log = {
    path = with pkgs; [ procps gawk ];
    serviceConfig.Type = "oneshot";
    script = ''
      bat=$(echo /sys/class/power_supply/BAT*)
      [ "$(cat $bat/status)" = Discharging ] || exit 0
      echo "awake on battery: $(cat $bat/capacity)%, $(( $(cat $bat/current_now) / 1000 ))mA, lid $(grep -o 'open\|closed' /proc/acpi/button/lid/*/state)"
      top -b -n2 -d1 -o %CPU -w 120 | awk '/^top -/{n++} n==2' | sed -n '7,12p'
    '';
  };
  systemd.timers.battery-awake-log = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "2min"; OnUnitActiveSec = "2min"; };
  };

  services = {
    journald.settings.Journal = { # battery debug: room for pm_debug logs overnight, flush often in case it dies
      SystemMaxUse = lib.mkForce "300M";
      SyncIntervalSec = "30s";
    };
    flatpak.enable = true; # For running Sober
    scx = { # scheduler for less active cores
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_lavd";
      extraArgs = [ "--autopower" ];
    };
  };
}
