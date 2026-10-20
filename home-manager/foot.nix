let
  nordColors = {
    regular0 = "2e3440"; # Black
    regular1 = "bf616a"; # Red
    regular2 = "a3be8c"; # Green
    regular3 = "ebcb8b"; # Yellow
    regular4 = "5e81ac"; # Blue
    regular5 = "b48ead"; # Magenta
    regular6 = "81a1c1"; # Cyan
    regular7 = "eceff4"; # White
    # urls = "5e81ac"; # Blue (regular4)
  };
in {
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        title = "Terminal";
        pad = "5x5";
        font = "Iosevka Nerd Font Mono:size=12.5";
      };
      cursor = {
        style = "beam";
        unfocused-style = "unchanged";
        blink = true;
        beam-thickness = 1;
      };
      key-bindings.clipboard-paste = "Control+Shift+v XF86Paste";

      colors-dark = nordColors // {
        alpha = 0.95;
        foreground = "d8dee9"; # darkest white
        background = nordColors.regular0; # black
      };

      colors-light = nordColors // {
        alpha = 0.9;
        foreground = nordColors.regular0; # black
        background = nordColors.regular7; # white
      };
    };
  };
}
