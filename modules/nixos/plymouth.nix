{ pkgs, ... }:

let
  gtgPlymouthTheme = pkgs.runCommand "plymouth-theme-gtg" {
    nativeBuildInputs = [ pkgs.imagemagick pkgs.dejavu_fonts ];
  } ''
    themeDir=$out/share/plymouth/themes/gtg
    src=${./../../files/plymouth/gtg/assets}
    bank=$src/BankGothic.ttf
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
  boot.initrd.verbose = false;

  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    "vt.global_cursor_default=0"
  ];

  boot.plymouth = {
    enable = true;
    theme = "gtg";
    themePackages = [ gtgPlymouthTheme ];
  };
}
