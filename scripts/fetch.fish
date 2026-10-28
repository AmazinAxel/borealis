set -l blue '\033[0;34m'
set -l cyan '\033[0;36m'
set -l white '\033[39m'
set -l d (string split -n ' ' (df -BG --output=used,size,pcent /persist)[2])
set -l disk "$d[1]B / $d[2]B ($cyan$d[3]$white)"
set -l m (string match -rg '^(?:MemTotal|MemAvailable): +(\d+)' < /proc/meminfo)
set -l u (math $m[1] - $m[2])
set -l memory (printf "%.1fGB / %.0fGB ($cyan%.1f%%$white)" (math $u x 1024 / 1e9) (math $m[1] x 1024 / 1e9) (math $u / $m[1] x 100))
read -l -a s < /proc/stat
set -l b (math $s[2] + $s[3] + $s[4])
set -l cpu (printf "%.1f" (math $b / \($b + $s[5] + $s[6] + $s[7] + $s[8] + $s[9]\) x 100)) # since boot

echo -e "$blue  ▗▄   $cyan▗▄ ▄▖     $white┌───────────────────────────────┐"
echo -e "$blue ▄▄🬸█▄▄▄$cyan🬸█▛ $blue▃"
echo -e "$cyan   ▟▛    ▜$blue▃▟🬕     $cyan CPU:$white $cpu%"
echo -e "$cyan🬋🬋🬫█      $blue█🬛🬋🬋    $cyan Disk:$white $disk"
echo -e "$cyan 🬷▛🮃$blue▙    ▟▛       $cyan Memory:$white $memory"
echo -e "$cyan 🮃$blue ▟█🬴$cyan▀▀▀█🬴▀▀"
echo -e "$blue  ▝▀ ▀▘   $cyan▀▘     $white└───────────────────────────────┘"
