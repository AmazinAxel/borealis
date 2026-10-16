{ pkgs, ... }: {
  # Printing with CUPS
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplip
      pkgs.mfcj880dwlpr pkgs.mfcj880dwcupswrapper pkgs.mfcj470dw-cupswrapper pkgs.mfcj470dwlpr ]; # HP + Brother MFC inkjet
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
    };

    avahi.publish = {
      enable = true;
      addresses = true; # for .local
      userServices = true; # CUPS queues
    };
  };
}
