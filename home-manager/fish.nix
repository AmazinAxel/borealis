{ lib, pkgs, config, osConfig, ... }: let
  nord = import ../nord.nix;
  starshipInit = pkgs.runCommand "starship-init.fish" {} "${lib.getExe config.programs.starship.package} init fish --print-full-init > $out";
in {
  programs = {
    fish = {
      enable = true;
      # autoloaded functions instead of shellAliases, which run `alias` on every shell start
      functions = lib.mapAttrs (_: cmd: { body = "${cmd} $argv"; wraps = cmd; }) {
        nx-switch = "sudo nixos-rebuild switch --flake ${osConfig.borealis.flake}";
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
      } // {
        gcm = ''git commit -m "$argv"'';
        gacm = ''git add -A && git commit -m "$argv"'';
        cdp = "cd ~/Projects/$argv[1]";
        __cdp_arg = "if set -q argv[1]; cdp $argv[1]; end";
        h = "__cdp_arg $argv[1]; or return; hx .";
        c = "__cdp_arg $argv[1]; or return; claude --dangerously-skip-permissions $argv[2..]";
        cr = "__cdp_arg $argv[1]; or return; claude --dangerously-skip-permissions --resume $argv[2..]";
        fetch = builtins.readFile ../scripts/fetch.fish; # in-process, shell start even thru ssh
        __proj_dirs = "for d in ~/Projects/(commandline -ct)*/; string replace ~/Projects/ '' $d; end";
      };
      interactiveShellInit = ''
        set fish_greeting
        fetch
        complete -c cdp -c h -c c -c cr -f -a "(__proj_dirs)"

        set fish_color_normal normal
        set fish_color_command ${nord.nord9}
        set fish_color_quote ${nord.nord14}
        set fish_color_redirection ${nord.nord9}
        set fish_color_end ${nord.nord6}
        set fish_color_error ${nord.nord11}
        set fish_color_param normal
        set fish_color_comment ${nord.nord3}
        set fish_color_match ${nord.nord8}
        set fish_color_search_match ${nord.nord8}
        set fish_color_operator ${nord.nord9}
        set fish_color_escape ${nord.nord13}
        set fish_color_cwd ${nord.nord8}
        set fish_color_autosuggestion ${nord.nord6}
        set fish_color_user normal
        set fish_color_host ${nord.nord9}
        set fish_color_cancel ${nord.nord15}
        set fish_pager_color_prefix ${nord.nord13}
        set fish_pager_color_completion ${nord.nord6}
        set fish_pager_color_description ${nord.nord10}
        set fish_pager_color_progress ${nord.nord12}
        set fish_pager_color_secondary ${nord.nord1}

        if test "$TERM" = linux
            set -gx STARSHIP_CONFIG ~/.config/starship-tty.toml
        end
        test "$TERM" != dumb; and source ${starshipInit} # pregenerated, skips starship init on every shell
      '';
    };
    starship = {
      enable = true;
      enableFishIntegration = false;
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
