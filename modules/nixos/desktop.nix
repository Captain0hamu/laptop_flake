{ lib, pkgs, ... }:

let
  background = ../../files/sddm/dmc-login-bg.jpg;
  themeSource = ../../files/sddm/Gently-Blur-SDDM-6;
  themeConfig = pkgs.writeText "theme.conf.user" ''
    [General]
    background=${toString background}
    type=image
    showlogo=hidden
    showClock=true
    fontSize=10
    needsFullUserModel=false
  '';
  gentlyBlurTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "gently-blur-sddm-theme";
    version = "2025-04-28";
    dontUnpack = true;

    installPhase = ''
      theme_dir="$out/share/sddm/themes/Gently-Blur-SDDM-6"
      mkdir -p "$theme_dir"
      cp -r ${themeSource}/. "$theme_dir"/
      chmod -R u+w "$theme_dir"
      rm -f "$theme_dir/theme.conf.user"
      cp ${themeConfig} "$theme_dir/theme.conf.user"
    '';
  };
in
{
  services = {
    xserver.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "Gently-Blur-SDDM-6";
      extraPackages = [ gentlyBlurTheme ];
      settings.theme.Current = "Gently-Blur-SDDM-6";
    };
    desktopManager.plasma6.enable = true;
  };

  environment = {
    systemPackages = [ gentlyBlurTheme ];
    etc."sddm.conf.d/kde_settings.conf".text = lib.mkForce ''
      [Theme]
      Current=Gently-Blur-SDDM-6
      CursorTheme=breeze_cursors
      Font=Noto Sans,10,-1,0,400,0,0,0,0,0,0,0,0,0,0,1

      [Users]
      MinimumUid=1000
      MaximumUid=30000
    '';
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };
}
