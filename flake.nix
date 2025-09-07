{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.config.allowUnfree = true;
    home-manager = {
	url = "github:nix-community/home-manager/release-25.05";
	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    homeConfigurations."tauraamui" = home-manager.lib.homeManagerConfiguration {
	pkgs = nixpkgs.legacyPackages.x86_64-linux;

	extraSpecialArgs = {
            gpgKeyGeneratorScript = import ./pkgs/gpg-key-generator.nix {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
            };
	};

	modules = [
          ./home.nix
        ];
    };
  };
}
