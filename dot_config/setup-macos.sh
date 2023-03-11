#!/bin/zsh

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

export BREWDIR=/opt/homebrew/bin
export BREWBIN=$BREWDIR/brew
export FISHBIN=$BREWDIR/fish
export CHEZMOI=$BREWDIR/chezmoi
export WGET=$BREWDIR/wget
export GIT=$BREWDIR/git
export GITHUB_USERNAME=tauraamui

$BREWBIN install git
$BREWBIN install fish
$BREWBIN install tmux
$BREWBIN install curl
$BREWBIN install wget
$BREWBIN install ripgrep
$BREWBIN install htop
$BREWBIN install kitty
$BREWBIN install neovim
$BREWBIN install jesseduffield/lazygit/lazygit
$BREWBIN tap wez/wezterm
$BREWBIN install --cask wez/wezterm/wezterm
$BREWBIN install --cask neovide
$BREWBIN install --cask brave-browser
$BREWBIN install chezmoi

# setting fish shell as default
echo $FISHBIN | sudo tee -a /etc/shells
chsh -s $FISHBIN
#
# install oh-my-fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | $FISHBIN

mkdir ~/bin
sudo mkdir /usr/local/bin

# generate local SSH key for auth
ssh-keygen -t ed25519 -C "adampstringer@protonmail.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# setup chezmoi, fetch and apply config files from Github
$CHEZMOI init https://github.com/$GITHUB_USERNAME/dotfiles.git

# setup go
$WGET -O ~/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.5.0/gvm-darwin-arm64
chmod +x ~/bin/gvm
eval "$(~/bin/gvm 1.19)"
export GO=$(which go)
$GO version

# install jump utility
$GO install github.com/gsamokovarov/jump@latest

# install gopls language server
$GO install golang.org/x/tools/gopls@latest

# install starship
curl -sS https://starship.rs/install.sh | sh

# download and install packer plugin
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 .local/share/nvim/site/pack/packer/start/packer.nvim

# install patched nerd font with ligatures
mkdir ~/fonts
$WGET -O ~/fonts/hasklig.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hasklig.zip
unzip ~/fonts/hasklig.zip -d ~/fonts/Hasklug
mv ~/fonts/Hasklug/*.otf ~/Library/Fonts
rm -r ~/fonts/Hasklug

$CHEZMOI apply

