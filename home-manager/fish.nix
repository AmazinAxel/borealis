{ lib, osConfig, ... }: let
  nord = import ../nord.nix;
  inherit (osConfig.borealis) buildHost user;
  remote = buildHost != null && buildHost != osConfig.networking.hostName;
  inherit (osConfig.borealis) flake;
  ssh = "${user}@${buildHost}";
  cache = "http://${buildHost}:5000"; # harmonia (options.nix); signatures checked on copy
in {
  programs.fish = {
    enable = true;
    # autoloaded functions instead of shellAliases, which run `alias` on every shell start
    functions = lib.mapAttrs (_: cmd: { body = "${cmd} $argv"; wraps = cmd; }) {
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
      # nsp a b -> nix shell nixpkgs#a nixpkgs#b; remote: build there, copy only the runtime closure here
      nsp = if remote then ''
        set -l paths (ssh ${ssh} nix build --no-link --print-out-paths nixpkgs#$argv); or return # eval there too: no local eval, no .drv upload
        nix copy --from ${cache} $paths; and nix shell $paths
      '' else "nix shell nixpkgs#$argv";
      cdp = "cd ~/Projects/$argv[1]";
      __cdp_arg = "if set -q argv[1]; cdp $argv[1]; end";
      fetch = builtins.readFile ../scripts/fetch.fish; # in-process, shell start even thru ssh
      # ns: switch this host, then gc in the background; remote: the build host's checkout of the flake is the
      # source (dirty tree included), so this machine needs no repo. Password asked up front: the build can outlast sudo's cache
      ns = ''
        read -lsP "[sudo] password for $USER: " pass; or return
        printf '%s\n' $pass | sudo -Sp ''' -v; or return
      '' + (if remote then ''
        set -l sys (ssh ${ssh} nix build --no-link --print-out-paths ${flake}#nixosConfigurations.${osConfig.networking.hostName}.config.system.build.toplevel); or return
        nix copy --from ${cache} $sys; or return
        printf '%s\n' $pass | sudo -Sp ''' nix-env -p /nix/var/nix/profiles/system --set $sys; or return
        printf '%s\n' $pass | sudo -Sp ''' $sys/bin/switch-to-configuration switch; or return
      '' else ''
        printf '%s\n' $pass | sudo -Sp ''' nixos-rebuild switch --flake ${flake}; or return
      '') + "printf '%s\\n' $pass | sudo -Sp '' systemctl start --no-block nix-gc";
      # ngc: user + system gc, dedupe, trim, on demand
      ngc = ''
        read -lsP "[sudo] password for $USER: " pass; or return
        printf '%s\n' $pass | sudo -Sp ''' -v; or return
        nix-collect-garbage -d # user-collected garbage
        printf '%s\n' $pass | sudo -Sp ''' nix-collect-garbage -d
        printf '%s\n' $pass | sudo -Sp ''' nix-store --optimise
        printf '%s\n' $pass | sudo -Sp ''' fstrim -av
      '';
      # nde <host>: boot-deploy the flake host of that name to that remote machine (local: ns)
      nde = if remote then ''
        ssh -t ${ssh} env NIX_SSHOPTS='-i /home/${user}/.ssh/id_deploy -o IdentitiesOnly=yes' nixos-rebuild boot --flake ${flake}#$argv[1] --target-host ${user}@$argv[1] --use-substitutes --sudo --ask-sudo-password --no-reexec # eval+build on the build host; target pulls from its substituters (harmonia first), ssh push only for the rest
      '' else ''
        set -lx NIX_SSHOPTS -o ControlMaster=auto -o ControlPath=$XDG_RUNTIME_DIR/nde-%C -o ControlPersist=60 # one ssh login for the whole deploy
        nixos-rebuild boot --flake ${flake}#$argv[1] --target-host ${user}@$argv[1] --use-substitutes --sudo --ask-sudo-password --no-reexec # remote sudo needs the password, no ssh tty to prompt on
      '';
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
        set_color -b ${nord.nord10} ${nord.nord4}; echo -n 
        set_color -b ${nord.nord9} ${nord.nord10}; echo -n 
        set_color ${nord.nord0}; echo -n " $dir $branch"
        set_color normal; set_color ${nord.nord9}; echo -n " "
        set_color normal
      '';
    };
    interactiveShellInit = ''
      set fish_greeting
      set -q TMUX; or fetch
      complete -c cdp -f -a "(__proj_dirs)"

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
