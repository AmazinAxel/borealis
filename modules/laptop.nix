{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    flashprint
    aseprite
    (symlinkJoin {
      name = "kicad"; paths = [ kicad ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })
    openjdk25
  ];

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/upower"
      "/var/lib/bluetooth" # bt paired devices
    ];
    users.alec.directories = [
      ".config/kicad"
      ".local/share/kicad"
      ".FlashPrint5" # FlashPrint slicer
      ".config/aseprite"
      ".platformio" # dont break builds
    ];
  };

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

  # logs drain per suspend; on battery wakes hourly and powers off at 10% so it never dies asleep
  systemd.services.sleep-guard = {
    wantedBy = [ "suspend.target" ];
    before = [ "systemd-suspend.service" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    script = ''
      bat=$(echo /sys/class/power_supply/BAT*)
      rtc=$(dirname $(echo /sys/class/rtc/*/wakealarm | cut -d' ' -f1))
      armed=0
      echo 0 > $rtc/wakealarm
      [ "$(cat $bat/status)" = Discharging ] && echo +3600 > $rtc/wakealarm && armed=1
      echo "$(date +%s) $(cat $bat/charge_now) $(cat /sys/power/suspend_stats/total_hw_sleep) $armed" > /run/sleep-guard
    '';
    preStop = ''
      bat=$(echo /sys/class/power_supply/BAT*)
      rtc=$(dirname $(echo /sys/class/rtc/*/wakealarm | cut -d' ' -f1))
      read t0 c0 h0 armed < /run/sleep-guard
      dt=$(( $(date +%s) - t0 ))
      [ $dt -gt 0 ] || dt=1
      hw=$(( ($(cat /sys/power/suspend_stats/total_hw_sleep) - h0) / 10000 / dt ))
      mah=$(( (c0 - $(cat $bat/charge_now)) / 1000 ))
      echo "slept ''${dt}s, ''${hw}% in hardware sleep, drained ''${mah}mAh ($(( mah * 3600 / dt ))mA avg), now $(cat $bat/capacity)%"
      fired=0 # alarm went off rather than lid/power key
      [ $armed = 1 ] && [ -z "$(cat $rtc/wakealarm)" ] && [ $dt -ge 3590 ] && [ $dt -le 3700 ] && fired=1
      echo 0 > $rtc/wakealarm
      if [ $fired = 1 ]; then
        if [ "$(cat $bat/capacity)" -le 10 ]; then systemd-run --on-active=5 systemctl poweroff
        else systemd-run --on-active=5 systemctl suspend; fi
      fi
    '';
  };

  services = {
    udev = {
      packages = [ pkgs.platformio-core.udev ];
      # only power button & lid can wake from sleep
      extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/wakeup}="disabled"
        ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x060400", ATTR{power/wakeup}="disabled"

        # battery mode while charging, AC mode only once full
        ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT0", ATTR{capacity}=="100", ATTR{status}!="Discharging", RUN+="${pkgs.tlp}/bin/tlp ac"

        # Pi Pico
        SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"

        # WCH CH32X035
        SUBSYSTEM=="usb", ATTR{idVendor}=="4348", ATTR{idProduct}=="55e0", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55e0", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8010", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8012", MODE="0666"
      '';
    };

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
