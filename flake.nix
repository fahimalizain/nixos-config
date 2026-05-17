{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin-unstable = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode = {
      url = "github:anomalyco/opencode/v1.15.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-unstable, home-manager, nix-darwin, nix-darwin-unstable, opencode, ... }@inputs: let
    # TODO: Remove `inherit system` when nixpkgs-unstable fixes stdenv.hostPlatform.system deprecation
    mkPkgsUnstable = system: import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      thinkpad-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = mkPkgsUnstable "x86_64-linux";
          hostname = "thinkpad-nixos";
        };
        modules = [
          ./hosts/thinkpad-nixos
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pkgs-unstable = mkPkgsUnstable "x86_64-linux";
              hostname = "thinkpad-nixos";
            };
            home-manager.users.fahimalizain = { config, pkgs, pkgs-unstable, hostname, ... }: {
              imports = [
                ./home.nix
                ./hosts/thinkpad-nixos/home.nix
              ];
            };
          }
        ];
      };
    };

    darwinConfigurations = {
      "mbp-m1max" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = mkPkgsUnstable "aarch64-darwin";
          hostname = "mbp-m1max";
          isDarwin = true;
        };
        modules = [
          ./hosts/mbp-m1max
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pkgs-unstable = mkPkgsUnstable "aarch64-darwin";
              hostname = "mbp-m1max";
            };
            home-manager.users.fahimalizain = { config, pkgs, pkgs-unstable, hostname, ... }: {
              imports = [
                ./home.nix
                ./hosts/mbp-m1max/home.nix
              ];
            };
          }
        ];
      };
    };
  };
}
