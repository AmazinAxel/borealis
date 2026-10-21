{
  services = {
    mpd = {
      enable = true;
      network.startWhenNeeded = true; # faster login
      musicDirectory = "/home/alec/Music";
      playlistDirectory = "/home/alec/Music";
      extraConfig = ''
        restore_paused "yes"
        metadata_to_use	"artist,album,title,track,name,date"
        audio_output {
          type "pipewire"
          name "Main Output"
        }
      '';
    };
    mpd-discord-rpc = {
      enable = true;
      settings = {
        id = 1562331878164398113;
        format = {
          large_image = "blank";
          small_image = "";
        };
      };
    };
  };
}
