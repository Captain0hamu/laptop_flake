{ pkgs, local, ... }:

{
  users.users.root.hashedPassword = local.rootHashedPassword;

  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "docker" "networkmanager" "libvirtd" "kvm" ];
    hashedPassword = local.userHashedPassword;
    packages = [
      (pkgs.discord-ptb.override {
        commandLineArgs = "--ozone-platform=x11 --force-device-scale-factor=1";
      })
    ];
  };
}
