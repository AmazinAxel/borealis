{ pkgs, lib, ... }: {
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

      colors = with lib.mapAttrs (_: v: "#${v}") (import ../../nord.nix); {
        focused = { # focused window
          background = nord10;
          border = nord10;
          childBorder = nord10;
          indicator = nord10;
          text = nord6;
        };

        focusedInactive = {
          background = nord10;
          border = nord10;
          childBorder = nord10;
          indicator = nord10;
          text = nord5;
        };

        placeholder = {
          background = nord0;
          border = nord3;
          childBorder = nord3;
          indicator = nord0;
          text = nord5;
        };

        unfocused = {
          background = nord0;
          border = nord3;
          childBorder = nord3;
          indicator = nord0;
          text = nord4;
        };

        urgent = {
          background = nord11;
          border = nord12;
          childBorder = nord12;
          indicator = nord3;
          text = nord6;
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
          { app_id = "xdg-desktop-portal-gtk"; } # file chooser from an app
        ];
      };

      floating = {
        border = 3;
        titlebar = false;
      };

      startup = [
        { command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_DATA_DIRS PATH"; }
        # { command = "fcitx5 -d"; }
        { command = "wl-gammarelay-rs & ${pkgs.glib}/bin/gdbus wait --session rs.wl-gammarelay && busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 3500"; } # blue light filter
      ];
    };
    extraConfig = ''
      primary_selection disabled
      swaybg_command -
    '';
  };
}
