{ config, lib, ... }:

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

    kernelModules = [ "v4l2loopback" ];

    extraModulePackages = [
      config.boot.kernelPackages.v4l2loopback
    ];

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="Virtual Camera" exclusive_caps=1
    '';
  };
}
