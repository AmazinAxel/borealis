{ lib, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.concatMapAttrs (app: mimes: lib.genAttrs mimes (_: app)) {
      "org.gnome.FileRoller.desktop" = [
        "application/zip"
      ];
      "org.gnome.gThumb.desktop" = [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/svg+xml"
        "image/x-xcf"
        "image/vnd.adobe.photoshop"
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/vnd.avi"
        "video/quicktime"
        "audio/mpeg"
        "audio/flac"
        "audio/vnd.wave"
        "audio/ogg"
        "audio/mp4"
      ];
    };
  };
}
