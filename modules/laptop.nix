{ pkgs, ... }: {
  services = {
    # only power button & lid can wake from sleep
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/wakeup}="disabled"
      ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x060400", ATTR{power/wakeup}="disabled"

      # battery mode while charging, AC mode only once full
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{capacity}=="100", ATTR{status}!="Discharging", RUN+="${pkgs.tlp}/bin/tlp ac"
    '';

    upower.enable = true; # battery level for the astal shell

    tlp = { # Better battery life
      enable = true;
      settings = {
        TLP_DEFAULT_MODE = "BAT";
        TLP_PERSISTENT_DEFAULT = 1;

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_BAT = "low-power";
        PCIE_ASPM_ON_BAT = "powersupersave";
        RUNTIME_PM_ON_BAT = "auto";
        WIFI_PWR_ON_BAT = "on";

        RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
        AMDGPU_ABM_LEVEL_ON_BAT = 1;

        # causes crackling noises otherwise
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;
        SOUND_POWER_SAVE_CONTROLLER = "N";
      };
    };
  };
}
