# borealis

A hyperfocused, keyboard-oriented NixOS configuration: sway, the [flurry](https://github.com/AmazinAxel/flurry) shell, tmpfs root, Nord everywhere.

```fish
nix flake init -t github:AmazinAxel/borealis
```

Set `borealis.user`, pick a profile (`desktop`, `laptop`, `pi`, or just `default`), add your `hardware-configuration.nix` and you're done. Keep the flake at `~/Projects/flake` (or set `borealis.flake`) so `nixos-rebuild switch` finds it.

Before first boot: mount `/persist`, put your password hash in `/persist/passwords/<user>` (`mkpasswd`), and `sbctl create-keys` for secure boot on desktops.

## [Learn more at the Wiki](https://github.com/AmazinAxel/borealis/wiki)
