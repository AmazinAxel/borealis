{ lib, config, ... }: let
  mod = "Mod4";
  # next/prev workspace clamped to 1-9
  workspace = dir: "nop flurry workspace ${dir}";
  moveItemToWorkspace = dir: "nop flurry workspace move${dir}";
  # arrows and hjkl: focus, move window, switch workspace, move window to workspace
  directionBinds = lib.concatMapAttrs (dir: vim: let step = if dir == "left" || dir == "up" then "-" else "+"; in
    lib.mergeAttrsList (map (key: {
      "${mod}+${key}" = "focus ${dir}";
      "${mod}+shift+${key}" = "move ${dir}";
      "control+${mod}+${key}" = workspace step;
      "control+${mod}+shift+${key}" = moveItemToWorkspace step;
    }) [ dir vim ])) { left = "h"; right = "l"; up = "k"; down = "j"; };
in {
  wayland.windowManager.sway = {
    config.keybindings = directionBinds // {
      # Volume
      "XF86AudioRaiseVolume" = "nop flurry volume up";
      "XF86AudioLowerVolume" = "nop flurry volume down";
      "XF86AudioMute" = "nop flurry volume mute";

      # Brightness
      "XF86MonBrightnessUp" = "nop flurry brightness up";
      "XF86MonBrightnessDown" = "nop flurry brightness down";

      # Apps
      "${mod}+return" = "nop flurry terminal";
      "${mod}+N" = "exec foot ${lib.getExe config.programs.yazi.package}";
      "${mod}+shift+N" = "exec foot sudo -E ${lib.getExe config.programs.yazi.package}"; # root yazi, foot asks for the password

      # Flurry
      "${mod}+space" = "nop flurry toggle launcher";
      "${mod}+P" = "nop flurry toggle pass";
      "${mod}+I" = "nop flurry randomWallpaper";
      "${mod}+X" = "nop flurry closeMenu";
      "control+${mod}+P" = "nop flurry toggle passSave";
      "control+${mod}+z" = "nop flurry toggleBluetooth";
      "control+${mod}+x" = "nop flurry toggleWifi";
      "control+${mod}+c" = "nop flurry toggleCalendar";

      "control+${mod}+Q" = "nop flurry sideview plan";
      "control+${mod}+W" = "nop flurry sideview assistant";
      "control+${mod}+E" = "nop flurry sideview custom";
      "control+${mod}+R" = "nop flurry closeSideview"; # destroy
      "${mod}+A" = "nop flurry toggleSideviewFocus";
      "control+${mod}+Tab" = "nop flurry toggleSideview"; # hides, or reopens the last page
      "${mod}+G" = "nop flurry toggleSideviewSize";

      "${mod}+C" = "nop flurry hideNotif"; # Closes last notification
      "${mod}+M" = "nop flurry invokeOldestNotif"; # Activates first action of the oldest notification!
      "control+${mod}+M" = "nop flurry invokeOldestNotif 1"; # 2nd action
      "shift+${mod}+M" = "nop flurry invokeOldestNotif 2"; # 3rd action
      "${mod}+S" = "nop flurry toggleStreamingMode";
      "${mod}+B" = "nop flurry theme";
      "${mod}+O" = "nop flurry dim";
      "${mod}+T" = "nop flurry toggleFocus";
      "${mod}+Escape" = "nop flurry cancelBreak";
      "${mod}+Z" = "nop flurry toggleStatus";

      "${mod}+V" = "nop flurry toggle clipboard";
      # Enter = select entry, C = copy 2nd entry, E = edit image with swappy, G = open in gthumb, M = compress video, N = show in nemo, W = wipe clipboard

      "${mod}+R" = "nop flurry record";
      # R = toggle mic, Q = toggle quality, C = clip last 30s, Space = record

      "XF86PowerOff" = "nop flurry toggle powermenu";
      "${mod}+shift+S" = "nop flurry toggle powermenu";
      # S = sleep, Q = shutdown, L = lock, R = restart

      # Mpris/spotify
      "control+${mod}+S" = "nop flurry mpris toggle"; # toggle play/pause
      "control+${mod}+D" = "nop flurry mpris next"; # next track
      "control+${mod}+A" = "nop flurry mpris prev"; # previous track

      # Flurry MPD controls
      "${mod}+control+period" = "nop flurry media next";
      "${mod}+control+comma" = "nop flurry media prev";
      "${mod}+greater" = "nop flurry media nextPlaylist";
      "${mod}+less" = "nop flurry media prevPlaylist";
      "${mod}+slash" = "nop flurry media toggle";

      "Print" = "nop flurry screenshot"; # Screenshot

      "${mod}+minus" = "floating enable, resize set 1800 960, move scratchpad, move position center";
      "${mod}+equal" = "scratchpad show";

      "${mod}+F" = "floating toggle";
      "F11" = "fullscreen toggle";
      "${mod}+Q" = "kill";
      "${mod}+tab" = "workspace back_and_forth";
    };
    # Scroll through workspaces
    extraConfig = ''
      bindsym --whole-window Mod4+button5 ${workspace "+"}
      bindsym --whole-window Mod4+button4 ${workspace "-"}
      bindsym --whole-window Control+Mod4+button5 ${moveItemToWorkspace "+"}
      bindsym --whole-window Control+Mod4+button4 ${moveItemToWorkspace "-"}
    '';
  };
}
