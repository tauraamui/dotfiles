nix build --extra-experimental-features 'nix-command flakes' .#darwinConfigurations.Adams-MacBook-Pro.system
./result/sw/bin/darwin-rebuild switch --flake ~/src/dotfiles
