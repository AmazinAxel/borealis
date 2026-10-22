{ pkgs, lib, config, ... }: {
  users.users.alec = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNtO18H89dHbyP658hIDMeFZrjdWNUbWrdcL6URrthh alec" ];
  };

  boot = {
    loader.timeout = lib.mkForce 0; # Hold down space on boot to access
    tmp.useTmpfs = true;
    kernelParams = [ "nowatchdog" "nmi_watchdog=0" ];
    blacklistedKernelModules = [ "sp5100_tco" ]; # speeds up shutdown on amd stop since it doesnt wait for watchdog
    kernelModules = [ "tcp_bbr" ];

    # faster networking
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq"; # goes with BBR
      "net.ipv4.tcp_fastopen" = 3; # saves a round-trip
      "net.ipv4.tcp_slow_start_after_idle" = 0; # don't reset cwnd after idle
      "net.ipv4.tcp_mtu_probing" = 1; # reduces fragmentation
      "net.ipv4.tcp_notsent_lowat" = 16384; # reduce latency

      "vm.dirty_writeback_centisecs" = 6000; # batch disk writes

    # zram is enabled on a lot of hosts, this optimizes it
    } // lib.optionalAttrs config.zramSwap.enable {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
  };

  networking = {
    nftables.enable = true; # native firewall, no iptables compat layer
    useNetworkd = lib.mkDefault true; # newer
    wireless.iwd = {
      enable = lib.mkDefault true;
      settings.Scan = { # periodic scans only run while disconnected
        InitialPeriodicScanInterval = 10;
        MaximumPeriodicScanInterval = 300; # low value caused roam flapping between mesh APs
      };
    };
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
  systemd.network = {
    networks."20-default" = {
      matchConfig.Type = "ether wlan";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IgnoreCarrierLoss = "5s"; # tolerate short wifi drops
      };
      dhcpV4Config.UseMTU = true; # avoid fragmentation
    };
    wait-online = {
      timeout = 10; # Dont prolong boot for too long
      extraArgs = [ "--operational-state=routable" ];
    };
  };

  programs = {
    git = {
      enable = true;
      package = pkgs.gitMinimal;
      config = {
        init.defaultBranch = "main";
        color.ui = true;
        core.editor = "hx";
        credential.helper = "store --file=/home/alec/.local/share/git/credentials";
        github.user = "AmazinAxel"; # Github
        user.name = "AmazinAxel"; # Git
        user.email = "87440159+AmazinAxel@users.noreply.github.com";
        push.autoSetupRemote = true;
      };
    };
    command-not-found.enable = false;
    nano.enable = false; # use Helix
  };
  security.sudo.extraConfig = "Defaults lecture=never"; # lectures are on by default

  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault 100;
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    channel.enable = false; # we only use flakes

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
      download-buffer-size = 268435456; # 256 MiB
      trusted-users = [ "alec" ]; # for remote deployments

      # Binary caches
      extra-substituters = [
        "https://cache.xinux.uz" # cachyos kernel (lantian attic mirror)
        "https://helix.cachix.org" # helix
      ];
      extra-trusted-public-keys = [
        "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };

  services = {
    openssh.settings = {
      PasswordAuthentication = false; # key auth only
      KbdInteractiveAuthentication = false;
    };

    journald.settings.Journal.SystemMaxUse = "20M";
    tailscale = {
      enable = true;
      openFirewall = true;
      disableUpstreamLogging = true;
      extraSetFlags = [ "--update-check=false" "--auto-update=false" "--webclient=false" ];
    };

    resolved = {
      enable = true;
      settings.Resolve = {
        MulticastDNS = "no"; # hosts resolve via tailscale MagicDNS
        LLMNR = "no";
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com";
        DNSOverTLS = "opportunistic";
        Domains = "~."; # override DHCP-provided DNS (ISP)
      };
    };
  };
  fileSystems."/".options = [ "noatime" ];
  documentation.enable = false;
  documentation.man.enable = false; # faster rebuilds, even if docs off
  environment.defaultPackages = lib.mkForce [];
  environment.systemPackages = [ (pkgs.writeShellScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.sh)) ];

  system.stateVersion = lib.mkDefault "24.05";
}
