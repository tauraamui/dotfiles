{
  description = "dotconfigs flake for macOS";
  inputs = {
    # source of all software which can be installed
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # for symlinking configs into typically expected locations
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # controls macos system settings
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # custom neovim plugins overlay
    neovim-plugins = {
      url = "github:tauraamui/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: {
    darwinConfigurations.Adams-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
        overlays = [ inputs.neovim-plugins.overlays.default ];
      };
      modules = [
        (
          { pkgs, ... }:
          {
            # darwin preferences + configs
            programs.fish.enable = true;
            environment.shells = [
              pkgs.bash
              pkgs.zsh
              pkgs.fish
            ];
            nix.extraOptions = ''
              experimental-features = nix-command flakes
            '';
            environment.systemPackages = [ pkgs.coreutils ];
            system.keyboard.enableKeyMapping = true;
            fonts.packages = [
              pkgs.nerd-fonts.meslo-lg
              pkgs.nerd-fonts.gohufont
            ];
            system.defaults.finder.AppleShowAllExtensions = true;
            system.defaults.finder._FXShowPosixPathInTitle = true;
            system.defaults.dock.autohide = true;
            system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
            system.defaults.NSGlobalDomain.KeyRepeat = 1;
            system.primaryUser = "tauraamui";
            system.stateVersion = 6;
            homebrew = {
              enable = true;
              caskArgs.no_quarantine = true;
              global.brewfile = true;
              masApps = { }; # manage apps which live in apple app store
              casks = [
                "raycast"
                "google-chrome"
                "brave-browser"
                "mullvad-vpn"
              ];
            };
          }
        )
        inputs.home-manager.darwinModules.home-manager
        {
          users.users.tauraamui.home = "/Users/tauraamui";
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.tauraamui.imports = [ ./home.nix ];
          };
        }
      ];
    };
  };
}
