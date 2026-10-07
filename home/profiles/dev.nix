{ pkgs, ... }:

{
  imports = [
    ./ai-cli.nix
  ];

  home.packages = with pkgs; [
    nodejs
    gnumake
    hadolint
    docker-compose
    ardour
    obs-studio
  ];
}
