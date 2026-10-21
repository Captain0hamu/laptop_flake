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
