{ lib, osConfig, ... }: let
  nord = import ../nord.nix;
in {
  programs.fish = {
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
      fetch = builtins.readFile ../scripts/fetch.fish; # in-process, shell start even thru ssh
      __proj_dirs = "for d in ~/Projects/(commandline -ct)*/; string replace ~/Projects/ '' $d; end";
      fish_prompt = ''
        set -l root $PWD
        while test -n "$root"; and not test -f $root/.git/HEAD
          set root (string replace -r '/[^/]*$' "" $root)
        end
        set -l dir (prompt_pwd -D 4)
        set -l branch
        if test -n "$root"
          read -l head < $root/.git/HEAD
          set branch (string replace -f 'ref: refs/heads/' "" $head)
          set dir (string replace -r '.*/' "" $root)(string replace $root "" $PWD)
        end
        test -n "$branch"; and set branch "($branch)"

        echo
        if contains -- "$TERM" linux dumb
          echo -n "$hostname $dir $branch > "
          return
        end
        set_color -b ${nord.nord4} ${nord.nord3}; echo -n " $hostname "
        set_color -b ${nord.nord10} ${nord.nord4}; echo -n 
        set_color -b ${nord.nord9} ${nord.nord10}; echo -n 
        set_color ${nord.nord0}; echo -n " $dir $branch"
        set_color normal; set_color ${nord.nord9}; echo -n " "
        set_color normal
      '';
    };
    interactiveShellInit = ''
      set fish_greeting
      set -q TMUX; or fetch
      complete -c cdp -f -a "(__proj_dirs)"

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
    '';
  };
}
