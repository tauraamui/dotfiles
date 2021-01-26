#!/bin/sh
FISH_CONFIG=~/.config/fish/config.fish

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install fish
sudo apt-get install software-properties-common apt-transport-https curl
sudo curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
sudo curl -sSL https://packages.microsoft.com/key/microsoft.asc | apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt-get update
sudo apt-get install code
sudo apt-get install git
git config --global url.ssh://git@github.com/.insteadOf https://github.com/
mkdir ~/bin
curl -sL -o ~/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.3.0/gvm-linux-amd64
chmod +x ~/bin/gvm
touch $FISH_CONFIG
echo "~/bin/gvm 1.15.6 | source" > $FISH_CONFIG
