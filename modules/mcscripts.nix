{ pkgs, config, ... }:
let
  git = "sudo -u alec git -C ${config.mcdev.serverDir}";
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mc-sync" ''
      set -euo pipefail

      sudo systemctl stop minecraft-server

      # stash only in case of something bad
      ${git} stash clear
      ${git} stash

      #${git} reset --hard HEAD
      #${git} clean -fd
      ${git} pull --rebase

      sudo systemctl start minecraft-server
    '')

    (pkgs.writeShellScriptBin "mc-stop" ''
      set -euo pipefail

      sudo systemctl stop minecraft-server

      ${git} pull --rebase || true
      ${git} add -A
      ${git} reset -q -- 'Permafrost' 'Permafrost/*' 'world' 'world/*' 'server.properties' 2>/dev/null || true

      # commit message
      if ! ${git} diff --cached --quiet; then
        date_str=$(date +%-m/%-d/%y)

        top_files=$(${git} diff --cached --numstat \
          | awk '$1 != "-" { print $1+$2"\t"$3 }' \
          | sort -rn \
          | head -3 \
          | cut -f2 \
          | xargs -n1 basename \
          | paste -sd ', ')

        description=$(${git} diff --cached --numstat \
          | awk '$1 != "-" { printf "%d\t- %s (+%s/-%s)\n", $1+$2, $3, $1, $2 }' \
          | sort -rn \
          | cut -f2-)

        msg="sync $date_str $top_files"

        ${git} commit -m "$msg" -m "$description"
        ${git} push
      fi

      sudo systemctl poweroff
    '')
  ];
}
