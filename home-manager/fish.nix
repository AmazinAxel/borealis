{ lib, pkgs, ... }: let
  nord = import ../nord.nix;
in {
  home.packages = [ (pkgs.writeScriptBin "fetch" (builtins.readFile ../scripts/fetch.fish)) ]; # shell start even thru ssh

  programs = {
    fish = {
      enable = true;
      shellAliases = {
        nx-switch = "sudo nixos-rebuild switch";
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
        cdp = "cd ~/Projects/$argv[1]";
        h = "if set -q argv[1]; cdp $argv[1]; or return; end; hx .";
        c = "if set -q argv[1]; cdp $argv[1]; or return; end; claude --dangerously-skip-permissions $argv[2..]";
        cr = "if set -q argv[1]; cdp $argv[1]; or return; end; claude --dangerously-skip-permissions --resume $argv[2..]";
        __proj_dirs = "for d in ~/Projects/(commandline -ct)*/; string replace ~/Projects/ '' $d; end";
      };
      interactiveShellInit = ''
        set fish_greeting
        fetch
        complete -c cdp -c h -c c -c cr -f -a "(__proj_dirs)"

        ${lib.concatLines (lib.mapAttrsToList (n: v: "set ${n} ${v}") nord)}

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
      '';
    };
    starship = {
      enable = true;
      settings = {
        format = lib.concatStrings [
          "[ $hostname ](bg:#${nord.nord4} fg:#${nord.nord3})"
          "[](bg:#${nord.nord10} fg:#${nord.nord4})"
          "[](bg:#${nord.nord9} fg:#${nord.nord10})"
          "$directory"
          "$git_branch"
          "[ ](fg:#${nord.nord9})"
        ];

        hostname = {
          ssh_only = false;
          format = "$hostname"; # messes up coloring otherwise
        };
        directory = {
          format = "[ $path ](fg:#${nord.nord0} bg:#${nord.nord9})";
          truncation_length = 4;
          truncation_symbol = "../";
        };
        git_branch.format = "[\\($branch\\)](fg:#${nord.nord0} bg:#${nord.nord9})";
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
