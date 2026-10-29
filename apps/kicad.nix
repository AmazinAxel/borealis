{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (symlinkJoin {
      name = "kicad"; paths = [ kicad ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })
  ];
  environment.persistence."/persist".users.${config.borealis.user}.directories = [
    ".config/kicad"
    ".local/share/kicad"
  ];
}
