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
NIXOS_BUILD_HOST=nixos@100.81.40.56
```

Use `rebuild_n_switch --remote` to evaluate locally and activate the result on
this machine with sudo. It reuses a completed local system if available;
otherwise it builds on the SSH host. Set `NIXOS_BUILD_HOST` to use another
builder. SSH access must work as
the invoking user; the builder must accept the Nix store paths and support the
target architecture. Build inputs and outputs are copied to the builder, so
only use a trusted machine: any secrets included in Nix store paths are shared.
Without `--remote`, the helper continues to build locally.

The local Nix daemon trusts the public key `nixos-tailscale-builder-1` declared
in `modules/nixos/base.nix`. The remote daemon must be configured to sign builds
with its matching private key via `nix.settings.secret-key-files`. Activate that
configuration on the builder, and activate this local configuration once with
the normal local rebuild, before using `--remote`. Keep the private key outside
the Nix store and readable only by root. Trusting this key allows the builder to
supply store paths used by the local system; it must remain a trusted host.

The login name is `razero` (UID 1000). Its home remains `/home/nix` to keep
existing paths and VM disk mounts working. Home Manager profiles are
`razero@dev` and `razero@lab`. The recovery account `razero-trial` uses UID
1001 and `/home/razero`; it does not receive the main Home Manager profile.

## Assets and reproducibility

SDDM's animated background reads `anim/frames.js` and `anim/*.jpg` relative to
`files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml`. All 26 frames and
`anim/scanlines.png` are tracked here; the theme does not read `~/Downloads`.
The desktop module copies the whole theme into the Nix store at build time.

`files/fonts/BankGothic.ttf` is the shared font for GRUB, Plymouth and SDDM.
Plymouth's source images are in `files/plymouth/gtg/assets/`. These assets are
regular repository files, not symlinks into a user's home directory.

Neovim plugins and its Bash, C, C#, C++, CSS, HTML, JavaScript, JSON, Nix and
Python Tree-sitter parsers are declared in `home/neovim.nix`. Their versions
follow `flake.lock`; starting Neovim does not clone plugins or run `TSUpdate`.
The `dl-msc` helper also uses the Nix-managed `yt-dlp` package and writes to
`$HOME/Downloads/m4a`.

Nixpkgs, Home Manager and the upstream GRUB theme remain fetched inputs pinned
in `flake.lock`. They do not depend on files outside this checkout. The
remaining host-specific configuration includes `local.nix`, the home directory
and user name, and disk UUIDs/mounts in `hardware-configuration.nix` and
`modules/nixos/filesystems.nix`. For a checkout in a different location, set
`NIXOS_FLAKE_DIR` to its absolute path when evaluating the impure flake.

## Dependency graph

Open `graph/showcase.html` for an interactive tour of the custom GRUB,
Plymouth, SDDM, terminal and editor. It links to the dependency map and shows
the relevant configuration without leaving the page. See `graph/README.md`
for refreshing source snapshots and theme previews.

`graph/index.html` is a self-contained viewer for this repository's flake
structure. Regenerate the data after changing the configuration or running
`nix flake update`:

```bash
./graph/update.sh
xdg-open graph/index.html
```
# Speaker and login appearance

`home/easyeffects.nix` installs a conservative EQ + gentle compressor preset for
the built-in Fujitsu/Raptor Lake Speaker route only. EasyEffects starts with the
graphical session; headphones and HDMI are not assigned this preset. The EQ is
not a measured calibration: adjust its six bands in EasyEffects after listening
at a safe volume. The preset and device-specific autoload file live under
`~/.local/share/easyeffects/`.

SDDM, Plasma's lock screen and KSplash use the same animated background assets
in `files/sddm/Gently-Blur-SDDM-6/anim`. The lock screen keeps Plasma's native
authentication controls, including its recovery behavior. Both successful
password unlock and Plasma's startup splash fade/zoom into the desktop; SDDM
starts the same transition on login success (the display manager may close
before it completes).
