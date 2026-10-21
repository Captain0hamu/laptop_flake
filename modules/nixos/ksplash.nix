{ pkgs, ... }:

let
  sonicSplash = pkgs.runCommand "sonic-ksplash-theme" { } ''
    theme_dir=$out/share/plasma/look-and-feel/org.nixos.sonic.desktop
    mkdir -p "$theme_dir"
    cp -r ${./../../files/ksplash/sonic}/. "$theme_dir"/
  '';
in
{
  environment.systemPackages = [ sonicSplash ];
}
