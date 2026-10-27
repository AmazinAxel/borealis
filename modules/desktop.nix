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
  imports = [
    ./tmpfs-root.nix
    ./home-manager.nix
  ];

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
      libnotify # Astal internal notifications
      mpc
      screenshot # Freeze-then-select region screenshot (defined above)
      brightnessctl
      adwaita-icon-theme # Icons for GTK apps
      playerctl # mpris control from shell
      pass # password management
      xdg-terminal-exec # open in terminals
      wl-clipboard # wl paste for some apps

      # Desktop applications
      gthumb
      video-trimmer
      nemo-with-extensions
      nemo-fileroller
      file-roller
      discord
      filezilla
      libreoffice
      thunderbird
      iotas
      bun

      # Scripts
      (writeShellScriptBin "pass-sync" ''
        pass git pull --rebase && if [ "$(pass git rev-list '@{u}..HEAD' --count)" -gt 0 ]; then pass git push; fi
      '')
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/systemd" # backlight
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
          ".config/discord"
          ".config/Slack"
          ".config/filezilla"
          ".config/libreoffice"
          ".thunderbird"
          ".bun"
          ".config/valent"
          ".local/share/iotas"
          ".local/share/PrismLauncher"
          ".claude/projects" # transcripts, memory
          ".config/zen"
          ".config/spotify"
          ".cache/spotify"
          ".local/share/mpd"
          ".config/Code"
          ".vscode-shared" # logins and recents
          ".vscode" # password store
          ".local/share/ags-sideview"
          ".cache/ags-sideview"

          # GPU cache
          ".cache/mesa_shader_cache"
          ".cache/mesa_shader_cache_db"
          ".cache/radv_builtin_shaders"
          ".cache/qtshadercache-x86_64-little_endian-lp64"
        ];
        files = [
          ".claude.json" # claude login
          ".claude/.credentials.json"
          ".claude/history.jsonl"
        ];
      };
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Electron apps still need this
      MOZ_DBUS_REMOTE = "1"; # fix zen screensharing
      NO_AT_BRIDGE = "1"; # suppress warnings
      GTK_A11Y = "none";
    };
    # etc."xdg/fcitx5/addon/cloudpinyin.conf".text = ''
    #   [Addon]
    #   Enabled=False
    # '';
  };


  systemd = {
    # coredump.settings.Coredump = { # if an app crashes dont keep it open
    #   Storage = "none";
    #   ProcessSizeMax = "0";
    # };
    tmpfiles.rules = [
      "Z /persist/home/${user}/Music - ${user} users - -" # music proper owner
      "R! /home/${user}/*/.Trash-* - - - - -" # wipe trash in each persisted folder on boot
    ];
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

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka # Programming
    wqy_zenhei # Chinese
  ];

  programs = {
    kdeconnect = {
      enable = true;
      package = pkgs.valent;
    };
    dconf.enable = true; # For hm
    nix-ld.enable = true; # For dynamic executables
    gpu-screen-recorder.enable = true; # Clipping & recording software
    fish.enable = true; # Managed by hm but need this for path
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  # Chinese input support
  # i18n.inputMethod = {
  #   enable = true;
  #   type = "fcitx5";
  #   fcitx5 = {
  #     addons = with pkgs; [ qt6Packages.fcitx5-chinese-addons fcitx5-nord ];
  #     waylandFrontend = true;

  #     settings = {
  #       inputMethod = {
  #         "Groups/0" = {
  #           Name = "Default";
  #           "Default Layout" = "us";
  #           DefaultIM = "pinyin";
  #         };
  #         "Groups/0/Items/0".Name = "keyboard-us";
  #         "Groups/0/Items/1".Name = "pinyin";
  #       };
  #       globalOptions."Hotkey/TriggerKeys"."0" = "Control+Super+space";

  #       addons = {
  #         clipboard.globalSection."TriggerKey" = ""; # Disable clipboard
  #         classicui.globalSection."Theme" = "Nord-Dark";
  #         pinyin.globalSection."FirstRun" = "False";
  #       };
  #     };
  #   };
  # };

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

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
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
    pam.services.astal-auth.nodelay = true; # handle our own delays
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
