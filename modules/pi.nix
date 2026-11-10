{ pkgs, ... }: {
  imports = [ ./arm.nix ];

  boot.extraModprobeConfig = "options brcmfmac roamoff=1 feature_disable=0x82000"; # help with wifi drops

  networking.wireless.iwd.settings.DriverQuirks = {
    DefaultInterface = "brcmfmac"; # don't recreate wlan0
    PowerSaveDisable = "brcmfmac"; # stops network drops
  };

  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ]; # needed for wifi to work
  systemd.tmpfiles.rules = [ "w /sys/class/leds/ACT/trigger - - - - none" ]; # no activity LED
}
