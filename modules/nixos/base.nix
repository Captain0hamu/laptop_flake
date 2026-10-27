{ ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = 1;
    cores = 2;
    extra-trusted-public-keys = [
      "nixos-tailscale-builder-1:MCRmLODczdcmIecEDeEbFsjFRmeTu0YU4vXfMrQDEfQ="
    ];
  };

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  system.stateVersion = "25.05";
}
