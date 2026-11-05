{ borealis, pkgs, config, ... }: {
  imports = [ borealis.flurry.homeManagerModules.default ];

  programs.flurry = {
    enable = true;
    settings = {
      fileManager = [ "nemo" ];
      imageViewer = [ "gthumb" ];
      # Mod+Enter: float over workspaces with apps other than foot/nemo
      # Mod+B: foot's server switches palettes on SIGUSR1/SIGUSR2
      theme = {
        dark = "Graphite-Dark-nord";
        light = "Graphite-Light-nord";
        dir = "${config.gtk.theme.package}/share/themes";
        signalUnits = [ "foot.service" ];
      };
      terminal = {
        command = [ "footclient" ];
        floating = [ "footclient" "--app-id" "foot-float" ];
        tiledWith = [ "foot" "nemo" ];
      };
      fonts = with pkgs; [
        (runCommand "sora" { } "install -Dm444 -t $out/share/fonts/truetype ${./fonts}/Sora-*.ttf")
        # setting fonts replaces flurry's default list
        nerd-fonts.iosevka
        noto-fonts-color-emoji
        dejavu_fonts
      ];
    };
  };
}
