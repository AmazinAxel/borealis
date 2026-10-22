let
  nord = builtins.mapAttrs (_: v: "#${v}") (import ../nord.nix);
in {
  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      os.editPreset = "helix";
      gui.theme = with nord; {
        activeBorderColor = [ nord8 "bold" ];
        inactiveBorderColor = [ nord3 ];
        optionsTextColor = [ nord9 ];
        selectedLineBgColor = [ nord2 ];
        inactiveViewSelectedLineBgColor = [ nord1 ];
        cherryPickedCommitFgColor = [ nord8 ];
        cherryPickedCommitBgColor = [ nord2 ];
        markedBaseCommitFgColor = [ nord13 ];
        markedBaseCommitBgColor = [ nord2 ];
        unstagedChangesColor = [ nord11 ];
        defaultFgColor = [ nord4 ];
        searchingActiveBorderColor = [ nord13 ];
      };
    };
  };
}
