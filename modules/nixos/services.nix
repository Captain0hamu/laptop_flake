{ pkgs, ... }:

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
      package = pkgs.tailscale;
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
    # For class, use ~/Documents/database/flake.nix instead: its MySQL server
    # runs locally in that devShell and does not need a system-wide service.
    # Uncomment this only if a separate, always-on system MySQL is needed.
    # mysql = {
    #   enable = true;
    #   package = pkgs.mysql84;
    # };
  };
}
