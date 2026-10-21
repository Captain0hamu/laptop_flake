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
