# NixOS dependency graph

`index.html` is a self-contained viewer for this repository's flake structure.
Its evaluated data is stored in `dependency-data.js`, so the page also works
when opened directly with a `file://` URL.

Regenerate the data after changing the configuration or running
`nix flake update`:

```bash
./graph/update.sh
```

The generator has no npm dependencies. It reads `flake.lock` and local Nix
references directly, then uses `nix eval` to collect the effective packages,
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
