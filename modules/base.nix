{ pkgs, lib, config, ... }: let
  inherit (config.borealis) user;
in {
  imports = [ ./options.nix ./hardening.nix ];

  # Perlless (from nixpkgs profiles/perlless.nix): users and /etc without the perl activation scripts
  system = {
    etc.overlay.enable = lib.mkDefault true;
    tools = lib.genAttrs [ "nixos-generate-config" "nixos-install" "nixos-enter" "nixos-option" "nixos-build-vms" ]
      (_: { enable = lib.mkDefault false; }); # never install from here, nixos-generate-config pulls perl
  };
  services.userborn.enable = lib.mkDefault true;
  boot.loader.grub.enable = lib.mkDefault false;
  boot.kexec.enable = false; # unused, servers block kexec_load anyway
  boot.bcache.enable = false;
  xdg.sounds.enable = false;
  programs.nano.enable = false; # helix on desktops

  users.users.${user} = { # Default user
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
    # Only applies when the account is first created; set the real password with `passwd` (see tmpfs-root.nix)
    initialPassword = "nixos";
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
        credential.helper = "store --file=${config.users.users.${user}.home}/.local/share/git/credentials";
        push.autoSetupRemote = true;
      };
    };
    fish = {
      enable = true;
      useBabelfish = true; # env scripts translated at build, no bash spawn per shell
    };
  };
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ]; # glibc-locales: ~3M, not 223M

  zramSwap = {
    enable = lib.mkDefault true;
    memoryPercent = lib.mkDefault 100;
  };
  # nixpkgs builds it against pkgs.systemd, but the system runs a patched systemd.package: a second 68M systemd.
  # Copy the cached build and repoint it (same-length store paths, binary safe). No recompile.
  services.zram-generator.package = let zg = pkgs.zram-generator; in pkgs.runCommand zg.name {
    inherit (zg) passthru meta;
    disallowedReferences = [ pkgs.systemd ];
  } ''
    cp -r --no-preserve=ownership ${zg} $out
    chmod -R u+w $out
    find $out -type f -exec sed -i 's|${zg}|'$out'|g; s|${pkgs.systemd}|${config.systemd.package}|g' {} +
  '';

  nixpkgs.config.allowUnfree = true;
  nix = {
    channel.enable = false; # we only use flakes

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      download-buffer-size = 268435456; # 256 MiB
      trusted-users = [ user ]; # for remote deployments
      build-dir = "/nix/var/nix/builds"; # /tmp is tmpfs, too small for kernel builds
    };
  };

  services = {
    journald.settings.Journal.SystemMaxUse = "20M";
    logrotate.enable = lib.mkDefault false; # journald only, no log files

    resolved = {
      enable = true;
      settings.Resolve = {
        MulticastDNS = "no"; # hosts resolve via tailscale MagicDNS
        LLMNR = "no";
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com";
        FallbackDNS = ""; # no plaintext fallback servers
        DNSOverTLS = "opportunistic"; # strict breaks captive portal wifi logins
        Domains = "~."; # override DHCP-provided DNS (ISP)
      };
    };
  };
  fileSystems."/".options = [ "noatime" ];
  documentation = {
    enable = false;
    man.enable = false; # faster rebuilds, even if docs off
    info.enable = false;
    nixos.enable = false;
  };
  environment = {
    defaultPackages = lib.mkForce [];
    systemPackages = [ (pkgs.writeShellScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.sh)) ];
    persistence."/persist".enable = lib.mkDefault false; # apps add paths, tmpfs-root hosts enable it
  };

  system.stateVersion = lib.mkDefault "24.05";
}
