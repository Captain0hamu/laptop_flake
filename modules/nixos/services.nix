{ pkgs, unstable, ... }:

{
  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
    };

    tailscale = {
      enable = true;
      package = unstable.tailscale;
      extraSetFlags = [ "--accept-dns=false" ];
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    printing = {
      enable = true;
      drivers = with pkgs; [ cups-browsed cups-filters ];
    };
  };
}
