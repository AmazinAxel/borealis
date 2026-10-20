{ pkgs, inputs, ... }:

# Auto-convert EPUBs for the wintergreen e-reader.
#
# Drop a .epub into /media/books over Samba; a path unit notices and converts it
# into /media/books/.compiled/<stem>/. The reader pulls only the compiled form
# over HTTP (see webserver/booksync.js), so it never parses an EPUB itself and
# never sees the originals.

let
  epub2wgb = inputs.wintergreen.packages.aarch64-linux.epub2wgb;
in {
  systemd.tmpfiles.rules = [
    "d /media/books 0775 alec users -"
    "d /media/books/.compiled 0775 alec users -"
  ];

  systemd.paths.book-convert = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      # PathChanged, not DirectoryNotEmpty. DirectoryNotEmpty is a *level*, not
      # an edge: it re-triggers for as long as the directory has anything in it,
      # so the service restarted the instant it finished, forever, until
      # systemd's rate limiter killed it mid-run with start-limit-hit. The
      # alphabetically last book never got converted.
      #
      # PathChanged fires on close-after-write, so a Samba upload triggers it
      # once. Writes land in .compiled/, which is a separate directory and does
      # not re-arm this.
      PathChanged = "/media/books";
      MakeDirectory = false;
    };
  };

  systemd.services.book-convert = {
    path = [ epub2wgb pkgs.fish ];
    # Backstop against a retrigger loop: converting is idempotent and skips
    # up-to-date books, so a few redundant runs are harmless, but they should
    # never be able to spin. Without this a mistake in the path unit becomes a
    # failed service rather than a slow one.
    startLimitIntervalSec = 60;
    startLimitBurst = 10;
    serviceConfig = {
      Type = "oneshot";
      # A Pi Zero 2 shares this machine with the air-quality webserver, and a
      # conversion is CPU- and IO-heavy for tens of seconds. Never let it stall
      # the thing people actually look at.
      Nice = 15;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
    script = ''
      fish ${./scripts/convertBooks.fish}
    '';
  };
}
