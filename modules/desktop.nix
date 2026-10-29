{ borealis, pkgs, lib, config, ... }: let
  inherit (config.borealis) user;
  screenshot = pkgs.writeShellScriptBin "screenshot" ''
    ${pkgs.wayfreeze}/bin/wayfreeze --hide-cursor --after-freeze-cmd '
      geom=$(${pkgs.slurp}/bin/slurp) &&
        ${pkgs.grim}/bin/grim -g "$geom" - |
          ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
      ${pkgs.procps}/bin/pkill wayfreeze
    '
  '';
in {
  imports = [ ./tmpfs-root.nix ];

  # Cachy kernel
  nixpkgs.overlays = [ borealis.nix-cachyos-kernel.overlays.pinned ];

  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    bcache.enable = false; # dont need
    initrd.systemd.tpm2.enable = false; # no TPM unlock! dont need

    loader.efi.canTouchEfiVariables = true;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 2;
    };
  };

  home-manager = {
    users.${user}.imports = [ ../home-manager/home.nix ];
    backupFileExtension = "backup2";
  };
  users.users.${user}.shell = pkgs.fish; # default shell for ssh and foot

  xdg.sounds.enable = false; # don't need
  system.tools = { # don't need
    nixos-generate-config.enable = false;
    nixos-install.enable = false;
    nixos-enter.enable = false;
    nixos-option.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      # Desktop services
      libnotify # Flurry internal notifications
      mpc
      screenshot # Freeze-then-select region screenshot (defined above)
      brightnessctl
      playerctl # mpris control from shell
      pass # password management
      xdg-terminal-exec # open in terminals
      wl-clipboard # wl paste for some apps

      # Desktop applications
      gthumb
      nemo-with-extensions
      nemo-fileroller
      file-roller
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/rfkill" # wifi/bt soft block
        "/var/lib/systemd/timers" # persistent timer stamps
        "/var/lib/sbctl" # secure boot keys
      ];
      users.${user} = {
        directories = [
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"
          "Wallpapers"
          "Projects"

          # keys
          ".ssh"
          ".gnupg"
          ".password-store"

          # apps
          ".local/share/fish" # shell history
          ".local/share/mpd"
          ".local/share/flurry-sideview"
        ] ++ lib.optionals (!lib.elem "nvidia" config.services.xserver.videoDrivers) [ # GPU cache
          ".cache/mesa_shader_cache"
          ".cache/mesa_shader_cache_db"
        ];
      };
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Electron apps still need this
      NO_AT_BRIDGE = "1"; # suppress warnings
      GTK_A11Y = "none";
    };
  };

  systemd = {
    tmpfiles.rules = [ "R! /home/${user}/*/.Trash-* - - - - -" ]; # wipe trash in each persisted folder on boot
    sleep.settings.Sleep.HibernateMode = "platform"; # ONLY POWER BUTTON FOR UNHIBERNATION
    oomd.enable = false; # earlyoom already handles OOM
    tpm2.enable = false; # no TPM unlock, faster boot!
    services.systemd-boot-random-seed.enable = false; # faster boot
    services.greetd.serviceConfig.Type = lib.mkForce "simple"; # faster boot

    # we don't want these running
    user.services = lib.genAttrs [
      "gvfs-afc-volume-monitor"
      "gvfs-goa-volume-monitor"
      "gvfs-gphoto2-volume-monitor"
      "gvfs-mtp-volume-monitor"
    ] (_: { enable = false; });
  };

  fonts.packages = [ pkgs.nerd-fonts.iosevka ]; # Programming

  programs = {
    dconf.enable = true; # For hm
    gpu-screen-recorder.enable = true; # Clipping & recording software
    fish.enable = true; # Managed by hm but need this for path
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  console.colors = with import ../nord.nix; [ # TTY
    "000000" # black (background)
    nord11 # red
    nord14 # green
    nord13 # yellow
    nord9 # blue
    nord15 # magenta
    nord8 # cyan
    nord5 # white
    nord3 # bright black
    nord11 # bright red
    nord14 # bright green
    nord13 # bright yellow
    nord9 # bright blue
    nord15 # bright magenta
    nord7 # bright cyan
    nord6 # bright white
  ];

  services = {
    gvfs.enable = true; # Samba shares in nemo
    logrotate.enable = false; # no logs
    logind.settings.Login.HandlePowerKey = "ignore"; # Don't turn off computer on power key press

    # Prevent crashes
    earlyoom = {
       enable = true;
       freeMemThreshold = 10; # 10%
    };
    speechd.enable = false; # unused TTS daemon, browsers spawn it
    scx = { # sched_ext scheduler that favors interactive tasks
      enable = true;
      scheduler = "scx_lavd";
    };

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    greetd = { # Autologin
      enable = true;
      settings.default_session = {
        command = "fish -lc 'exec sway'";
        inherit user;
      };
    };
  };

  security = {
    rtkit.enable = true; # better audio latency
    pam.services.flurry-auth.nodelay = true; # handle our own delays
  };

  hardware.graphics.enable = true; # this isn't set by sway hm by default for some reason?

  # Since we dont use the sway nix module we have to set the portal explicitly for things like flatpak and screensharing to work
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = { # needed for now
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = [ "gtk" "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    };
  };
}
