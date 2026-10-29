{ lib, ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    disableUpstreamLogging = true;
    extraSetFlags = [ "--update-check=false" "--auto-update=false" "--webclient=false" ];
  };

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
