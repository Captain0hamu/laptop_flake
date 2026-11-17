{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.cool-retro-term ];

  # Keep the export available for manual import as well.
  home.file.".config/cool-retro-term/profiles/midnight-lilac.json".source =
    ../../files/cool-retro-term/midnight-lilac.json;

  # The app stores the active profile in Qt LocalStorage, not the .conf file.
  # Update only the profile rows, leaving window settings and other profiles alone.
  home.activation.coolRetroTermProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${../../files/cool-retro-term/activate-profile.py} \
      ${../../files/cool-retro-term/midnight-lilac.json}
  '';
}
