{ config, ... }:

{
  boot = {
    kernelModules = [ "v4l2loopback" ];

    extraModulePackages = [
      (config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
        # NixOS runs depmod on the merged module tree. Avoid generating empty
        # builtin indexes here that collide with the kernel's own indexes.
        makeFlags = old.makeFlags ++ [ "DEPMOD=true" ];
      }))
    ];

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="Virtual Camera" exclusive_caps=1
    '';
  };
}
