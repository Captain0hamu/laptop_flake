{ lib, pkgs, ... }:

let
  # Backport google/mozc#1594: Qt 6.12 rejects a leading :: in UI class names.
  mozcForQt = pkgs.mozc.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
        --replace-fail "::mozc::gui::DictionaryContentTableWidget" "mozc::gui::DictionaryContentTableWidget"
    '';
  });
  themeSource = ../../files/sddm/Gently-Blur-SDDM-6;
  themeConfig = pkgs.writeText "theme.conf.user" ''
    [General]
    type=animation
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
      cp ${../../files/fonts/BankGothic.ttf} "$theme_dir/BankGothic.ttf"
    '';
  };
  sharedSplash = pkgs.runCommand "shared-login-splash" { } ''
    dir="$out/share/plasma/look-and-feel/org.razero.shared-login/contents/splash"
    mkdir -p "$dir"
    cp ${../../files/plasma/SharedScene.qml} "$dir/SharedScene.qml"
    cp ${../../files/plasma/Splash.qml} "$dir/Splash.qml"
    cp ${../../files/sddm/Gently-Blur-SDDM-6/AnimatedBackground.qml} "$dir/AnimatedBackground.qml"
    cp -r ${../../files/sddm/Gently-Blur-SDDM-6/anim} "$dir/anim"
    cp ${../../files/plasma/splash-metadata.json} "$out/share/plasma/look-and-feel/org.razero.shared-login/metadata.json"
  '';
in
{
  imports = [ ./plasma-customisation.nix ];

  services = {
    xserver.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "Gently-Blur-SDDM-6";
      extraPackages = [ gentlyBlurTheme ];
      settings.theme.Current = "Gently-Blur-SDDM-6";
      settings.Users.HideUsers = "razero-trial";
    };
    desktopManager.plasma6.enable = true;
  };

  environment = {
    systemPackages = [ gentlyBlurTheme sharedSplash ];
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
      (fcitx5-mozc.override { mozc = mozcForQt; })
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };
}
