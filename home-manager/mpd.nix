{
  services.mpd = {
    enable = true;
    musicDirectory = "/home/alec/Music";
    playlistDirectory = "/home/alec/Music";
    extraConfig = ''
      restore_paused "yes"
      metadata_to_use	"artist,title,track,name,date"
      audio_output {
        type "pipewire"
        name "Main Output"
      }
    '';
  };
}
