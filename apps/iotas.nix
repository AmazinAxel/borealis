{ config, pkgs, ... }: let
  inherit (config.borealis) user;
in {
  environment.systemPackages = [ pkgs.iotas ];
  environment.persistence."/persist".users.${user}.directories = [ ".local/share/iotas" ];

  home-manager.users.${user}.dconf.settings."org/gnome/gitlab/cheywood/Iotas" = {
    first-start = false;
    use-monospace-font = true;
    spelling-enabled = true;
    editor-header-bar-visibility = "auto-hide";
    editor-theme = "iotas-mono";
    editor-formatting-bar-visibility = "disabled";
    persist-sidebar = false;
  };
}
