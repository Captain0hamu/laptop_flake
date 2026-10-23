{ pkgs, ... }:

let
  # Kickoff selection colors. Native popup/panel transparency is in home/plasma.nix.
  launcherStyle = {
    accentColor = "#cfbea5";
    selectionOpacity = "0.25";
  };
in
{
  # Plasma 6.8 embeds Kickoff QML in its applet plugin, so patch it at build time.
  # This keeps the existing launcher, favorites and key bindings intact.
  nixpkgs.overlays = [
    (_final: prev: {
      kdePackages = prev.kdePackages.overrideScope (_kdeFinal: kdePrev: {
        plasma-desktop = kdePrev.plasma-desktop.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            (pkgs.replaceVars ../../files/plasma/kickoff.patch launcherStyle)
          ];
          postPatch = (old.postPatch or "") + ''
            cp ${../../files/plasma/LauncherHighlight.qml} applets/kickoff/LauncherHighlight.qml
            cp ${../../files/plasma/LauncherToolButton.qml} applets/kickoff/LauncherToolButton.qml
            cp ${../../files/plasma/LauncherTabButton.qml} applets/kickoff/LauncherTabButton.qml
          '';
        });
      });
    })
  ];
}
