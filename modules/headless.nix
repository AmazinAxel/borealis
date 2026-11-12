{ pkgs, lib, ... }: {
  # Servers: smallest closure for fast remote deploys, plus hardening with a small speed cost
  imports = [ ./slim.nix ];
  system.forbiddenDependenciesRegexes = [ "perl" ]; # fail the build if perl sneaks back in (desktop apps need it)
  boot.enableContainers = false; # nixos-container pulls perl
  services.lvm.enable = false;
  fonts.fontconfig.enable = false;
  xdg.icons.enable = false;
  environment.stub-ld.enable = false;

  boot.kernelParams = [
    "slab_nomerge" # heap overflows can't spill into other caches
    "randomize_kstack_offset=on"
    "page_alloc.shuffle=1"
    "debugfs=off"
  ] ++ lib.optional pkgs.stdenv.hostPlatform.isx86_64 "vsyscall=none";
  boot.kernel.sysctl = lib.mapAttrs (_: lib.mkOverride 900) {
    "net.core.bpf_jit_harden" = 2;
    "kernel.yama.ptrace_scope" = 2; # only root can ptrace
    "kernel.perf_event_paranoid" = 3;
    "kernel.io_uring_disabled" = 2; # large attack surface, nothing here uses it
    "vm.unprivileged_userfaultfd" = 0;
  };
  security.protectKernelImage = lib.mkDefault true; # no kexec or hibernation

  # fish without python (fish_config web UI, man page completion parser), from the cached build: no recompile.
  # Copy it, point its self references at the copy, and null out the python3 path embedded in the binaries.
  nixpkgs.overlays = [ (final: prev: {
    fish = prev.runCommand prev.fish.name {
      inherit (prev.fish) passthru meta;
      nativeBuildInputs = [ prev.removeReferencesTo ];
      disallowedReferences = [ prev.python3 prev.man-db prev.fish.doc ]; # docs are off on headless hosts
    } ''
      cp -r --no-preserve=ownership ${prev.fish} $out
      chmod -R u+w $out
      find $out -type f -exec sed -i 's|${prev.fish}|'$out'|g' {} +
      find $out -type f -exec remove-references-to -t ${prev.python3} -t ${prev.man-db} -t ${prev.fish.doc} {} +
      sed -i 's|/nix/store/e\{32\}-[^ ]*||g' $out/nix-support/* # drop nulled propagated inputs (man-db)
    '';
  }) ];
}
