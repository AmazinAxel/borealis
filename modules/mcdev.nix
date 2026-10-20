{ pkgs, lib, config, ... }:
let
  cfg = config.mcdev;

  fifo = "/run/minecraft/console.stdin";

  # https://api.purpurmc.org/v2/purpur/<mcVersion>/latest
  # nix-prefetch-url https://api.purpurmc.org/v2/purpur/<mcVersion>/<build>/download
  mcVersion = "26.2";
  build = "2633";

  purpurmc = pkgs.stdenvNoCC.mkDerivation {
    pname = "purpurmc";
    version = "${mcVersion}-${build}";

    src = pkgs.fetchurl {
      url = "https://api.purpurmc.org/v2/purpur/${mcVersion}/${build}/download";
      hash = "sha256-QffAU1wc7Eft5I0lyNm9fwU9TcRPhyk+WgBzFNvPwyw=";
    };

    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    dontUnpack = true;
    preferLocalBuild = true;
    allowSubstitutes = false;

    installPhase = ''
      runHook preInstall

      install -D $src $out/share/purpurmc/purpurmc.jar

      makeWrapper ${lib.getExe pkgs.openjdk25} "$out/bin/minecraft-server" \
        --append-flags "-jar $out/share/purpurmc/purpurmc.jar nogui" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.udev ]}

      runHook postInstall
    '';

    meta = {
      description = "Drop-in replacement for Paper with additional configuration";
      homepage = "https://purpurmc.org/";
      sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
      license = lib.licenses.mit; # Purpur's patches; upstream Paper is GPLv3
      platforms = lib.platforms.unix;
      mainProgram = "minecraft-server";
    };
  };

  jvmOpts = [ # flags
    "-Xms${toString cfg.heapMB}M" "-Xmx${toString cfg.heapMB}M"
    "-XX:+UseG1GC" "-XX:+ParallelRefProcEnabled" "-XX:MaxGCPauseMillis=200"
    "-XX:+UnlockExperimentalVMOptions" "-XX:+DisableExplicitGC" "-XX:+AlwaysPreTouch"
    "-XX:G1HeapWastePercent=5" "-XX:G1MixedGCCountTarget=4"
    "-XX:InitiatingHeapOccupancyPercent=15" "-XX:G1MixedGCLiveThresholdPercent=90"
    "-XX:G1RSetUpdatingPauseTimePercent=5" "-XX:SurvivorRatio=32"
    "-XX:+PerfDisableSharedMem" "-XX:MaxTenuringThreshold=1"
    "-XX:G1NewSizePercent=30" "-XX:G1MaxNewSizePercent=40"
    "-XX:G1HeapRegionSize=8M" "-XX:G1ReservePercent=20"
  ];
in {
  options.mcdev = {
    enable = lib.mkEnableOption "Purpur Minecraft server with a console fifo";

    serverDir = lib.mkOption {
      type = lib.types.str;
    };

    heapMB = lib.mkOption {
      type = lib.types.int;
      default = 4096;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [

      # see & type in console
      (pkgs.writeShellScriptBin "mc" ''
        if [ $# -gt 0 ]; then
          printf '%s\n' "$*" > ${fifo}
          exit
        fi

        journalctl -fu minecraft-server -o cat -n 50 &
        trap 'kill %1 2> /dev/null' EXIT

        while IFS= read -r line; do
          printf '%s\n' "$line" > ${fifo}
        done
      '')
    ];

    systemd.services.minecraft-server = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        User = "alec";
        Group = "users";
        WorkingDirectory = cfg.serverDir;
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "minecraft";

        # mc command
        ExecStartPre = "${pkgs.coreutils}/bin/mkfifo -m 0600 ${fifo}";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep infinity > ${fifo} & exec ${purpurmc}/bin/minecraft-server ${lib.concatStringsSep " " jvmOpts} < ${fifo}'";
        ExecStop = "${pkgs.bash}/bin/bash -c 'echo stop > ${fifo}'";

        TimeoutStopSec = 90; # for saving
      };

      preStart = ''
        echo "eula=true" > ${cfg.serverDir}/eula.txt
      '';
    };

    networking.firewall = {
      allowedTCPPorts = [ 25565 ];
      allowedUDPPorts = [ 25565 ];
    };
  };
}
