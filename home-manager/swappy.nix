{ config, ... }: {
  programs.swappy = {
    enable = true;
    settings.Default = {
      save_dir = "${config.xdg.userDirs.pictures}/Screenshots";
      save_filename_format = "%Y%m%d-%H%M%S-edited.png";
      line_size = 10;
      text_font = "Sora";
      early_exit = true;
      custom_color="rgb(129,161,193)"; # nord blue
    };
  };
}