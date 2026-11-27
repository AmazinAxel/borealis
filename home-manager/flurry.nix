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
        # same derivation as desktop.nix's (same store path): variable ttc, SC/TC/HK/JP/KR
        (runCommand "noto-sans-cjk" {} ''
          install -Dm444 -t $out/share/fonts/opentype ${noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc
        '')
        # fancy-letter names (math alphanumerics), dingbats, misc symbols: ~1.2M of the 50M package
        (runCommand "noto-symbols" {} ''
          install -Dm444 -t $out/share/fonts/opentype ${noto-fonts}/share/fonts/noto/{NotoSansMath-Regular.otf,NotoSansSymbols2-Regular.otf,NotoSansSymbols.ttf}
        '')
        dejavu_fonts
      ];
    };
  };
}
