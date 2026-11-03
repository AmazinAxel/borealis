{ lib, pkgs, ... }: let
  nord = (import ../nord.nix).hex;
in {
  environment.systemPackages = [ pkgs.foot.terminfo ]; # tmux refuses to start over ssh from foot without it
  programs.fish.shellFunctions = lib.mapAttrs (_: cmd: { body = "${cmd} $argv"; modifiers.wraps = cmd; }) {
    t = "tmux";
    ta = "tmux new -A -s main"; # attach or create
    tl = "tmux ls";
    tk = "tmux kill-session -t";
  };

  programs.tmux = {
    enable = true;
    shortcut = "a"; # easier to type
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

      set -g status-interval 0 # no periodic redraw
      set -g status-style "bg=default,fg=${nord.nord4}"
      set -g status-left "#[bg=${nord.nord4},fg=${nord.nord3}] #S #[bg=${nord.nord10},fg=${nord.nord4}]#[bg=#{?#{==:#{window_index},#{base-index}},${nord.nord9},default},fg=${nord.nord10}]"
      set -g status-left-length 50 # default 10 truncates session names
      set -g status-right ""
      set -g window-status-current-style default
      set -g pane-status-current-style default
      set -g session-status-current-style default
      set -g window-status-separator ""
      set -g window-status-format " #I:#W "
      set -g window-status-current-format "#[bg=${nord.nord9},fg=${nord.nord0}] #I:#W #[bg=default,fg=${nord.nord9}]"
      set -g pane-active-border-style "fg=${nord.nord9}"
      set -g message-style "bg=${nord.nord9},fg=${nord.nord0}"
      set -g mode-style "bg=${nord.nord9},fg=${nord.nord0}"
    '';
  };
}
