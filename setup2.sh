#!/bin/bash

# install nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

mkdir -p ~/.config/nix
cp ./nix.conf ~/.config/nix

# run the rest in a subshell with nix sourced
source ~/.nix-profile/etc/profile.d/nix.sh

nix-shell --run "home-manager switch --impure --flake .; exit"

# Reload environment to see newly installed programs
source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

# Set Fish as default shell
FISH_PATH="$HOME/.nix-profile/bin/fish"
if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
chsh -s "$FISH_PATH"

gh auth login
