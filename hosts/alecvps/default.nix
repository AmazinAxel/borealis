{ modulesPath, pkgs, lib, ... }:
let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICh1nH79rMAd7qEySygClFNsnGRsHRabisFZCD7nKYEz axel@amazinaxel.com";
in {
  imports = [
    ../common.nix
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC = {
    privileged = false; # unprivileged container
    manageNetwork = false; # Proxmox handles network
    manageHostName = true; # keep networking.hostName
  };

  users.users.alec.initialPassword = "nixos"; # change with passwd
  networking.wireless.iwd.enable = false; # no wifi in a container
  zramSwap.enable = false; # cant use in proxmox
  services.tailscale.interfaceName = "userspace-networking"; # no /dev/net/tun in unprivileged LXC

  services = {
    fstrim.enable = false; # Proxmox handles this
    openssh = {
      openFirewall = true;
      # settings.PermitRootLogin = "prohibit-password";
      settings.AllowTcpForwarding = true; # VSC Remote-SSH support
      extraConfig = ''
        Match User alec
          PasswordAuthentication yes
      '';
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [ key ];
  users.users.alec.openssh.authorizedKeys.keys = [ key ]; # login key for fast access

  programs.nix-ld.enable = true; # for vsc

  # Nocturn player count tracker
  systemd.services.tracker = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.mcstatus ]; # server list pings
    serviceConfig = {
      ExecStart = "${pkgs.bun}/bin/bun ${./tracker}/tracker.js";
      StateDirectory = "nocturn-tracker"; # /var/lib/nocturn-tracker
      DynamicUser = true;
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ]; # port 80 as a dynamic user
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "always";
      RestartSec = 5;
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

  nix.settings.sandbox = false; # fix builds on the vps
  services.logrotate.checkConfig = false; # fix build error
  fileSystems = lib.mkForce {}; # no need for noatime
  nixpkgs.hostPlatform = "x86_64-linux";

  # Networking
  networking.hostName = "alecvps";
  systemd.network.networks."20-default".enable = false; # Proxmox has ethernet!
  system.stateVersion = "25.11";
}
