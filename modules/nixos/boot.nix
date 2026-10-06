{ lib, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 60;
    };
    kernelModules = [ "kvm-amd" ];
  };
}
