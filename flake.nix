{
 description = "NixOS system configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darkmatter-grub-theme = {
      url = "github:VandalByte/darkmatter-grub2-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
};

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, home-manager, darkmatter-grub-theme, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkHomeModule = profile: import ./home/default.nix profile;
      mkSystem = profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit unstable;
          };
          modules = [
            darkmatter-grub-theme.nixosModule
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.users.nix = mkHomeModule profile;
            }
            (
              { lib, ... }:
              {
                boot.loader = {
                  systemd-boot.enable = lib.mkForce false;
                  grub = {
                    enable = true;
                    efiSupport = true;
                    device = "nodev";
                    darkmatter-theme = {
                      enable = true;
                      style = "nixos";
                      icon = "color";
                      resolution = "1440p";
                    };
                  };
                };
              }
            )
          ];
        };
      mkStandaloneHome = profile:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ (mkHomeModule profile) ];
        };
    in {
      nixosConfigurations = {
        nixos = mkSystem "dev";
        nixos-dev = mkSystem "dev";
        nixos-lab = mkSystem "lab";
      };
      homeConfigurations = {
        "nix@dev" = mkStandaloneHome "dev";
        "nix@lab" = mkStandaloneHome "lab";
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          dotnet-sdk_10
          csharp-ls
          netcoredbg
        ];
        DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      };

    };
}
