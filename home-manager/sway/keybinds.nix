{ pkgs, config, ... }: let
  mod = "Mod4";
  currentWorkspace = "$(swaymsg -p -t get_workspaces | grep focused | grep -oE '[0-9]+')";
  workspace = direction: "exec sh -c 'current=${currentWorkspace}; target=$((current ${direction} 1)); [ $target -lt 1 ] && target=1; [ $target -gt 9 ] && target=9; [ $target -eq $current ] || swaymsg workspace number $target'";
  moveItemToWorkspace = direction: "exec sh -c 'current=${currentWorkspace}; target=$((current ${direction} 1)); [ $target -lt 1 ] && target=1; [ $target -gt 9 ] && target=9; [ $target -ne $current ] && swaymsg move container to workspace number $target && swaymsg workspace number $target'";
  # True iff the focused workspace has apps other than foot/nemo
  shouldFloat = pkgs.writeShellScript "should-float" ''
    swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '
      ([.. | objects | select(.type? == "workspace" and ([.. | objects | .focused?] | any))][0] // {}) |
      [.. | objects | select(
        (.type? == "con" or .type? == "floating_con") and
        (.nodes? // [] | length) == 0 and
        (((.app_id? // "") | startswith("foot")) | not) and
        ((.app_id? // "") != "nemo")
      )] | length > 0
    ' >/dev/null
  '';
  openFoot = pkgs.writeShellScript "open-foot" ''
    if ${shouldFloat}; then
      exec footclient --app-id foot-float
    else
      exec footclient
    fi
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
in {
  wayland.windowManager.sway = {
    config.keybindings = {
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
      "${mod}+space" = "exec ags toggle launcher";
      "${mod}+P" = "exec ags toggle pass";
      "${mod}+I" = "exec ags request randomWallpaper";
      "${mod}+period" = "exec ags toggle emojiPicker";
      "${mod}+X" = "exec ags request closeAsideStatusMenuWidget";
      "control+${mod}+P" = "exec ags toggle passSave";
      "control+${mod}+z" = "exec ags request toggleQuicksettings";
      "control+${mod}+v" = "exec ags request toggleCalendar";
      "control+${mod}+x" = "exec ags request toggleBluetooth";
      "control+${mod}+c" = "exec ags request toggleWifi";

      "control+${mod}+Q" = "exec ags request sideviewPlan";
      "control+${mod}+W" = "exec ags request sideviewClaude";
      "control+${mod}+E" = "exec ags request sideviewCustom";
      "control+${mod}+R" = "exec ags request closeSideview"; # destroy
      "${mod}+A" = "exec ags request toggleSideviewFocus";
      "control+${mod}+Tab" = "exec ags request hideSideview"; # just hides
      "${mod}+G" = "exec ags request toggleSideviewSize";

      "${mod}+C" = "exec ags request hideNotif"; # Closes last notification
      "${mod}+M" = "exec ags request invokeOldestNotif"; # Activates first action of the oldest notification!
      "shift+${mod}+M" = "exec ags request 'invokeOldestNotif 1'"; # 2nd action
      "control+${mod}+M" = "exec ags request 'invokeOldestNotif 2'"; # 3rd action
      "${mod}+S" = "exec ags request toggleStreamingMode";
      "${mod}+O" = "exec ${toggleTheme}";
      "${mod}+T" = "exec ags request toggleFocus";
      "${mod}+Z" = "exec ags request toggleInfoArea";

      "${mod}+V" = "exec ags toggle clipboard";
      # Enter = select entry, C = copy 2nd entry, E = edit image with swappy, G = open in gthumb, M = compress video, N = show in nemo, W = wipe clipboard

      "${mod}+R" = "exec ags request record";
      # R = toggle mic, Q = toggle quality, C = clip last 30s, Space = record

      "XF86PowerOff" = "exec ags toggle powermenu";
      "${mod}+shift+S" = "exec ags toggle powermenu";
      # S = sleep, Q = shutdown, L = lock, R = restart

      # Mpris/spotify
      "control+${mod}+S" = ''exec "playerctl --player=spotify,%any play-pause"''; # toggle play/pause
      "control+${mod}+D" = ''exec "playerctl --player=spotify,%any next"''; # next track
      "control+${mod}+A" = ''exec "playerctl --player=spotify,%any previous"''; # previous track

      # blue light filter toggle
      "${mod}+b" = "exec ags request toggleFilter";

      # Ags MPD controls
      "${mod}+control+period" = "exec ags request 'media next'";
      "${mod}+control+comma" = "exec ags request 'media prev'";
      "${mod}+greater" = "exec ags request 'media nextPlaylist'";
      "${mod}+less" = "exec ags request 'media prevPlaylist'";
      "${mod}+slash" = "exec ags request 'media toggle'";

      "Print" = "exec screenshot"; # Screenshot

      # Move focus in a workspace
      "${mod}+left" = "focus left";
      "${mod}+right" = "focus right";
      "${mod}+up" = "focus up";
      "${mod}+down" = "focus down";
      "${mod}+h" = "focus left";
      "${mod}+l" = "focus right";
      "${mod}+k" = "focus up";
      "${mod}+j" = "focus down";

      # Move window in a workspace
      "${mod}+shift+left" = "move left";
      "${mod}+shift+right" = "move right";
      "${mod}+shift+up" = "move up";
      "${mod}+shift+down" = "move down";
      "${mod}+shift+h" = "move left";
      "${mod}+shift+l" = "move right";
      "${mod}+shift+k" = "move up";
      "${mod}+shift+j" = "move down";

      # Move through workspaces
      "control+${mod}+right" = workspace "+";
      "control+${mod}+left" = workspace "-";
      "control+${mod}+l" = workspace "+";
      "control+${mod}+h" = workspace "-";
      "control+${mod}+shift+right" = moveItemToWorkspace "+";
      "control+${mod}+shift+left" = moveItemToWorkspace "-";
      "control+${mod}+shift+l" = moveItemToWorkspace "+";
      "control+${mod}+shift+h" = moveItemToWorkspace "-";
      "control+${mod}+down" = workspace "+";
      "control+${mod}+up" = workspace "-";
      "control+${mod}+j" = workspace "+";
      "control+${mod}+k" = workspace "-";
      "control+${mod}+shift+down" = moveItemToWorkspace "+";
      "control+${mod}+shift+up" = moveItemToWorkspace "-";
      "control+${mod}+shift+j" = moveItemToWorkspace "+";
      "control+${mod}+shift+k" = moveItemToWorkspace "-";

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
