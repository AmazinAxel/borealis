{
  imports = [ ../../home-manager/laptop.nix ../../home-manager/iotas.nix ];

  wayland.windowManager.sway.config = {
    output = {
      "HDMI-A-1" = { # main built in hdmi
        resolution = "1920x1080@144Hz";
        position = "0 0";
      };
      "DP-9" = { # main with adapter
        resolution = "1920x1080@144Hz";
        position = "0 0";
      };
      "*".position = "1920 0"; # Laptop/other monitors
      "DP-1" = {
        position = "3200 0"; # Right
        scale = "1.5";
      };
      "DP-7" = { # adapter
        position = "3200 0"; # Right
        scale = "1.5";
      };
    };

    startup = [
      { command = ''swaymsg "workspace 5; exec thunderbird"''; }
    ];

    workspaceOutputAssign = [
      { workspace = "1"; output = "HDMI-A-1"; }
      { workspace = "2"; output = "HDMI-A-1"; }
      { workspace = "3"; output = "HDMI-A-1"; }
      { workspace = "4"; output = "HDMI-A-1"; }
      { workspace = "5"; output = "eDP-1"; }
      { workspace = "6"; output = "eDP-1"; }
      { workspace = "7"; output = "eDP-1"; }
      { workspace = "8"; output = "DP-1"; }
      { workspace = "9"; output = "DP-1"; }
    ];
  };
}
