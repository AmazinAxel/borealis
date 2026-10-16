{ pkgs, config, ... }: {
  services.swayidle = { # lock before suspend on laptop lid close
    enable = true;
    events.before-sleep = "${config.home.profileDirectory}/bin/ags request lock; ${pkgs.coreutils}/bin/sleep 1";
  };

  wayland.windowManager.sway = {
    enable = true;
    systemd.dbusImplementation = "broker"; # this needs to match the new nixos default
    wrapperFeatures.gtk = true;

    config = {
      modifier = "Mod4"; # Super
      bars = []; # No default ugly sway bar
      gaps.inner = 5;

      focus = {
        newWindow = "focus";
        followMouse = "always"; # "yes"
      };

      workspaceAutoBackAndForth = true;

      input = {
        "*".xkb_variant = "nodeadkeys";
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "-0.1";
        };
        "type:touchpad" = {
          tap = "enabled";
          drag_lock = "disable";
          dwt = "disabled"; # disabled while typing
        };
        "type:keyboard" = {
          repeat_delay = "300";
          repeat_rate = "30";
          xkb_options = "caps:none";
        };
      };

      colors = let # Color vars
        dark0 = "#2e3440";
        dark4 = "#4c566a";
        white0 = "#d8dee9";
        white1 = "#e5e9f0";
        white2 = "#eceff4";

        blue0 = "#5e81ac";
        blue1 = "#81a1c1";
        blue2 = "#88c0d0";
        blue3 = "#8fbcbb";

        purple = "#b48ead";
        green = "#a3be8c";
        yellow = "#ebcb8b";
        orange = "#d08770";
        red = "#bf616a";
      in {
        focused = { # focused window
          background = blue0;
          border = blue0;
          childBorder = blue0;
          indicator = blue0;
          text = white2;
        };

        focusedInactive = {
          background = blue0;
          border = blue0;
          childBorder = blue0;
          indicator = blue0;
          text = white1;
        };

        placeholder = {
          background = dark0;
          border = dark4;
          childBorder = dark4;
          indicator = dark0;
          text = white1;
        };

        unfocused = {
          background = dark0;
          border = dark4;
          childBorder = dark4;
          indicator = dark0;
          text = white0;
        };

        urgent = {
          background = red;
          border = orange;
          childBorder = orange;
          indicator = dark4;
          text = white2;
        };
      };

      window = {
        titlebar = false;
        border = 3;
        commands = map (criteria: { inherit criteria; command = "floating enable"; }) [
          { app_id = "nemo"; } # file browser
          { app_id = "foot-float"; } # terminal
          { app_id = "org.gnome.FileRoller"; } # file extraction dialogs
          { app_id = "org.gnome.SystemMonitor"; }
          { app_id = "org.gnome.gThumb"; } # image viewer
          { app_id = "zen-beta"; title = ".*PassFF.*"; } # PassFF popup
          { app_id = "PrismLauncher"; } # Minecraft launcher
          { app_id = "org.kde.kdeconnect.daemon"; }
          { app_id = "xdg-desktop-portal-gtk"; } # file chooser from an app
        ];
      };

      floating = {
        border = 3;
        titlebar = false;
      };

      startup = [
        { command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_DATA_DIRS PATH"; }
        { command = "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' && gsettings set org.gnome.desktop.interface gtk-theme 'Graphite-Dark-nord'"; } # dark mode on boot
        { command = "fcitx5 -d"; }
        { command = "wl-gammarelay-rs"; }
        { command = "sleep 1 && busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 3500"; }
      ];
    };
    # Disable middle mouse paste
    extraConfig = "primary_selection disabled";
  };
}
