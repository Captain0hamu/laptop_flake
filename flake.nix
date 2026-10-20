{
  description = "NixOS system configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    grub-gtg = {
      url = "git+https://gitlab.com/imnotpua/grub_gtg.git?ref=main";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, grub-gtg, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Secrets and personal data live in ./local.nix, which is git-ignored.
      # See ./local.nix.example for the expected shape. Git-ignored files are
      # invisible to flakes, so this is read from its absolute path and
      # therefore requires an impure evaluation (nixos-rebuild/home-manager
      # are invoked with --impure by scripts/nixos-functions.sh).
      local =
        let
          base =
            let fromEnv = builtins.getEnv "NIXOS_FLAKE_DIR";
            in if fromEnv != "" then fromEnv else "/home/nix/nixos-flake";
          real = /. + "${base}/local.nix";
          example = /. + "${base}/local.nix.example";
        in
        if builtins.pathExists real then import real
        else if builtins.pathExists example then import example
        else throw ''
          Could not read ${base}/local.nix or local.nix.example.
          If local.nix exists, run with --impure: a git-ignored file is only
          visible to an impure evaluation.
        '';

      mkHomeModule = profile: import ./home/default.nix profile;
      mkSystem = profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit local; grubThemeSrc = grub-gtg; };
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = { inherit local; };
              home-manager.users.nix = mkHomeModule profile;
            }
          ];
        };
      mkStandaloneHome = profile:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit local; };
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
