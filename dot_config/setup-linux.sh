#!/bin/sh

# pre-req install of required tools and packages
sudo -s -u $USER<<EOF
    sudo apt update
	sudo apt install -y git
    sudo apt install -y build-essential
    sudo apt install -y wget
    sudo apt install -y curl
    sudo apt install -y tmux
    sudo apt install -y xclip
    sudo apt install -y fish
    echo /usr/bin/fish | sudo tee -a /etc/shells
    sudo apt install -y kitty
EOF

# setup fish
echo "setting fish as default shell"
chsh -s /usr/bin/fish
#
# install oh-my-fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# EXPORTS
export GITHUB_USERNAME=tauraamui
# the fetch script for chezmoi puts it into a standard path I know ahead of time
export CHEZMOI=~/bin/chezmoi
export GO=~/.gvm/versions/go1.19.linux.amd64/bin/go
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

wget -O lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
rm lazygit.tar.gz

sudo -s -u $USER<<EOF
  sudo install lazygit /usr/local/bin
EOF

# configure git to use default username and email
# TODO:(tauraamui): need to add signing key somehow and also
#                   the aliasing of https://github to git@github
git config --global user.name "tauraamui"
git config --global user.email "adampstringer@protonmail.com"

# generate local SSH key for auth
ssh-keygen -t ed25519 -C "adampstringer@protonmail.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# setup chezmoi and then fetch and apply config files from Github
sh -c "$(curl -fsLS get.chezmoi.io)"
chmod u+x $CHEZMOI
$CHEZMOI init https://github.com/$GITHUB_USERNAME/dotfiles.git
$CHEZMOI apply

# setup go
wget -O ~/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.5.0/gvm-linux-amd64
chmod +x ~/bin/gvm
eval "$(~/bin/gvm 1.19)"
$GO version

# install jump utility
$GO install github.com/gsamokovarov/jump@latest

# install starship
curl -sS https://starship.rs/install.sh | sh

# setup nvim
#
# download and install packer plugin
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 .local/share/nvim/site/pack/packer/start/packer.nvim
 # acquire specific deb package for nvim (should use same version fetching lazygit is using)
wget -O ~/bin/nvim.deb https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
sudo -s -u $USER<<EOF
  sudo apt install ~/bin/nvim.deb
EOF
rm ~/bin/nvim.deb
# install nvim plugin 3rd party dependancies
#
# ripgrep to facilite live-grep for nvim
wget -O ~/bin/ripgrep.deb https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
sudo -s -u $USER<<EOF
  sudo apt install ~/bin/ripgrep.deb
EOF
rm ~/bin/ripgrep.deb

# install patched nerd font with ligatures
mkdir ~/fonts
wget -O ~/fonts/hasklig.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hasklig.zip
unzip ~/fonts/hasklig.zip -d ~/fonts/Hasklug
mkdir ~/.local/share/fonts
mv ~/fonts/Hasklug/*.otf ~/.local/share/fonts
fc-cache -f -v
rm -r ~/fonts/Hasklug


