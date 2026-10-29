# borealis map

Opinionated NixOS + home-manager base others import. Public repo: no private info, no hardcoded user/paths. Shell lives in `~/Projects/flurry`, Alec's hosts in `~/Projects/snowflake`.

## Wiring
- `flake.nix`: `nixosModules.{default,desktop,laptop,pi}` profiles (all but default include HM + impermanence); `base` sets `_module.args.borealis = inputs`. Upstream modules (HM, impermanence, lanzaboote) are imported in flake.nix, keyed, since `imports` can't use module args. `templates.default`.
- `modules/options.nix`: `borealis.user` (required), `borealis.flake` (default `~/Projects/flake`, used by `nx-switch`). Use `config.borealis.user`, never a literal name.
- `modules/base.nix`: every host (sysctl, networkd/iwd, nix settings).
- `modules/desktop.nix`: cachyos kernel, lanzaboote, sway, `screenshot`; imports `tmpfs-root.nix` (HM via flake profile), HM `home-manager/home.nix`.
- `modules/laptop.nix`: desktop + bluetooth + tlp, HM `home-manager/laptop.nix`.
- `modules/tmpfs-root.nix` → `impermanence.nix` (`/persist`); used by desktop + `pi.nix`.
- `apps/<name>.nix`: opt-in NixOS modules, auto-exported as `nixosModules.<name>`. Each bundles package, HM config (`home-manager.users.${user}`) and persistence for one app.
- `modules/home-manager.nix`: HM settings, `useGlobalPkgs`, passes `borealis` to HM.

## home-manager/
One file per program, all imported in `home.nix`. `sway/{sway,keybinds}.nix`, `flurry.nix` (enables flurry). Paths via `config.home.homeDirectory` / `config.xdg.userDirs`.

## Other
- `nord.nix`: palette. `scripts/`: fish utils (fetch, persist-prune, nx-gc).
- Verify from snowflake: `nix eval --no-write-lock-file --override-input borealis git+file:///home/alec/Projects/borealis .#nixosConfigurations.<host>.config.<changed option>`; `system.build.toplevel.drvPath` only when asked. New files need `git add` first. Never `path:`, never rebuild.
