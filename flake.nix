{
  description = "NixOS configuration for angmar";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fetch = {
      url = "github:areofyl/fetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    keyboard-app = {
      url = "github:occamist/keyboard-app";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tori-src = {
      url = "github:LeoRiether/tori/v0.2.6";
      # Tori ships no flake. Pinned to a tag, so `nix flake update`
      # re-resolves to the same commit and can never move it; bump by editing the
      # tag here.
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      ...
    }@inputs:
    {
      nixosConfigurations.angmar = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              nur.overlays.default
              (final: _prev: {
                tori = final.callPackage ./pkgs/tori { src = inputs.tori-src; };
              })
            ];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.occamist = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
