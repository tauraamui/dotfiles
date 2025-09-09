#!/bin/bash

# install nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

mkdir -p ~/.config/nix
cp ./nix.conf ~/.config/nix
cp ./flake.nix ~/

# run the rest in a subshell with nix sourced
bash -c '
source ~/.nix-profile/etc/profile.d/nix.sh

nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update
nix-env -iA nixgl.auto.nixGLDefault

nix flake update
nix build

nix run home-manager/master -- init

rm ~/.config/home-manager/home.nix
ln -sf "$(pwd)/home.nix" ~/.config/home-manager/

nix run home-manager -- switch --impure

# Reload environment to see newly installed programs
source ~/.nix-profile/etc/profile.d/hm-session-vars.sh

# Set Fish as default shell
FISH_PATH="$HOME/.nix-profile/bin/fish"
if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
chsh -s "$FISH_PATH"

gh auth login
'
