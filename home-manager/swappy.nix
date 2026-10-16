{
  programs.swappy = {
    enable = true;
    settings.Default = {
      save_dir = "$HOME/Pictures/Screenshots";
      save_filename_format = "%Y%m%d-%H%M%S-edited.png";
      show_panel = false;
      line_size = 10;
      text_size = 20;
      text_font = "Sora";
      paint_mode = "brush";
      early_exit = true;
      fill_shape = false;
      custom_color="rgb(129,161,193)"; # nord blue
    };
  };
}