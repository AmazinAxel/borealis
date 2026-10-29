{ config, pkgs, ... }: let
  inherit (config.borealis) user;
  prismThemes = pkgs.fetchFromGitHub {
    owner = "PrismLauncher";
    repo = "Themes";
    rev = "9e921ca23a1838f87e0699517a77da5e92921a11";
    hash = "sha256-V6mkItSVA/TSC0yWKvcps/ewAC0nSd1KSBr8Pvdv8z8=";
  };
in {
  environment.persistence."/persist".users.${user}.directories = [
    ".local/share/PrismLauncher"
    ".cache/qtshadercache-x86_64-little_endian-lp64"
  ];

  home-manager.users.${user} = {
    programs.prismlauncher = {
      enable = true;
      themes.Nord = "${prismThemes}/themes/Nord";
      settings = {
        CloseAfterLaunch = true;
        QuitAfterGameStop = true;
        ShowConsoleOnError = false;

        UseNativeGLFW = false;
        UseNativeOpenAL = false;

        StatusBarVisible = false;

        ShowGameTime = false;
        RecordGameTime = false;
        ShowGlobalGameTime = false;

        ApplicationTheme = "Nord";
        IconTheme = "Ore UI";
        ConsoleFont = "Iosevka Nerd Font";
      };
    };
    home.file.".local/share/PrismLauncher/iconthemes/Ore UI".source = "${prismThemes}/icons/Ore UI";

    wayland.windowManager.sway.config.window.commands = [{
      criteria.app_id = "PrismLauncher"; # Minecraft launcher
      command = "floating enable";
    }];
  };
}
