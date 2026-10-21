{ pkgs, local, ... }:

{
  users.users.root.hashedPassword = local.rootHashedPassword;

  # Retain the test account as a recovery login during migration.
  users.users.razero-trial = {
    isNormalUser = true;
    uid = 1001;
    home = "/home/razero";
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "libvirtd" "kvm" ];
    hashedPassword = local.userHashedPassword;
  };

  # Migrated from nix; keep UID and home stable for existing files and VM disks.
  # USER-MIGRATION.md records the migration and recovery procedure.
  users.users.razero = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/nix";
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "libvirtd" "kvm" ];
    hashedPassword = local.userHashedPassword;
    packages = [
      (pkgs.discord-ptb.override {
        commandLineArgs = "--ozone-platform=x11 --force-device-scale-factor=1";
      })
    ];
  };
}
