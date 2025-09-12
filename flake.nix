{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-plugins = {
      url = "github:tauraamui/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixgl, neovim-plugins, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      config.allowUnfree = true;
      overlays = [ nixgl.overlay neovim-plugins.overlays.default ];
    };
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {

    packages.x86_64-linux.hello = pkgs.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    homeConfigurations."tauraamui" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        nixgl = nixgl;
        pkgs-unstable = pkgs-unstable;
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
