{ config, pkgs, ... }: let
  nord = (import ../nord.nix).hex;
in {
  home-manager.users.${config.borealis.user}.programs.yazi = {
    enable = true;
    enableFishIntegration = true; # y wrapper, cd on quit
    extraPackages = [ pkgs.sshfs pkgs.ouch ];
    plugins = {
      sshfs = { package = pkgs.yaziPlugins.sshfs; setup = true; };
      ouch = pkgs.yaziPlugins.ouch;
    };
    settings = {
      mgr = {
        ratio = [ 1 3 4 ];
        show_hidden = true;
        scrolloff = 8;
      };
      opener.extract = [{ run = ''ouch d -y "$@"''; desc = "Extract here"; }];
      plugin.prepend_previewers = [{ mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}"; run = "ouch"; }];
    };
    keymap.mgr.prepend_keymap = [
      { on = "C"; run = "plugin ouch"; desc = "Compress"; }
      { on = [ "M" "s" ]; run = "plugin sshfs -- menu"; desc = "SSHFS"; }
    ];
    theme = with nord; {
      mgr = {
        cwd = { fg = nord8; bold = true; };
        border_symbol = "│";
        border_style.fg = nord3;
        find_keyword = { fg = nord13; bold = true; };
        find_position.fg = nord15;
        marker_copied = { fg = nord14; bg = nord14; };
        marker_cut = { fg = nord11; bg = nord11; };
        marker_selected = { fg = nord13; bg = nord13; };
        count_copied = { fg = nord0; bg = nord14; };
        count_cut = { fg = nord0; bg = nord11; };
        count_selected = { fg = nord0; bg = nord13; };
      };
      icon = { globs = []; dirs = []; files = []; exts = []; conds = []; };
      notify = { icon_info = ""; icon_warn = ""; icon_error = ""; };
      cmp = { icon_file = ""; icon_folder = ""; icon_command = ""; };
      which.separator = " ";
      indicator = {
        padding = { open = ""; close = ""; };
        parent = { fg = nord6; bg = nord2; };
        current = { fg = nord6; bg = nord2; bold = true; };
        preview = { fg = nord6; bg = nord1; };
      };
      tabs = {
        sep_inner = { open = ""; close = ""; };
        sep_outer = { open = ""; close = ""; };
        active = { fg = nord0; bg = nord9; bold = true; };
        inactive = { fg = nord9; bg = nord1; };
      };
      mode = {
        normal_main = { fg = nord0; bg = nord9; bold = true; };
        normal_alt = { fg = nord9; bg = nord1; };
        select_main = { fg = nord0; bg = nord15; bold = true; };
        select_alt = { fg = nord15; bg = nord1; };
        unset_main = { fg = nord0; bg = nord11; bold = true; };
        unset_alt = { fg = nord11; bg = nord1; };
      };
      status = {
        sep_left = { open = ""; close = ""; };
        sep_right = { open = ""; close = ""; };
        perm_sep.fg = nord3;
        perm_type.fg = nord14;
        perm_read.fg = nord13;
        perm_write.fg = nord11;
        perm_exec.fg = nord8;
        progress_normal = { fg = nord9; bg = nord1; };
        progress_error = { fg = nord11; bg = nord1; };
      };
    };
  };
}
