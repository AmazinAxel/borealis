{ lib, ... }: let
  main = { resolution = "1920x1080@144Hz"; position = "0 0"; };
  right = { position = "3200 0"; scale = "1.5"; };
in {
  imports = [ ../../home-manager/laptop.nix ../../home-manager/iotas.nix ];

  wayland.windowManager.sway.config = {
    output = {
      "HDMI-A-1" = main; # built in hdmi
      "DP-9" = main; # adapter
      "*".position = "1920 0"; # Laptop/other monitors
      "DP-1" = right;
      "DP-7" = right; # adapter
    };

    startup = [
      { command = "sleep 3 && thunderbird"; } # let ags load first
    ];
    assigns."5" = [{ app_id = "thunderbird"; }];

    workspaceOutputAssign = map (n: {
      workspace = toString n;
      output = if n <= 4 then "HDMI-A-1" else if n <= 7 then "eDP-1" else "DP-1";
    }) (lib.range 1 9);
  };
}
