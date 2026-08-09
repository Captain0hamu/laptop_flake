# nixos-flake

NixOS and home-manager configuration collected from `/etc/nixos`, with the local `codex-neovim` and `codex-grub-loader` work folded into this repository.

## Layout

- `flake.nix`: NixOS and home-manager entry points.
- `configuration.nix`: host system configuration.
- `home/`: home-manager modules and profiles.
- `files/`: files consumed by Nix modules.
- `modules/`: standalone NixOS modules kept for reuse.
- `scripts/nixos-functions.sh`: shell functions installed through `environment.interactiveShellInit`.

## Common Commands

```bash
drybuild
rebuild_n_switch
loadgen
switch-dev
switch-lab
build-dev
build-lab
```

The shell functions default to:

```bash
NIXOS_FLAKE_DIR=/home/nix/nixos-flake
NIXOS_FLAKE_HOST=nixos
```
