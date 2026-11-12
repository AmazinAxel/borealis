{ pkgs, lib, ... }: let
  # never loaded: old or rare protocols and filesystems, a common source of kernel bugs
  unused = [
    "dccp" "sctp" "rds" "tipc" "n-hdlc" "ax25" "netrom" "x25" "rose" "decnet" "econet" "af_802154" "ipx" "appletalk"
    "psnap" "p8023" "p8022" "can" "atm"
    "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "udf"
    "firewire-core" "firewire-ohci" "firewire-sbp2"
  ];
in {
  # Every host: hardening that costs nothing and breaks no desktop use. Servers add more in headless.nix.
  # Left out on purpose: the hardened kernel, init_on_alloc/free and hardened malloc (slower), lockdown (blocks
  # unsigned modules, NixOS modules are unsigned) and modules_disabled (breaks on-demand nftables/veth/tun modules).
  boot = {
    extraModprobeConfig = lib.concatMapStrings (m: "install ${m} ${pkgs.coreutils}/bin/false\n") unused;

    kernel.sysctl = lib.mapAttrs (_: lib.mkOverride 900) { # above nixpkgs mkDefaults, below plain host values
      "kernel.kptr_restrict" = 2; # hide kernel pointers
      "kernel.dmesg_restrict" = 1;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.sysrq" = 0;
      "dev.tty.ldisc_autoload" = 0;
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      # no ICMP redirects (source routing, syncookies, bogus ICMP already kernel defaults)
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.tcp_rfc1337" = 1;
    };
  };

  # memory-safe sudo, only runnable by wheel
  security.sudo.enable = false;
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

  # crashes leave no dumps (they can hold secrets)
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };
  security.pam.loginLimits = [{ domain = "*"; item = "core"; type = "hard"; value = "0"; }];

  nix.settings.allowed-users = lib.mkDefault [ "@wheel" ]; # root is always allowed

  services.openssh.settings = lib.mapAttrs (_: lib.mkDefault) {
    PasswordAuthentication = false; # key auth only
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    AuthenticationMethods = "publickey";
    MaxAuthTries = 3;
    LoginGraceTime = 20;
    AllowAgentForwarding = false;
    AllowTcpForwarding = false;
    AllowStreamLocalForwarding = false;
  };

  networking.firewall.logRefusedConnections = lib.mkDefault false; # floods would fill the journal
}
