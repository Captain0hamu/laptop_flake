{ pkgs, ... }:

{
  users.users.root.hashedPassword = "$6$D1yPR195la2OcHsV$ux/cvoQRyea.DCuZDNMZIEbnggw4NJaYWJm2nz98X49OsJ.ip9/MfKVMEJc9tw3K/dJ5W3lBsnV3pV1Mf8E1G0";

  users.users.nix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "networkmanager" "libvirtd" "kvm" ];
    hashedPassword = "$6$D1yPR195la2OcHsV$ux/cvoQRyea.DCuZDNMZIEbnggw4NJaYWJm2nz98X49OsJ.ip9/MfKVMEJc9tw3K/dJ5W3lBsnV3pV1Mf8E1G0";
    packages = [
      (pkgs.discord-ptb.override {
        commandLineArgs = "--ozone-platform=x11 --force-device-scale-factor=1";
      })
    ];
  };
}
