{ lib, pkgs, ... }: {
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        nx-switch = "sudo nixos-rebuild switch --flake /home/alec/Projects/flake";
        g = "git";
        ga = "git add -A";
        gl = "git pull";
        glr = "git pull --rebase";
        gp = "git push";
        gs = "git stash";
        gsp = "git stash pop";
        gd = "git diff";
        gdh = "git diff HEAD";
        gc = "git commit -v";
        gac = "git add -A && git commit -v";
        gu = "git reset"; # unstage everything
        guc = "git reset HEAD~"; # undo last commit

        n = "nix";
        nfu = "nix flake update";
        nb = "nix build";
        nd = "nix develop";
        nfc = "nix flake check";
      };
      functions = {
        gcm = ''git commit -m "$argv"'';
        gacm = ''git add -A && git commit -m "$argv"'';
      };
      interactiveShellInit = ''
        set fish_greeting
        fetch

        set nord0 2e3440
        set nord1 3b4252
        set nord2 434c5e
        set nord3 4c566a
        set nord4 d8dee9
        set nord5 e5e9f0
        set nord6 eceff4
        set nord7 8fbcbb
        set nord8 88c0d0
        set nord9 81a1c1
        set nord10 5e81ac
        set nord11 bf616a
        set nord12 d08770
        set nord13 ebcb8b
        set nord14 a3be8c
        set nord15 b48ead

        set fish_color_normal normal
        set fish_color_command $nord9
        set fish_color_quote $nord14
        set fish_color_redirection $nord9
        set fish_color_end $nord6
        set fish_color_error $nord11
        set fish_color_param normal
        set fish_color_comment $nord3
        set fish_color_match $nord8
        set fish_color_search_match $nord8
        set fish_color_operator $nord9
        set fish_color_escape $nord13
        set fish_color_cwd $nord8
        set fish_color_autosuggestion $nord6
        set fish_color_user normal
        set fish_color_host $nord9
        set fish_color_cancel $nord15
        set fish_pager_color_prefix $nord13
        set fish_pager_color_completion $nord6
        set fish_pager_color_description $nord10
        set fish_pager_color_progress $nord12
        set fish_pager_color_secondary $nord1

        if test "$TERM" = linux
            set -gx STARSHIP_CONFIG ~/.config/starship-tty.toml
        end
        starship init fish | source
      '';
    };
    starship = {
      enable = true;
      settings = {
        format = lib.concatStrings [
          "[ $hostname ](bg:#d8dee9 fg:#4c566a)"
          "[](bg:#5e81ac fg:#d8dee9)"
          "[](bg:#81a1c1 fg:#5e81ac)"
          "$directory"
          "$git_branch"
          "[ ](fg:#81a1c1)"
        ];

        hostname = {
          ssh_only = false;
          format = "$hostname"; # messes up coloring otherwise
        };
        directory = {
          format = "[ $path ](fg:#2e3440 bg:#81a1c1)";
          truncation_length = 4;
          truncation_symbol = "../";
        };
        git_branch.format = "[\\($branch\\)](fg:#2e3440 bg:#81a1c1)";
      };
    };
  };

  # TTY prompt
  xdg.configFile."starship-tty.toml".text = ''
    format = "$hostname $directory ($git_branch) > "

    [hostname]
    ssh_only = false
    format = "$hostname"

    [directory]
    format = "$path"
    truncation_length = 4
    truncation_symbol = "../"

    [git_branch]
    format = " ($branch)"
  '';
}
