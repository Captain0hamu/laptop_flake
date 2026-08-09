{ pkgs, ... }:

{
  home.username = "nix";
  home.homeDirectory = "/home/nix";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    ripgrep
    fd
  ];

  home.file.".config/oh-my-posh/distrous-nixos.omp.json".source =
    ../files/oh-my-posh/distrous-nixos.omp.json;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Lrnz3318";
      email = "251091shirai@tid.ac.jp";
    };
  };

#  programs.home-manager.enable = true;
  programs.neovim = {
    enable = true;
    withRuby = true;
    withPython3 = true;
    initLua = builtins.readFile ../files/nvim/init.lua;
  };
}
