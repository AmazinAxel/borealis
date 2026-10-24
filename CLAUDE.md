# flake map

NixOS + home-manager flake, user `alec`. Public repo: no private info.

## Wiring
- `flake.nix`: hosts via `genAttrs` → `hosts/<host>/default.nix`; `specialArgs = { inputs }`.
- `hosts/common.nix`: every host (user, sysctl, networkd/iwd, tailscale).
- `modules/desktop.nix`: cachyos kernel, lanzaboote, sway, `screenshot`; imports `tmpfs-root.nix` + `home-manager.nix`, HM `home-manager/home.nix`.
- `modules/laptop.nix`: desktop + printing + bluetooth-audio, HM `home-manager/laptop.nix`.
- `modules/tmpfs-root.nix` → `impermanence.nix` (`/persist`); used by desktop + `pi.nix`.
- `modules/home-manager.nix`: HM NixOS module, `useGlobalPkgs`.

## Hosts
- `alecslaptop`: primary laptop (laptop.nix; hm.nix = monitors, thunderbird, iotas).
- `alecolaptop`: old laptop (laptop.nix; hm.nix = eDP scale).
- `alecpc`: desktop, nvidia (desktop + mcdev + playit).
- `alechomelab`: Pi Zero 2W (pi.nix, services.nix, books.nix, `webserver/` bun js, `scripts/*.fish`).
- `alecdev`: Pi 4B (pi + mcdev + mcscripts, HM fish/helix only).
- `alecvps`: Proxmox LXC, `tracker/` bun service.

## home-manager/
One file per program, all imported in `home.nix`. `sway/{sway,keybinds}.nix`, `claude.nix` (Claude Code settings, statusline, terse style), `ags.nix` (astal packages, `configDir = ../ags`).

## ags/ (Astal/gnim, GTK4, TSX)
- `app.ts`: entry; imports all CSS + widgets, request handler (sway keybinds call `ags request ...`).
- `widgets/`: status bar (`status/`), `sideview.tsx`, launcher, clipboard, notifications, osd, lockscreen, powermenu, pass, record, focus, emojiPicker, workspaces.
- `lib/`: services/helpers (audio, bluetooth, iwd, brightness, sway, mediaPlayer, wallpaper, idle, power, logind, perMonitor, searchDialog).
- Typecheck: `cd ags; nix shell nixpkgs#typescript_5 -c tsc --noEmit -p . | rg -v nix/store`.

## Other
- `nord.nix`: palette. `scripts/`: fish utils (fetch, sys-sync, persist-prune, homelab-update).
- Verify: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`. New files need `git add` first (git+file flake). Never `path:`, never rebuild.
