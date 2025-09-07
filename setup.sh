# install nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
~/.nix-profile/etc/profile.d/nix.sh

mkdir -p ~/.config/nix
cp ./nix.conf ~/.config/nix
cp ./flake.nix ~/

nix flake update
nix build

nix run home-manager/master -- init

cp ./home.nix ~/.config/home-manager/home.nix

nix run home-manager switch
