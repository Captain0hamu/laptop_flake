{ lib, ... }:

{
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
      darkmatter-theme = {
        enable = true;
        style = "nixos";
        icon = "color";
        resolution = "1440p";
      };
    };
  };
}
