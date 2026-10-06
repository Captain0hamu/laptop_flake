{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/nixos/base.nix
    ./modules/nixos/boot.nix
    ./modules/nixos/filesystems.nix
    ./modules/nixos/networking.nix
    ./modules/nixos/audio.nix
    ./modules/nixos/desktop.nix
    ./modules/nixos/services.nix
    ./modules/nixos/virtualisation.nix
    ./modules/nixos/users.nix
    ./modules/nixos/packages.nix
    ./modules/nixos/shell.nix
  ];
}
