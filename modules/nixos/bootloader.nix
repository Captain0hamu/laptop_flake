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
  # Keep the selected graphical menu visible until the kernel takes over.
  nixpkgs.overlays = [
    (final: prev: {
      grub2 = prev.grub2.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../files/grub/keep-menu-on-boot.patch ];
      });
    })
  ];

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
      # The theme supplies its own background. The default NixOS splash is
      # otherwise exposed when GRUB leaves the graphical menu.
      splashImage = null;
      backgroundColor = "#000000";
      gfxpayloadEfi = "keep";
      extraConfig = ''
        set keep_menu_on_boot=1
        background_color '#000000'
      '';
    };
  };
}
