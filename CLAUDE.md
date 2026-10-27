# borealis map

Opinionated NixOS + home-manager base others import. Public repo: no private info, no hardcoded user/paths. Shell lives in `~/Projects/flurry`, Alec's hosts in `~/Projects/snowflake`.

## Wiring
- `flake.nix`: `nixosModules.{default,home-manager,desktop,laptop,pi}` profiles; `base` sets `_module.args.borealis = inputs`. Upstream modules (HM, impermanence, lanzaboote) are imported in flake.nix, keyed, since `imports` can't use module args. `templates.default`.
- `modules/options.nix`: `borealis.user` (required), `borealis.flake` (default `~/Projects/flake`, used by `nx-switch`). Use `config.borealis.user`, never a literal name.
- `modules/base.nix`: every host (sysctl, networkd/iwd, tailscale, nix settings).
- `modules/desktop.nix`: cachyos kernel, lanzaboote, sway, `screenshot`; imports `tmpfs-root.nix` + `home-manager.nix`, HM `home-manager/home.nix`.
- `modules/laptop.nix`: desktop + printing + bluetooth-audio, HM `home-manager/laptop.nix`.
- `modules/tmpfs-root.nix` → `impermanence.nix` (`/persist`); used by desktop + `pi.nix`.
- `modules/home-manager.nix`: HM settings, `useGlobalPkgs`, passes `borealis` to HM.

## home-manager/
One file per program, all imported in `home.nix`. `sway/{sway,keybinds}.nix`, `claude.nix`, `flurry.nix` (enables flurry). Paths via `config.home.homeDirectory` / `config.xdg.userDirs`.

## Other
- `nord.nix`: palette. `scripts/`: fish utils (fetch, persist-prune, nx-gc).
- Verify from snowflake: `nix eval --no-write-lock-file --override-input borealis git+file:///home/alec/Projects/borealis .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`. New files need `git add` first. Never `path:`, never rebuild.
