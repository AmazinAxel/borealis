{ pkgs, ... }: {
  imports = [ ./arm.nix ./headless.nix ];

  boot = {
    extraModprobeConfig = "options brcmfmac roamoff=1 feature_disable=0x82000"; # help with wifi drops
    blacklistedKernelModules = [ "snd_bcm2835" "btbcm" "hci_uart" "bluetooth" ]; # no audio or bluetooth
  };

  networking.wireless.iwd.settings.DriverQuirks = {
    DefaultInterface = "brcmfmac"; # don't recreate wlan0
    PowerSaveDisable = "brcmfmac"; # stops network drops
  };

  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ]; # needed for wifi to work
  systemd.tmpfiles.rules = [ # LEDs off, PWR only exists on some boards
    "w- /sys/class/leds/ACT/trigger - - - - none"
    "w- /sys/class/leds/PWR/trigger - - - - none"
  ];
}
