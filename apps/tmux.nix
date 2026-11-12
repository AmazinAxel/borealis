{ lib, pkgs, ... }: let
  nord = (import ../nord.nix).hex;

  # Prefixless, sway-style: Alt mirrors sway's Super. Panes = sway windows, windows = sway workspaces.
  cwd = ''-c "#{pane_current_path}"'';
  # Clamp at the first window, create past the last, like flurry's workspace stepping
  step = {
    "-" = "if -F '#{?window_start_flag,,1}' prev";
    "+" = "if -F '#{window_end_flag}' 'neww ${cwd}' next";
  };
  move = {
    "-" = "if -F '#{window_start_flag}' 'breakp -b' 'joinp -t :-'";
    "+" = "if -F '#{window_end_flag}' 'breakp -a' 'joinp -t :+'";
  };
  dirs = { h = "L"; j = "D"; k = "U"; l = "R"; Left = "L"; Down = "D"; Up = "U"; Right = "R"; };
  dirBinds = lib.concatStrings (lib.mapAttrsToList (key: d: let
    shifted = if lib.stringLength key == 1 then lib.toUpper key else "S-${key}";
    s = if d == "L" || d == "U" then "-" else "+";
    of = { L = "left"; D = "down"; U = "up"; R = "right"; }.${d};
  in ''
    bind -n M-${key} selectp -${d}
    bind -n M-${shifted} swapp -t '{${of}-of}'
    bind -n C-M-${key} ${step.${s}}
    bind -n C-M-${shifted} ${move.${s}}
    bind -T resize ${key} resizep -${d} 5 \; switchc -T resize
  '') dirs);
  windowBinds = lib.concatMapStrings (n: let i = toString n; in ''
    bind -n M-${i} if -F '#{W:#{?#{==:#{window_index},${i}},1,}}' 'selectw -t :${i}' 'neww -t :${i} ${cwd}'
  '') (lib.range 1 9);
  popup = "popup -E -w 90% -h 90% -d '#{pane_current_path}'";
in {
  environment.systemPackages = [ pkgs.foot.terminfo ]; # tmux refuses to start over ssh from foot without it
  programs.fish.shellFunctions = {
    t.body = "if set -q argv[1]; tmux new -A -s $argv[1]; else; tmux new; end"; # attach or create
    tk.body = "for s in $argv; tmux kill-session -t $s; end";
  };
  programs.fish.interactiveShellInit = ''
    complete -c t -c tk -f -a "(tmux ls -F '#S' 2>/dev/null)"
  '';

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    escapeTime = 0;
    baseIndex = 1;
    terminal = "tmux-256color";
    secureSocket = false; # /run/user socket is removed on logout, sessions become unreachable over ssh
    withUtempter = false;
    extraConfig = ''
      set -g mouse on
      set -g focus-events on
      set -ga terminal-overrides ",foot*:Tc"
      set -g extended-keys on # pass Shift+Enter etc. to apps
      set -g extended-keys-format csi-u
      set -ga terminal-features ",foot*:extkeys:clipboard"

      set -g prefix None
      unbind -a -T prefix
      ${dirBinds}${windowBinds}
      bind -n C-M-WheelUpPane ${move."-"}
      bind -n C-M-WheelDownPane ${move."+"}
      bind -n M-WheelUpPane ${step."-"}
      bind -n M-WheelDownPane ${step."+"}
      bind -n M-Enter if -F '#{e|>:#{pane_width},#{e|*:#{pane_height},2}}' 'splitw -h ${cwd}' 'splitw -v ${cwd}'
      bind -n M-q killp
      bind -n M-Tab last
      bind -n M-f resizep -Z
      bind -n M-r switchc -T resize
      bind -n M-= if -F '#{==:#{session_name},scratch}' detach "${popup} 'TMUX= tmux new -A -s scratch'"
      bind -n M-n ${popup} yazi
      bind -n M-N ${popup} 'sudo -E yazi'
      bind -n M-Space choose-tree -Zs
      bind -n M-v copy-mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      set -g status-interval 0 # no periodic redraw
      set -g status-style "bg=default,fg=${nord.nord4}"
      set -g status-left "#[bg=${nord.nord4},fg=${nord.nord3}] #S #[bg=${nord.nord10},fg=${nord.nord4}]#[bg=#{?#{==:#{window_index},#{base-index}},${nord.nord9},default},fg=${nord.nord10}]"
      set -g status-left-length 50 # default 10 truncates session names
      set -g status-right ""
      set -g window-status-current-style default
      set -g pane-status-current-style default
      set -g session-status-current-style default
      set -g window-status-separator ""
      set -g window-status-format " #I:#W "
      set -g window-status-current-format "#[bg=${nord.nord9},fg=${nord.nord0}] #I:#W #[bg=default,fg=${nord.nord9}]"
      set -g pane-active-border-style "fg=${nord.nord9}"
      set -g message-style "bg=${nord.nord9},fg=${nord.nord0}"
      set -g mode-style "bg=${nord.nord9},fg=${nord.nord0}"
    '';
  };
}
