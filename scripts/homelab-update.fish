#!/usr/bin/env fish

set musicDir /home/alec/Music
set mntPoint /mnt/alechomelab
set playlists \
    "Synthwave https://open.spotify.com/playlist/1YIe34rcmLjCYpY9wJoM2p" \
    "Focus https://open.spotify.com/playlist/3Qk9br14pjEo2aRItDhb2f" \
    "Study https://open.spotify.com/playlist/0vvXsWCC9xrXsKd4FyS8kM" \
    "Liked https://open.spotify.com/playlist/1t9A5qwCTugNsZsu558xeN" \
    "SynthAmbient https://open.spotify.com/playlist/4murW7FWRb0LFbG7eUwDy0" \
    "Ambient https://open.spotify.com/playlist/07lYUEyTkWP3NqIa7Kzyqx"

read -lx -P "Enter password: " passwd --silent
echo

function s --inherit-variable passwd
    echo $passwd | sudo -S -p '' $argv
end

set -x NAS_KEEP_MOUNT 1 # sys-sync leaves the NAS mounted for the push
sys-sync
mountpoint -q $mntPoint
or begin
    echo \n"[Homelab] NAS not mounted"
    exit 1
end

set spotdl (nix build --no-link --print-out-paths nixpkgs#spotdl)/bin/spotdl # eval once
mkdir -p $musicDir
for playlist in $playlists
    set fields (string split ' ' $playlist)
    echo \n"[Spotify sync] $fields[1]"
    $spotdl download "$fields[2]" --output $musicDir/$fields[1] --archive $musicDir/$fields[1].archive \
        --add-unavailable --threads 8 --skip-album-art
end
mpc update >/dev/null

echo \n"[Homelab] Pushing music to NAS"
rsync -av --ignore-existing $musicDir/ "$mntPoint/Music/"
s umount $mntPoint

echo \n"[Homelab] Rebuilding"
cd /home/alec/Projects/flake # sys-sync already pulled
and nixos-rebuild boot --flake .#alechomelab --sudo --build-host alec@alecpc --target-host alec@alechomelab.local
