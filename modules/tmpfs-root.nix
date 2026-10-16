{ ... }: {
  imports = [ ./impermanence.nix ];

  # sudo install -Dm600 <(grep '^alec:' /etc/shadow | cut -d: -f2) /passwords/alec
  # maybe install to /persist/passwords/alec
  users = {
    users.alec.hashedPasswordFile = "/persist/passwords/alec";
    mutableUsers = false;
  };

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=4G" "mode=755" ];
  };
  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" "x-initrd.mount" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };
}
