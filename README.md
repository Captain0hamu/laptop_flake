# nixos-flake

English | [日本語](README.ja.md)

NixOS and home-manager configuration for this machine, kept together with the
local SDDM theme, virtual-camera support, and a dependency-graph viewer. It
also provides shared development shells and Tor Browser.

## Contents

- [Setup](#setup)
- [Common commands](#common-commands)
- [Tor development shell](#tor-development-shell)
- [Assets and reproducibility](#assets-and-reproducibility)
- [Dependency graph](#dependency-graph)
- [Speaker and login appearance](#speaker-and-login-appearance)

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

Copy the template only if you do not already have `local.nix`, then replace
the example values before the first rebuild:

```bash
cp -n local.nix.example local.nix
$EDITOR local.nix
```

`local.nix` is git-ignored. Git-ignored files are invisible to flakes, so the
flake reads it from its absolute path, which requires an impure evaluation.
The rebuild helpers pass `--impure` for you; if you invoke `nixos-rebuild` or
`home-manager` directly, add `--impure` yourself. Without `--impure` the
evaluation fails, and with `--impure` but no `local.nix`, the committed
`local.nix.example` values are used instead.

**Do not use the example passwords:** both hashes correspond to the public
password `changeme`. Replace them with unique password hashes before applying
the configuration, and never commit your real `local.nix` or private keys.
Nix store contents may be readable by other local users; do not put plaintext
secrets in values that become store paths.

## Common commands

| Command | Purpose |
| --- | --- |
| `drybuild` | Check the system build without switching. |
| `rebuild_n_switch` | Build and activate the NixOS configuration. |
| `loadgen` | Build the configuration and select it for the next boot. |
| `switch-dev`, `switch-lab` | Activate the corresponding Home Manager profile. |
| `build-dev`, `build-lab` | Build a Home Manager profile without activating it. |
| `tor-start`, `tor-stop` | Start or stop the shared Tor client. |
| `tor-shell` | Enter the shared Tor development shell. |

The shell functions default to:

```bash
NIXOS_FLAKE_DIR=/home/nix/nixos-flake
NIXOS_FLAKE_HOST=nixos
```

Use `rebuild_n_switch --remote` to evaluate locally and activate the result on
this machine with sudo. It reuses a completed local system if available;
otherwise it builds on the SSH host configured by `remoteBuildHost` in
`local.nix` (or the `NIXOS_BUILD_HOST` environment variable). Configure the
builder's public signing key in `remoteBuildPublicKeys`, and activate the local
configuration before using it. The builder must sign its outputs, support the
target architecture, and accept SSH connections from the invoking user.
Only use a trusted builder: inputs and outputs are shared with it. Without
`--remote`, the helper builds locally.

The login name is `razero` (UID 1000). Its home remains `/home/nix` to keep
existing paths and VM disk mounts working. Home Manager profiles are
`razero@dev` and `razero@lab`. The recovery account `razero-trial` uses UID
1001 and `/home/razero`; it does not receive the main Home Manager profile.

## Tor development shell

Tor Browser is installed as a system package and routes its own browser traffic
through Tor. The separate development shell below is for command-line tools;
it does not use or control Tor Browser's client.

### Start and verify the client

From any working directory, start a Tor client in the background:

```bash
tor-start
```

Check its log and wait for `Bootstrapped 100%` for the current launch (logs
are retained across launches). Press Ctrl-C to stop viewing the log; Tor keeps
running:

```bash
tail -f "$HOME/.local/share/tor-dev-shell/tor.log"
```

Then enter the shared shell without changing the working directory or loading
the local project's dev shell:

```bash
tor-shell
```

These functions are installed with the system shell configuration. To use
them in an existing Bash session before rebuilding, run
`source /home/nix/nixos-flake/scripts/nixos-functions.sh`. Alternatively, enter
the shell directly:

```bash
nix develop /home/nix/nixos-flake#tor --impure
```

The shell provides `tor`, `torsocks`, and `curl`, but does not start Tor or
route commands through it automatically. Run supported commands explicitly
through Tor:

```bash
torsocks curl https://check.torproject.org/api/ip
```

The response should report `"IsTor": true`. Run `exit` to leave the shell;
this does not stop the Tor client. When finished, stop the client separately:

```bash
tor-stop
```

The client uses `127.0.0.1:9050` and stores its state, PID file and log in
`~/.local/share/tor-dev-shell/`. If another Tor client already listens on port
9050, use it instead of starting a second one; `tor-stop` only stops the client
started by `tor-start`.

**Privacy limits:** ordinary commands are not automatically proxied, and
`torsocks` cannot cover every application or UDP traffic. This shell does not
isolate networking or block direct connections. The project's own dev shell
is not automatically combined with the shared Tor shell.

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
## Speaker and login appearance

`home/easyeffects.nix` installs a conservative EQ + gentle compressor preset for
the built-in Fujitsu/Raptor Lake Speaker route only. Start EasyEffects manually
when needed; headphones and HDMI are not assigned this preset. The EQ is
not a measured calibration: adjust its six bands in EasyEffects after listening
at a safe volume. The preset and device-specific autoload file live under
`~/.local/share/easyeffects/`.

SDDM, Plasma's lock screen and KSplash use the same animated background assets
in `files/sddm/Gently-Blur-SDDM-6/anim`. The lock screen keeps Plasma's native
authentication controls, including its recovery behavior. Both successful
password unlock and Plasma's startup splash fade/zoom into the desktop; SDDM
starts the same transition on login success (the display manager may close
before it completes).
