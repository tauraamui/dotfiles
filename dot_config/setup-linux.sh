#!/bin/sh

# EXPORTS
export GITHUB_USERNAME=tauraamui
export CHEZMOI=~/bin/chezmoi

sudo -s -u $USER<<EOF
	sudo apt install -y git
    sudo apt install -y build-essential
EOF

sh -c "$(curl -fsLS get.chezmoi.io)"
chmod u+x $CHEZMOI

$CHEZMOI init https://github.com/$GITHUB_USERNAME/dotfiles.git
$CHEZMOI apply

wget -O ~/bin/nvim.deb https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb

git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 .local/share/nvim/site/pack/packer/start/packer.nvim

sudo -s -u $USER<<EOF
  sudo apt install ~/bin/nvim.deb
EOF

# install patched nerd font with ligatures
mkdir ~/fonts
wget -O ~/fonts/hasklig.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hasklig.zip
unzip ~/fonts/hasklig.zip -d ~/fonts/Hasklug
mkdir ~/.local/share/fonts
mv ~/fonts/Hasklug/*.otf ~/.local/share/fonts
fc-cache -f -v
rm -r ~/fonts/Hasklug

# install ripgrep to facilite live-grep for nvim
wget -O ~/bin/ripgrep.deb https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
sudo -s -u $USER<<EOF
  sudo apt install ~/bin/ripgrep.deb
EOF

