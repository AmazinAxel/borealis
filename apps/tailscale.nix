{ lib, config, ... }: let
  cfg = config.services.tailscale;
  userspace = cfg.interfaceName == "userspace-networking"; # tailnet ssh arrives from loopback
in {
  services.tailscale = {
    enable = true;
    openFirewall = true; # wireguard udp only
    disableUpstreamLogging = true;
    extraSetFlags = [
      "--update-check=false"
      "--netfilter-mode=off" # tailscale's own rules accept everything from the tailnet; the NixOS firewall decides instead
    ];
  };

  # ssh only over the tailnet: firewall, and sshd itself for hosts without a firewall
  services.openssh = {
    openFirewall = false;
    settings.AllowUsers = map (from: "${config.borealis.user}@${from}")
      ([ "100.64.0.0/10" "fd7a:115c:a1e0::/48" ] ++ lib.optionals userspace [ "127.0.0.1" "::1" ]);
  };
  networking.firewall.interfaces.${cfg.interfaceName}.allowedTCPPorts =
    lib.mkIf config.services.openssh.enable config.services.openssh.ports;

  systemd.services.tailscaled = {
    environment = {
      TS_DEBUG_FIREWALL_MODE = "nftables"; # skip iptables detection
      TS_DISABLE_FEATURE = lib.concatStringsSep "," [
        "ace" "appconnectors" "aws" "bird" "capture" "clientupdate" "connreject"
        "debugportmapper" "doctor" "drive" "favorites" "identityfederation" "kube"
        "netlog" "oauthkey" "portlist" "posture" "relayserver" "remoteconfig" "routecheck"
        "runtimemetrics" "serviceclientprefs" "ssh" "syslog" "syspolicy" "taildrop"
        "tailnetlock" "tap" "tpm" "tundevstats" "wakeonlan"
      ];
    };
    serviceConfig = { # stop logs
      StandardOutput = "null";
      StandardError = "null";
    };
  };
  environment.persistence."/persist".directories = [ "/var/lib/tailscale" ];
}
