read -rsp "[sudo] password for $USER: " pass; echo
sudo -Sp '' -v <<< "$pass" || exit 1

# Delete stuff
nix-collect-garbage -d # user-collected garbage
sudo -Sp '' nix-collect-garbage -d <<< "$pass"

# Trim
sudo -Sp '' fstrim -av <<< "$pass"
