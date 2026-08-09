{ pkgs, ... }:

{
  imports = [
    ./ai-cli.nix
  ];

  home.packages = with pkgs; [
    nodejs
    gcc
    gnumake
    hadolint
    docker-compose
    ardour
    obs-studio
  ];
}
