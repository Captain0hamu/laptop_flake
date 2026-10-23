{ lib, pkgs, ... }:

let
  # 40% transparent = 60% opaque. Only background SVG fills are changed.
  backgroundOpacity = "0.60";
  themeName = "personal-translucent";
  plasmaTheme = pkgs.runCommand "plasma-theme-${themeName}" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python ${../files/plasma/build-translucent-theme.py} \
      ${pkgs.kdePackages.libplasma}/share/plasma/desktoptheme/default \
      "$out" ${backgroundOpacity}
  '';
in
{
  home.file.".local/share/plasma/desktoptheme/${themeName}".source = plasmaTheme;

  # Set only the theme key; preserve wallpaper choices and other Plasma settings.
  home.activation.plasmaTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file plasmarc --group Theme --key name ${themeName} --notify
  '';
}
