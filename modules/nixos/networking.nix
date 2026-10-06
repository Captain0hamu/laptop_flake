{ ... }:

{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  hardware = {
    wirelessRegulatoryDatabase = true;
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
