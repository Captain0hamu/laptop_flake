{ lib, ... }:

{
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/home/nix/lab" = {
    device = "/dev/disk/by-uuid/c21c9a3b-376e-4450-97d3-d199a9bfac8e";
    fsType = "ext4";
  };

  fileSystems."/home/nix/lab/vms" = {
    device = "/dev/disk/by-uuid/c72eb9dd-7720-4ad9-99b4-cce96c21e316";
    fsType = "ext4";
  };
}
