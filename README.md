# nixos-flake

NixOS and home-manager configuration for this machine, kept together with the
local SDDM theme, virtual-camera support, and a dependency-graph viewer.

## Layout

- `flake.nix`: NixOS and home-manager entry points, plus the `local.nix` loader.
- `configuration.nix`: imports the host system modules.
- `local.nix`: git-ignored secrets and personal data (passwords, git identity).
- `local.nix.example`: committed template for `local.nix`.
- `home/`: home-manager modules and profiles.
- `files/`: files consumed by Nix modules.
- `modules/nixos/`: standalone NixOS modules (boot, bootloader, desktop, ...).
- `scripts/nixos-functions.sh`: shell functions installed through
  `environment.interactiveShellInit`.

## Setup

Copy the template and fill in the secrets before the first rebuild:

```bash
cp local.nix.example local.nix
$EDITOR local.nix
```

`local.nix` is git-ignored. Git-ignored files are invisible to flakes, so the
flake reads it from its absolute path, which requires an impure evaluation.
The rebuild helpers pass `--impure` for you; if you invoke `nixos-rebuild` or
`home-manager` directly, add `--impure` yourself. Without `--impure` the
evaluation fails, and with `--impure` but no `local.nix`, the committed
`local.nix.example` values are used instead.

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

## Dependency graph

`graph/index.html` is a self-contained viewer for this repository's flake
structure. Regenerate the data after changing the configuration or running
`nix flake update`:

```bash
./graph/update.sh
xdg-open graph/index.html
```
