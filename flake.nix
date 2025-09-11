{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [ nixgl.overlay ];
    };
  in {

    packages.x86_64-linux.hello = pkgs.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    homeConfigurations."tauraamui" = home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs;

      extraSpecialArgs = {
        gpgKeyGeneratorScript = import ./pkgs/gpg-key-generator.nix {
          pkgs = pkgs;
        };
      };

      modules = [
        ./home.nix
      ];
    };
  };
}
