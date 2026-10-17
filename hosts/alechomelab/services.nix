{ pkgs, inputs, ... }:

let
  service = { # basic service config
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
  privileges = { # Fix webserver stuff
    NoNewPrivileges = false;
    PrivateUsers = false;
  };
in {
  systemd = {
    services = {
      # /etc/homelab/webserver.env with AIRNOW_TOKEN=
      webserver = service // {
        path = [ pkgs.util-linux ];
        serviceConfig = service.serviceConfig // privileges // {
          EnvironmentFile = "/etc/homelab/webserver.env";
          ExecStart = "${pkgs.bun}/bin/bun ${./webserver}/webserver.js";
          MemoryMin = "32M"; # resident
        };
      };
      homelabDisplay = service // {
        serviceConfig = service.serviceConfig // privileges // {
          ExecStart = "${inputs.homelab.packages.aarch64-linux.homelabDisplay}/bin/homelabDisplay";
          MemoryMin = "8M";
        };
      };
      daily = {
        path = with pkgs; [ util-linux curl jq fish git ];
        script = ''
          fish ${./scripts}/githubBackup.fish
          date +%s > /home/alec/lastSynced
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "alec";
          Group = "users";
          MemoryHigh = "190M";
          MemoryMax = "240M"; # ceiling
          MemorySwapMax = "200M"; # prefer fast zram off usb swap
          ManagedOOMMemoryPressure = "kill";
          OOMScoreAdjust = 1000;
          IOSchedulingClass = "idle";
          IOWeight = 10;
          IOReadBandwidthMax = "/media 24M";
          IOWriteBandwidthMax = "/media 10M";
          IOReadIOPSMax = "/media 1200";
          IOWriteIOPSMax = "/media 600";
          CPUWeight = 10;
          CPUQuota = "200%";
          Nice = 19;
          # RuntimeMaxSec = "2h";
          TimeoutStopSec = "1m";
        };
      };
    };

    services.sshd.serviceConfig = {
      OOMScoreAdjust = -900; # NEVER OOM SSH
      MemoryMin = "16M";
    };

    timers."daily" = { # Every morning at 3AM PT
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        RandomizedDelaySec = "5m";
      };
    };
  };
}
