{ pkgs, lib, config, ... }: let
  mod = "Mod4";
  currentWorkspace = "$(swaymsg -p -t get_workspaces | grep focused | grep -oE '[0-9]+')";
  stepWorkspace = cmd: direction: "exec sh -c 'current=${currentWorkspace}; target=$((current ${direction} 1)); [ $target -lt 1 ] && target=1; [ $target -gt 9 ] && target=9; [ $target -eq $current ] || { ${cmd}; }'";
  workspace = stepWorkspace "swaymsg workspace number $target";
  moveItemToWorkspace = stepWorkspace "swaymsg move container to workspace number $target, workspace number $target";
  # arrows and hjkl: focus, move window, switch workspace, move window to workspace
  directionBinds = lib.concatMapAttrs (dir: vim: let step = if dir == "left" || dir == "up" then "-" else "+"; in
    lib.mergeAttrsList (map (key: {
      "${mod}+${key}" = "focus ${dir}";
      "${mod}+shift+${key}" = "move ${dir}";
      "control+${mod}+${key}" = workspace step;
      "control+${mod}+shift+${key}" = moveItemToWorkspace step;
    }) [ dir vim ])) { left = "h"; right = "l"; up = "k"; down = "j"; };
  # Float foot if the focused workspace has apps other than foot/nemo
  openFoot = pkgs.writeShellScript "open-foot" ''
    swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '
      ([.. | objects | select(.type? == "workspace" and ([.. | objects | .focused?] | any))][0] // {}) |
      [.. | objects | select(
        (.type? == "con" or .type? == "floating_con") and
        (.nodes? // [] | length) == 0 and
        (((.app_id? // "") | startswith("foot")) | not) and
        ((.app_id? // "") != "nemo")
      )] | length > 0
    ' >/dev/null && exec footclient --app-id foot-float
    exec footclient
  '';
  toggleTheme = pkgs.writeShellScript "toggle-theme" ''
    gs=${pkgs.glib}/bin/gsettings
    pk=${pkgs.procps}/bin/pkill
    themes=${config.gtk.theme.package}/share/themes
    gtk4css=$HOME/.config/gtk-4.0/gtk.css
    if [ "$($gs get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]; then
      $gs set org.gnome.desktop.interface color-scheme 'prefer-light'
      $gs set org.gnome.desktop.interface gtk-theme 'Graphite-Light-nord'
      ln -sfn "$themes/Graphite-Light-nord/gtk-4.0/gtk.css" "$gtk4css"
      $pk -USR2 -f "foot --server" || true # SIGUSR2 = [colors-light]
    else
      $gs set org.gnome.desktop.interface color-scheme 'prefer-dark'
      $gs set org.gnome.desktop.interface gtk-theme 'Graphite-Dark-nord'
      ln -sfn "$themes/Graphite-Dark-nord/gtk-4.0/gtk.css" "$gtk4css"
      $pk -USR1 -f "foot --server" || true # SIGUSR1 = [colors-dark]
    fi
  '';
  toggleDim = pkgs.writeShellScript "toggle-dim" ''
    set -- rs.wl-gammarelay / rs.wl.gammarelay Brightness
    if [ "$(busctl --user get-property "$@")" = "d 1" ]; then
      busctl --user set-property "$@" d 0.4
    else
      busctl --user set-property "$@" d 1
    fi
  '';
in {
  wayland.windowManager.sway = {
    config.keybindings = directionBinds // {
      # Volume
      "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05+";
      "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05-";
      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_SINK@ toggle";

      # Brightness
      "XF86MonBrightnessUp" = "exec brightnessctl set +15%";
      "XF86MonBrightnessDown" = "exec brightnessctl set 15%-";

      # Apps
      "${mod}+E" = "exec zen-beta";
      "${mod}+return" = "exec ${openFoot}";
      "${mod}+N" = "exec nemo";
      "${mod}+shift+N" = "exec env SUDO_ASKPASS=${pkgs.writeShellScript "zenity-askpass" "exec ${pkgs.zenity}/bin/zenity --password"} sudo -AE ${pkgs.nemo-with-extensions}/bin/nemo"; # root nemo

      # Ags
      "${mod}+space" = "exec flurry toggle launcher";
      "${mod}+P" = "exec flurry toggle pass";
      "${mod}+I" = "exec flurry randomWallpaper";
      "${mod}+X" = "exec flurry closeAsideStatusMenuWidget";
      "control+${mod}+P" = "exec flurry toggle passSave";
      "control+${mod}+z" = "exec flurry toggleQuicksettings";
      "control+${mod}+v" = "exec flurry toggleCalendar";
      "control+${mod}+x" = "exec flurry toggleBluetooth";
      "control+${mod}+c" = "exec flurry toggleWifi";

      "control+${mod}+Q" = "exec flurry sideview plan";
      "control+${mod}+W" = "exec flurry sideview assistant";
      "control+${mod}+E" = "exec flurry sideview custom";
      "control+${mod}+R" = "exec flurry closeSideview"; # destroy
      "${mod}+A" = "exec flurry toggleSideviewFocus";
      "control+${mod}+Tab" = "exec flurry hideSideview"; # just hides
      "${mod}+G" = "exec flurry toggleSideviewSize";

      "${mod}+C" = "exec flurry hideNotif"; # Closes last notification
      "${mod}+M" = "exec flurry invokeOldestNotif"; # Activates first action of the oldest notification!
      "control+${mod}+M" = "exec flurry invokeOldestNotif 1"; # 2nd action
      "shift+${mod}+M" = "exec flurry invokeOldestNotif 2"; # 3rd action
      "${mod}+S" = "exec flurry toggleStreamingMode";
      "${mod}+B" = "exec ${toggleTheme}";
      "${mod}+O" = "exec ${toggleDim}";
      "${mod}+T" = "exec flurry toggleFocus";
      "${mod}+Escape" = "exec flurry cancelBreak";
      "${mod}+Z" = "exec flurry toggleInfoArea";

      "${mod}+V" = "exec flurry toggle clipboard";
      # Enter = select entry, C = copy 2nd entry, E = edit image with swappy, G = open in gthumb, M = compress video, N = show in nemo, W = wipe clipboard

      "${mod}+R" = "exec flurry record";
      # R = toggle mic, Q = toggle quality, C = clip last 30s, Space = record

      "XF86PowerOff" = "exec flurry toggle powermenu";
      "${mod}+shift+S" = "exec flurry toggle powermenu";
      # S = sleep, Q = shutdown, L = lock, R = restart

      # Mpris/spotify
      "control+${mod}+S" = ''exec "playerctl --player=spotify,%any play-pause"''; # toggle play/pause
      "control+${mod}+D" = ''exec "playerctl --player=spotify,%any next"''; # next track
      "control+${mod}+A" = ''exec "playerctl --player=spotify,%any previous"''; # previous track

      # Ags MPD controls
      "${mod}+control+period" = "exec flurry media next";
      "${mod}+control+comma" = "exec flurry media prev";
      "${mod}+greater" = "exec flurry media nextPlaylist";
      "${mod}+less" = "exec flurry media prevPlaylist";
      "${mod}+slash" = "exec flurry media toggle";

      "Print" = "exec screenshot"; # Screenshot

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
