#!/usr/bin/env fish

set mntPoint /mnt/alechomelab
if not set -q passwd # caller (eg homelab-update) may have already asked
    read -g -P "[Sync] Enter password: " passwd --silent
    echo
end

function s --inherit-variable passwd
    echo $passwd | sudo -S -p '' $argv
end

s mkdir -p $mntPoint
set cred (mktemp) # keeps the password out of ps
printf 'username=alec\npassword=%s\n' $passwd >$cred
s mount.cifs //ALECHOMELAB.local/USB $mntPoint -o credentials=$cred,uid=alec,gid=users
set mounted $status
rm $cred

if test $mounted -eq 0
    echo \n"[Sync] Pulling music from NAS"
    rsync -av --ignore-existing "$mntPoint/Music/" /home/alec/Music/
    mpc update >/dev/null
    echo \n"[Sync] Syncing wallpapers with NAS"
    rsync -av --ignore-existing "$mntPoint/Wallpapers/" /home/alec/Wallpapers/
    rsync -av --ignore-existing /home/alec/Wallpapers/ "$mntPoint/Wallpapers/"
    set -q NAS_KEEP_MOUNT; or s umount $mntPoint # homelab-update reuses the mount
else
    echo \n"[Sync] NAS mount failed - skipping music and wallpapers"
end

echo \n"[Sync] Pulling passwords"
pass git pull --rebase

if test (pass git rev-list '@{u}..HEAD' --count) -gt 0
    echo \n"[Sync] Passwords modified"
    pass git push
end

set sshDir /home/alec/.ssh
mkdir -p $sshDir
chmod 700 $sshDir
set keyEntries /home/alec/.password-store/ssh/*.gpg # if this is empty it wont loop
for f in $keyEntries
    set name (basename $f .gpg)
    test -e $sshDir/$name; and continue # skip if installed?
    string match -q '*.pub' $name; and set mode 644; or set mode 600 # .pub is not secret
    pass show ssh/$name | install -m $mode /dev/stdin $sshDir/$name
    and echo "[Sync] Installed ssh key $name"
end

## Rebuild latest
cd /home/alec/Projects/flake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo \n"[Sync] System flake is dirty - not updating system"
else
    git pull
    s nixos-rebuild boot --flake .
end

# Astal
date +%s%3N >/home/alec/Projects/flake/ags/lastSync.txt
