#!/bin/sh

# EXPORTS
export GITHUB_USERNAME=tauraamui
export CHEZMOI_BIN=~/bin/chezmoi

sudo -s -u $USER<<EOF
	sudo apt install -y git
	sudo apt install -y neovim
EOF

sh -c "$(curl -fsLS get.chezmoi.io)"
chmod u+x $CHEZMOI_BIN

$CHEZMOI init https://github.com/$GITHUB_USERNAME/dotfiles.git
$CHEZMOI_BIN apply

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 .local/share/nvim/site/pack/packer/start/packer.nvim

