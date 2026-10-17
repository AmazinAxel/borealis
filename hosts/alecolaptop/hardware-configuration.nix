{
  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "i8042" "atkbd" "usbhid" "hid_generic" ]; # MUST include these modules for keyboard to work for LUKS
    kernelModules = [ "kvm-amd" ];
    initrd.luks.devices."cryptpersist" = {
      device = "/dev/disk/by-uuid/fd5a2a94-4459-4102-a07a-2ea504232b9d";
      allowDiscards = true;
      bypassWorkqueues = true;
      crypttabExtraOpts = [ "password-echo=no" ];
    };
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/cryptpersist";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6A47-9F78";
    fsType = "vfat";
    options = [ "fmask=0137" "dmask=0027" ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };
}
