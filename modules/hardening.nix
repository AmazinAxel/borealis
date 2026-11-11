{ pkgs, lib, ... }: let
  # never loaded: old or rare protocols and filesystems, a common source of kernel bugs
  unused = [
    "dccp" "sctp" "rds" "tipc" "n-hdlc" "ax25" "netrom" "x25" "rose" "decnet" "econet" "af_802154" "ipx" "appletalk"
    "psnap" "p8023" "p8022" "can" "atm"
    "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "udf"
    "firewire-core" "firewire-ohci" "firewire-sbp2"
  ];
in {
  # Server hardening with no measurable speed cost; everything is mkDefault so hosts can override.
  # Left out on purpose: the hardened kernel, init_on_alloc/free and hardened malloc (slower), lockdown (blocks
  # unsigned modules, NixOS modules are unsigned) and modules_disabled (breaks on-demand nftables/veth/tun modules).
  boot = {
    kernelParams = [
      "slab_nomerge" # heap overflows can't spill into other caches
      "randomize_kstack_offset=on"
      "page_alloc.shuffle=1"
      "debugfs=off"
    ] ++ lib.optional pkgs.stdenv.hostPlatform.isx86_64 "vsyscall=none";

    extraModprobeConfig = lib.concatMapStrings (m: "install ${m} ${pkgs.coreutils}/bin/false\n") unused;

    kernel.sysctl = lib.mapAttrs (_: lib.mkOverride 900) { # above nixpkgs mkDefaults, below plain host values
      "kernel.kptr_restrict" = 2; # hide kernel pointers
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.yama.ptrace_scope" = 2; # only root can ptrace
      "kernel.perf_event_paranoid" = 3;
      "kernel.sysrq" = 0;
      "kernel.io_uring_disabled" = 2; # large attack surface, nothing here uses it
      "vm.unprivileged_userfaultfd" = 0;
      "dev.tty.ldisc_autoload" = 0;
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      # no ICMP redirects or source routing
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.tcp_syncookies" = 1; # SYN floods
    };

    loader.systemd-boot.editor = lib.mkDefault false; # no init=/bin/sh from the boot menu
  };

  security = {
    protectKernelImage = lib.mkDefault true; # no kexec or hibernation
    sudo.execWheelOnly = lib.mkDefault true;
  };

  # crashes leave no dumps (they can hold secrets)
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };
  security.pam.loginLimits = [{ domain = "*"; item = "core"; type = "hard"; value = "0"; }];

  nix.settings.allowed-users = lib.mkDefault [ "@wheel" ]; # root is always allowed

  services = {
    dbus.implementation = lib.mkDefault "broker"; # faster, smaller
    openssh.settings = lib.mapAttrs (_: lib.mkDefault) {
      PermitRootLogin = "no";
      AuthenticationMethods = "publickey";
      MaxAuthTries = 3;
      LoginGraceTime = 20;
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      AllowStreamLocalForwarding = false;
    };
  };

  networking.firewall.logRefusedConnections = lib.mkDefault false; # floods would fill the journal
}
