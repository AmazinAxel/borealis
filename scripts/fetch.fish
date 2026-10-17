#!/usr/bin/env fish

set -l blue '\033[0;34m'
set -l cyan '\033[0;36m'
set -l white '\033[39m'
set -l disk (df -BG /persist | awk -v cyan="$cyan" -v white="$white" 'NR==2 {print $3 "B / " $2 "B (" cyan $5 white ")"}')
set -l memory (free -b | awk -v cyan="$cyan" -v white="$white" '/Mem/ {u=$2-$7; t=$2} END {printf "%.1fGB / %.0fGB (" cyan "%.1f%%" white ")", u/1e9, t/1e9, (u/t*100)}')
set -l cpu (awk '/^cpu /{b=$2+$3+$4; printf "%.1f", b/(b+$5+$6+$7+$8+$9)*100}' /proc/stat) # since boot

echo -e "$blue  ▗▄   $cyan▗▄ ▄▖     $white┌───────────────────────────────┐"
echo -e "$blue ▄▄🬸█▄▄▄$cyan🬸█▛ $blue▃"
echo -e "$cyan   ▟▛    ▜$blue▃▟🬕     $cyan CPU:$white $cpu%"
echo -e "$cyan🬋🬋🬫█      $blue█🬛🬋🬋    $cyan Disk:$white $disk"
echo -e "$cyan 🬷▛🮃$blue▙    ▟▛       $cyan Memory:$white $memory"
echo -e "$cyan 🮃$blue ▟█🬴$cyan▀▀▀█🬴▀▀"
echo -e "$blue  ▝▀ ▀▘   $cyan▀▘     $white└───────────────────────────────┘"
