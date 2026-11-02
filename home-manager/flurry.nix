{ borealis, pkgs, ... }: {
  imports = [ borealis.flurry.homeManagerModules.default ];

  programs.flurry = {
    enable = true;
    settings = {
      fileManager = [ "nemo" ];
      imageViewer = [ "gthumb" ];
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
