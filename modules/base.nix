{ pkgs, lib, config, ... }: let
  inherit (config.borealis) user;
in {
  imports = [ ./options.nix ];

  users.users.${user} = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
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
        credential.helper = "store --file=${config.users.users.${user}.home}/.local/share/git/credentials";
        push.autoSetupRemote = true;
      };
    };
    fish.useBabelfish = true; # env scripts translated at build, no bash spawn per shell
    command-not-found.enable = false;
  };
  security.sudo.extraConfig = "Defaults lecture=never"; # lectures are on by default

  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault 100;
  };

  nixpkgs.config.allowUnfree = true;
  nix = {
    channel.enable = false; # we only use flakes
    optimise.automatic = true; # dedupe on a timer instead of slowing every build

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      download-buffer-size = 268435456; # 256 MiB
      trusted-users = [ user ]; # for remote deployments
      build-dir = "/nix/var/nix/builds"; # /tmp is tmpfs, too small for kernel builds

      # Binary caches
      extra-substituters = [
        "https://cache.lantian.pub/lantian" # cachyos kernel
        "https://cache.xinux.uz" # cachyos kernel (lantian attic mirror)
      ];
      extra-trusted-public-keys = [
        "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
        "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
      ];
    };
  };

  services = {
    openssh.settings = {
      PasswordAuthentication = false; # key auth only
      KbdInteractiveAuthentication = false;
    };

    journald.settings.Journal.SystemMaxUse = "20M";

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
  documentation = {
    enable = false;
    man.enable = false; # faster rebuilds, even if docs off
  };
  environment = {
    defaultPackages = lib.mkForce [];
    systemPackages = [ (pkgs.writeShellScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.sh)) ];
    persistence."/persist".enable = lib.mkDefault false; # apps add paths, tmpfs-root hosts enable it
  };

  system.stateVersion = lib.mkDefault "24.05";
}
