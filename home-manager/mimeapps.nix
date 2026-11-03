{ lib, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.concatMapAttrs (app: mimes: lib.genAttrs mimes (_: app)) {
      "org.gnome.FileRoller.desktop" = [
        "application/zip"
      ];
      "org.gnome.gthumb.desktop" = [
        "image/png"
        "image/apng"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/svg+xml"
        "image/jxl"
        "image/heif"
        "image/heic"
        "image/avif"
        "image/tiff"
        "image/x-canon-cr2"
        "image/x-canon-crw"
        "image/x-fuji-raf"
        "image/x-dcraw"
        "image/x-olympus-orf"
        "image/x-xcf"
        "image/vnd.adobe.photoshop"
        "video/mp4"
        "video/mpeg"
        "video/3gpp"
        "video/3gpp2"
        "video/x-matroska"
        "video/webm"
        "video/vnd.avi"
        "video/x-msvideo"
        "video/quicktime"
        "audio/mpeg"
        "audio/flac"
        "audio/vnd.wave"
        "audio/wav"
        "audio/ogg"
        "audio/mp4"
        "audio/x-matroska"
      ];
    };
  };
}
