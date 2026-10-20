{ lib, pkgs, grubThemeSrc, ... }:

let
  grubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "grub-gtg-theme";
    version = "unstable";

    src = grubThemeSrc;

    nativeBuildInputs = [ pkgs.grub2 ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp assets/images/background.png $out/background.png
      cp assets/menu/menu_*.png $out/
      cp assets/selection/select_*.png $out/
      cp assets/scrollbar/scrollbar_thumb_c.png $out/
      cp assets/theme.txt $out/theme.txt
      grub-mkfont -s 23 -b assets/fonts/BankGothic.ttf -o $out/bankgothic.pf2
      runHook postInstall
    '';
  };
in
{
  boot.loader = {
    systemd-boot = {
      enable = lib.mkForce false;
      editor = false;
    };

    efi.canTouchEfiVariables = true;
    timeout = 60;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      theme = grubTheme;
    };
  };
}
