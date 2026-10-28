# Desktop showcase and dependency map

`showcase.html` presents the custom boot/login sequence, the shared Plasma
lock and splash scene, the terminal and editor, and an inline source viewer.
Switch between it and the dependency map using the page navigation. Open it
directly:

```bash
xdg-open graph/showcase.html
```

For an internet-facing deployment, `deploy/update.sh` fetches the public
GitHub `main` branch and atomically publishes only `graph/`, the shared font,
and SDDM animation files. `deploy/nginx.conf` serves that snapshot without
directory listings or links outside the snapshot. The public server runs in a
read-only, unprivileged container on an internal Docker network; Tailscale
Funnel provides HTTPS. Its update timer
runs an independently installed copy of the update script; a GitHub
update does not execute code from the fetched repository. The checked-in
`showcase-data.js` and `dependency-data.js` are published as-is, so regenerate
and commit them when their inputs change.

No npm packages, external fonts or CDN scripts are required. Keep `graph/`
beside `files/` when serving or copying the pages: SDDM frames, the shared
scene source and the shared font are referenced directly from the repository.
The login controls and terminal output are visual examples, not an actual
login or command runner.

The boot player runs a 15.2-second sequence: GRUB, Plymouth, SDDM, the shared
lock/splash scene, then the Plasma title card. Play continues from the current
timeline position; the four chapter tabs seek to a stage. The range input,
stage buttons, play button and shared-scene controls are keyboard accessible.
The lock and splash surfaces share one scene, and **Enter the session** runs
the 850 ms zoom into the desktop card. Chapter deep links are supported:

```text
showcase.html?stage=sddm
showcase.html?stage=shared
showcase.html?stage=shared&mode=splash
```

The English showcase uses `showcase-art-direction.css` for the exhibition
layout and `showcase.css` for the simulated interfaces. Motion includes a
masked title entrance, a scroll-linked photograph, section-title reveals,
stage transitions and the scene handoff. The boot player pauses the sequence;
the page-header control pauses both the sequence and the additional page
motion. `prefers-reduced-motion` starts the page with motion off. The five-value
strip under the player links each number to the file that defines it.

The workspace includes `assets/workspace-redacted.jpg`, derived from
`Screenshot_20261022_105143.png`. The local IP, home path, login details and
session-resume information receive strong baked-in blur; the overall image has
a light blur and metadata is stripped. This is not a CSS-only effect.
Never publish the unmodified screenshot. The HTML/CSS terminal below it uses
an abstract background and static sample values, not a live desktop.
`assets/nix-snowflake.svg` comes from the installed Nix artwork,
recolored to match the terminal's blue/green logo. The terminal/editor tabs
also support Left/Right, Home and End keys. Fastfetch values are static samples.
The Tor feature uses `assets/tor-shell-crop.png`, cropped from the 28 October
2026 terminal screenshot to omit the prompt and project path, with metadata
removed. It is a real capture, not a live Tor status display. Its source
buttons show the allowlisted shell, banner and helper scripts.
The SDDM preview's `assets/sddm-avatar.jpg` is a local copy of the selected
`artworks-jMsWPOeOHp4qXf2j-Jt0oZA-t500x500.jpg` user image.

`node graph/generate-showcase.mjs` updates the frame list, animation timing
and allowlisted source snapshots in `showcase-data.js`. The allowlist covers
the SDDM and Plymouth themes, Plasma's shared scene and Kickoff patch, and the
Home Manager Plasma/EasyEffects modules. It never reads `local.nix` or the
dependency map's generated host data. `./graph/update.sh` updates both pages'
data. Existing changes to `dependency-data.js` do not need to be replaced to
update the showcase alone.

The GRUB and Plymouth previews in `graph/assets/` are tracked snapshots copied
from the built theme outputs. After changing those themes, build the system
and refresh the previews with:

```bash
nix build --impure .#nixosConfigurations.nixos.config.system.build.toplevel
node graph/generate-showcase.mjs --refresh-previews
```

The browser overlays approximate the actual QML/Plymouth UI. They are labelled
as recreations and do not claim to be screenshots or recordings. Animation
can be paused and respects `prefers-reduced-motion`.

`index.html` is a self-contained viewer for this repository's flake structure.
Its evaluated data is stored in `dependency-data.js`, so the page also works
when opened directly with a `file://` URL.

Regenerate the data after changing the configuration or running
`nix flake update`:

```bash
./graph/update.sh
```

The generator has no npm dependencies. It reads `flake.lock` and local Nix
references directly, then uses `nix eval --impure` (required to read the git-ignored `local.nix`) to collect
the effective packages,
systemd units, NixOS configurations, Home Manager configurations, and dev
shell inputs. If Nix evaluation fails, it still writes the lock/static data and
shows the error in the page.

Open the result:

```bash
xdg-open graph/index.html
```

The local-reference scanner is intentionally best-effort: Nix is a dynamic
language, so computed imports cannot always be recovered from source text.
The package and unit lists, in contrast, come from the evaluated module output.
