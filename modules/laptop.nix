{ pkgs, config, ... }: let
  # AC mode only when plugged in and full, battery mode otherwise (including while charging)
  tlpMode = pkgs.writeShellScript "tlp-mode" ''
    bat=$(echo /sys/class/power_supply/BAT*)
    read -r cap < $bat/capacity
    read -r status < $bat/status
    read -r cur 2>/dev/null < /run/tlp/manual_mode
    case "$status" in
      Full|"Not charging") mode=ac pp=0 ;;
      # stay ac while topping off at 99% so it doesnt flap
      Charging|Unknown) [ "$cap" -ge 100 ] || [ "$cur" = 0 ] && mode=ac pp=0 || mode=bat pp=1 ;;
      *) mode=bat pp=1 ;;
    esac
    # skip if tlp already holds this mode, battery emits change events every ~1%
    [ "$cur" = "$pp" ] && exit 0
    exec ${pkgs.tlp}/bin/tlp $mode
  '';
in {
  imports = [ ./desktop.nix ];
  home-manager.users.${config.borealis.user}.imports = [ ../home-manager/laptop.nix ];

  boot.initrd = {
    includeDefaultModules = false;
    compressor = "zstd";
    compressorArgs = [ "-19" "-T0" ];
  };

  environment.persistence."/persist".directories = [
    "/var/lib/upower"
    "/var/lib/bluetooth" # bt paired devices
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Don't start bluetooth until its needed
    settings.General = {
      Experimental = true; # battery reporting
      FastConnectable = true;
    };
    settings.Policy = {
      ReconnectAttempts = 7;
      ReconnectIntervals = "1,2,4,8,16,32,64";
    };
  };

  systemd.sleep.settings.Sleep = { # hibernation is broken on laptops
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };
  systemd.network.wait-online.enable = false; # nothing here needs network-online
  systemd.services.tlp.serviceConfig.ExecStartPost = "${tlpMode}"; # no udev event if already full at boot

  services = {
    # only power button & lid can wake from sleep
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/wakeup}="disabled"
      ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x060400", ATTR{power/wakeup}="disabled"

      # runs after tlp's own 85-tlp.rules
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="${tlpMode}"
    '';

    upower.enable = true; # battery level for the flurry shell

    tlp = { # Better battery life
      enable = true;
      settings = {
        TLP_PROFILE_DEFAULT = "BAL"; # bat profile until tlp-mode picks
        TLP_AUTO_SWITCH = 0; # tlp-mode sets manual mode, auto/resume keep it

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_BAT = "low-power";
        PCIE_ASPM_ON_BAT = "powersupersave";
        RUNTIME_PM_ON_BAT = "auto";
        WIFI_PWR_ON_BAT = "on";

        RADEON_DPM_PERF_LEVEL_ON_BAT = "auto"; # low drops frames
        AMDGPU_ABM_LEVEL_ON_BAT = 1;

        # causes crackling noises otherwise
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;
        SOUND_POWER_SAVE_CONTROLLER = "N";
      };
    };
  };
}
