{ config, pkgs, ... }: let
  libfprint = pkgs.libfprint.overrideAttrs {
    src = pkgs.fetchgit {
      url = "https://gitlab.freedesktop.org/depau/libfprint.git";
      rev = "11f0316d069cc90c154c8cb0e46478388c5e2a74";
      hash = "sha256-dxMls9Z5J9agesuNC46OoXAiYW/GcqWEEiAF7Y7DfwQ=";
    };
    patches = [(pkgs.fetchpatch {
      url = "https://raw.githubusercontent.com/wateenellende/hp-elan-0c00-linux/9f067840f7cdb3d426a137bd7620623eb1b66b5c/libfprint/0001-elanmoc2-Fix-protocol-handling-for-04f3-0c00-and-res.patch";
      hash = "sha256-PqZ749httIxRv2147UhlGQj8/UMMIoTn/5FjI8Fl+vQ=";
    })];
    installCheckPhase = "true";
  };
in {
  services.fprintd = {
    enable = true;
    package = pkgs.fprintd.override { inherit libfprint; };
  };
  security.pam.services = {
    astal-auth.fprintAuth = false; # lockscreen password only
    # ags lockscreen
    astal-fprint.text = ''
      auth sufficient ${config.services.fprintd.package}/lib/security/pam_fprintd.so timeout=10
      auth required pam_deny.so
      account required pam_permit.so
    '';
  };
  environment.persistence."/persist".directories = [ "/var/lib/fprint" ];
}
