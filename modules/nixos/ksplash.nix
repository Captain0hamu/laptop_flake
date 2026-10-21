{ pkgs, ... }:

let
  sonicSplash = pkgs.runCommand "sonic-ksplash-theme" { } ''
    theme_dir=$out/share/plasma/look-and-feel/org.nixos.sonic.desktop
    mkdir -p "$theme_dir"
    cp -r ${./../../files/ksplash/sonic}/. "$theme_dir"/
  '';

  sonicSplashSession = pkgs.writeShellScript "sonic-ksplash-session" ''
    set -u
    export PATH="${pkgs.dbus}/bin:$PATH"
    ${pkgs.util-linux}/bin/setsid \
      ${pkgs.coreutils}/bin/timeout 30 \
      ${pkgs.dbus}/bin/dbus-run-session -- \
      ${pkgs.kdePackages.plasma-workspace}/bin/ksplashqml org.nixos.sonic.desktop &
    pid=$!
    wait "$pid" 2>/dev/null || true
    kill -TERM -- -"$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  '';
in
{
  environment.systemPackages = [ sonicSplash ];

  systemd.user.services.plasma-ksplash = {
    description = "Sonic Plasma splash screen";
    partOf = [ "graphical-session.target" ];
    after = [ "plasma-kwin_wayland.service" ];
    serviceConfig = {
      ExecStart = sonicSplashSession;
      Type = "oneshot";
      Slice = "background.slice";
      TimeoutSec = 40;
    };
  };
}
