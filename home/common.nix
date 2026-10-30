{ pkgs, local, ... }:

{
  home.username = "razero";
  home.homeDirectory = "/home/nix";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    gh
    ripgrep
    feather
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
        ConsumeRedundantActivateKeys=True

        [Hotkey/TriggerKeys]
        0=Control+space

        [Hotkey/ActivateKeys]
        0=Henkan

        [Hotkey/DeactivateKeys]
        0=Muhenkan

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
        0=Muhenkan
        1=Henkan
        2=Hiragana_Katakana
      '';
    };
    ".config/fcitx5/conf/mozc.conf" = {
      force = true;
      text = ''
        InitialMode=Hiragana
      '';
    };
    ".config/kitty/kitty.conf".source = ../files/kitty/kitty.conf;
    ".config/fastfetch/config.jsonc".source = ../files/fastfetch/config.jsonc;
    ".bashrc".source = ../files/bash/bashrc;
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
