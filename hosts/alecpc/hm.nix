{ lib, ... }: {
  wayland.windowManager.sway = {
    extraOptions = [ "--unsupported-gpu" ];
    config = {
      output = {
        "DP-1".position = "1920 0";
        "HDMI-A-1" = {
          resolution = "1920x1080@60Hz";
          position = "0 0";
        };
      };

      workspaceOutputAssign = map (n: {
        workspace = toString n;
        output = if n <= 3 then "HDMI-A-1" else "DP-1";
      }) (lib.range 1 9);

      startup = [
        { command = ''swaymsg "workspace 1; exec discord"''; }
      ];
    };

    extraSessionCommands = ''
      export LIBVA_DRIVER_NAME=nvidia
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NVD_BACKEND=direct
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };
}
