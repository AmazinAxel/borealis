let
  nord = import ../nord.nix;
  nordColors = with nord; {
    regular0 = nord0; # Black
    regular1 = nord11; # Red
    regular2 = nord14; # Green
    regular3 = nord13; # Yellow
    regular4 = nord10; # Blue
    regular5 = nord15; # Magenta
    regular6 = nord9; # Cyan
    regular7 = nord6; # White
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
        foreground = nord.nord4; # darkest white
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
