{ config, ... }: {
  services = {
    mpd = {
      enable = true;
      network.startWhenNeeded = true; # faster login
      musicDirectory = config.xdg.userDirs.music;
      playlistDirectory = config.xdg.userDirs.music;
      extraConfig = ''
        restore_paused "yes"
        metadata_to_use	"artist,album,title,track,name,date"
        audio_output {
          type "pipewire"
          name "Main Output"
        }
      '';
    };
  };
}
