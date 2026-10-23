# NixOS dependency graph

`showcase.html` presents the custom boot/login sequence, terminal and editor,
with interactive browser recreations and an inline source viewer. Switch
between it and the dependency map using the page navigation. Open it directly:

```bash
xdg-open graph/showcase.html
```

No npm packages, external fonts or CDN scripts are required. Keep `graph/`
beside `files/` when serving or copying the pages: SDDM frames and the shared
font are referenced directly from the repository. The login controls and
terminal output are visual examples, not an actual login or command runner.

The English showcase uses `showcase-art-direction.css` for the exhibition
layout and `showcase.css` for the simulated interfaces. Motion includes a
masked title entrance, a scroll-linked photograph, section-title reveals and
boot-stage wipes. Both motion buttons control the page and boot preview;
`prefers-reduced-motion` disables the additional effects. The system notes
are tucked into a native disclosure below the main previews.

The workspace includes `assets/workspace-redacted.jpg`, derived from
`Screenshot_20261022_105143.png`. The local IP, home path, login details and
session-resume information receive strong baked-in blur; the overall image has
a light blur and metadata is stripped. This is not a CSS-only effect.
Never publish the unmodified screenshot. The HTML/CSS terminal below it uses
an abstract background and static sample values, not a live desktop.
`assets/nix-snowflake.svg` comes from the installed Nix artwork,
recolored to match the terminal's blue/green logo. The terminal/editor tabs
also support Left/Right, Home and End keys. Fastfetch values are static samples.
The SDDM preview's `assets/sddm-avatar.jpg` is a local copy of the selected
`artworks-jMsWPOeOHp4qXf2j-Jt0oZA-t500x500.jpg` user image.

`node graph/generate-showcase.mjs` updates the frame list, animation timing
and allowlisted source snapshots in `showcase-data.js`. It never reads
`local.nix` or the dependency map's generated host data. `./graph/update.sh`
updates both pages' data. Existing changes to `dependency-data.js` do not need
to be replaced to update the showcase alone.

The two files in `graph/assets/` are tracked previews copied from the built
GRUB and Plymouth theme outputs. After changing those themes, build the system
and refresh them with:

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
