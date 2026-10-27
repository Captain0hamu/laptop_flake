{ config, lib, pkgs, ... }:

let
  plymouthdConf = ../../files/plymouth/plymouthd.conf;

  gtgPlymouthTheme = pkgs.runCommand "plymouth-theme-gtg" {
    nativeBuildInputs = [ pkgs.imagemagick pkgs.dejavu_fonts ];
  } ''
    themeDir=$out/share/plymouth/themes/gtg
    src=${./../../files/plymouth/gtg/assets}
    bank=${../../files/fonts/BankGothic.ttf}
    dejavu=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans.ttf
    dejavu_bold=${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf
    export themeDir src bank dejavu dejavu_bold

    mkdir -p "$themeDir"
    bash ${./../../files/plymouth/gtg/generate-assets.sh}

    install -m644 ${./../../files/plymouth/gtg/gtg.script} "$themeDir/gtg.script"
    install -m644 ${./../../files/plymouth/gtg/gtg.plymouth.in} "$themeDir/gtg.plymouth"
    substituteInPlace "$themeDir/gtg.plymouth" \
      --subst-var-by themeDir "$themeDir"
  '';
in
{
  boot.initrd.kernelModules = [ "i915" ];

  boot.consoleLogLevel = 0;

  boot.kernelParams = [
    "quiet"
    "logo.nologo"
    # Clear the bootloader framebuffer before Plymouth starts. Otherwise quiet
    # boot can leave it untouched and expose it again during later VT switches.
    "fbcon=nodefer"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
    "systemd.show_status=false"
    "rd.systemd.show_status=false"
  ];

  systemd.settings.Manager.ShowStatus = false;
  boot.initrd.systemd.settings.Manager.ShowStatus = false;

  systemd.services.mute-status = {
    description = "Mute systemd status output";
    wantedBy = [ "sysinit.target" ];
    after = [ "dbus.service" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/busctl call org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager SetShowStatus s no";
    };
  };

  boot.plymouth = {
    enable = true;
    theme = "gtg";
    themePackages = [ gtgPlymouthTheme ];
  };

  environment.etc."plymouth/plymouthd.conf".source = lib.mkForce plymouthdConf;
  boot.initrd.systemd.contents."/etc/plymouth/plymouthd.conf".source = lib.mkForce plymouthdConf;

  systemd.services.plymouth-quit.serviceConfig.ExecStart =
    lib.mkForce [
      # Reset the upstream oneshot command instead of running both commands.
      ""
      # Match upstream: the daemon may already be gone during rebuild switch.
      "-${config.boot.plymouth.package}/bin/plymouth quit --retain-splash"
    ];
}
