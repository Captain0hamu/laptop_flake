{ lib, ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
      sshProxy = false;
    };
    docker.enable = true;

    vmVariant = {
      fileSystems."/home/nix/lab" = lib.mkForce {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "mode=755" "size=256M" ];
      };

      boot.initrd.kernelModules = [ "bochs" "virtio_gpu" ];

      services.displayManager.sddm.wayland.enable = lib.mkForce false;

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        graphics = true;
        resolution = {
          x = 1600;
          y = 900;
        };
      };
    };
  };
}
