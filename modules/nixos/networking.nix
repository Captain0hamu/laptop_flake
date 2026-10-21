{ ... }:

{
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      # Disable Wi-Fi power saving while investigating intermittent disconnects.
      wifi.powersave = false;
      # Record connection transitions and disconnect reasons for diagnosis.
      logLevel = "INFO";
    };
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
