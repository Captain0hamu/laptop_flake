{ pkgs, local, ... }:

{
  home.username = "nix";
  home.homeDirectory = "/home/nix";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    gh
    ripgrep
    fd
    yt-dlp
  ];

  home.file.".config/oh-my-posh/distrous-nixos.omp.json".source =
    ../files/oh-my-posh/distrous-nixos.omp.json;

  home.file = {
    ".config/fcitx5/config" = {
      force = true;
      text = ''
        [Hotkey]
        AltTriggerKeys=

        [Hotkey/TriggerKeys]
        0=Control+space

        [Behavior]
        PreeditEnabledByDefault=False
        ShowInputMethodInformation=False
        CompactInputMethodInformation=False
        ShowFirstInputMethodInformation=False
      '';
    };
    ".config/fcitx5/profile" = {
      force = true;
      text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=mozc

        [Groups/0/Items/0]
        Name=keyboard-us

        [Groups/0/Items/1]
        Name=mozc

        [Groups/0/Items/2]
        Name=keyboard-ru-ruintl_ru

        [GroupOrder]
        0=Default
      '';
    };
    ".config/fcitx5/conf/imselector.conf" = {
      force = true;
      # SwitchKey entries correspond to the input methods in profile, in order.
      text = ''
        [SwitchKey]
        0=Henkan
        1=Muhenkan
        2=Hiragana_Katakana
      '';
    };
    ".config/kitty/kitty.conf".source = ../files/kitty/kitty.conf;
    ".config/fastfetch/config.jsonc".source = ../files/fastfetch/config.jsonc;
    ".bashrc".source = ../files/bash/bashrc;
    ".config/ksplashrc" = {
      force = true;
      text = ''
        [KSplash]
        Engine=none
        Theme=None
      '';
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = local.gitName;
      email = local.gitEmail;
    };
  };

#  programs.home-manager.enable = true;
}
