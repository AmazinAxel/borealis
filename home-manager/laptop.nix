{ pkgs, ... }: {
  services.batsignal = {
    enable = true;
    extraArgs = [
      "-w" "20" # warning msg
      "-c" "10" # critical msg
      "-d" "3" # now we dont want to lose work!
      "-m" "30" # poll s multiplier
      "-a" "Low battery"
      "-W" "  "
      "-C" "  "

      # at 3% warn then sleep so i have time to find a charger without it dying on me
      "-D" "${pkgs.libnotify}/bin/notify-send -u critical -a 'Low battery' 'Going to sleep...'; sleep 10; systemctl suspend"
    ];
  };
}
