{ pkgs, ... }:
let
  serverDir = "/var/lib/minecraft";
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mc-sync" ''
      set -euo pipefail

      if systemctl is-active --quiet minecraft-server; then
        sudo systemctl stop minecraft-server
      fi

      # stash only in case of something bad
      sudo -u alec git -C ${serverDir} stash clear
      sudo -u alec git -C ${serverDir} stash

      #sudo -u alec git -C ${serverDir} reset --hard HEAD
      #sudo -u alec git -C ${serverDir} clean -fd
      sudo -u alec git -C ${serverDir} pull --rebase

      sudo systemctl start minecraft-server
    '')

    (pkgs.writeShellScriptBin "mc-stop" ''
      set -euo pipefail

      if systemctl is-active --quiet minecraft-server; then
        sudo systemctl stop minecraft-server
      fi

      sudo -u alec git -C ${serverDir} pull --rebase || true
      sudo -u alec git -C ${serverDir} add -A
      sudo -u alec git -C ${serverDir} reset -q -- 'Permafrost' 'Permafrost/*' 'world' 'world/*' 'server.properties' 2>/dev/null || true

      # commit message
      if ! sudo -u alec git -C ${serverDir} diff --cached --quiet; then
        date_str=$(date +%-m/%-d/%y)

        top_files=$(sudo -u alec git -C ${serverDir} diff --cached --numstat \
          | awk '$1 != "-" { print $1+$2"\t"$3 }' \
          | sort -rn \
          | head -3 \
          | cut -f2 \
          | xargs -n1 basename \
          | paste -sd ', ')

        description=$(sudo -u alec git -C ${serverDir} diff --cached --numstat \
          | awk '$1 != "-" { printf "%d\t- %s (+%s/-%s)\n", $1+$2, $3, $1, $2 }' \
          | sort -rn \
          | cut -f2-)

        msg="sync $date_str $top_files"

        sudo -u alec git -C ${serverDir} commit -m "$msg" -m "$description"
        sudo -u alec git -C ${serverDir} push
      fi

      sudo systemctl poweroff
    '')
  ];
}
