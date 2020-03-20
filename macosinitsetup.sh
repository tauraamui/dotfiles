#!/bin/sh

brew bundle
curl -sL -o /usr/local/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.2.0/gvm-darwin-amd64
chmod +x /usr/local/bin/gvm
mkdir -p ~/.config/fish && touch ~/.config/fish/config.fish
echo "[ -f /usr/local/share/autojump/autojump.fish ]; source /usr/local/share/autojump/autojump.fish
gvm 1.13.7 | source
kitty + complete setup fish | source
set -g fish_user_paths "/usr/local/opt/icu4c/bin" $fish_user_paths
set -g fish_user_paths "/usr/local/opt/icu4c/sbin" $fish_user_paths
set -g fish_user_paths "/usr/local/opt/python@3.8/bin" $fish_user_paths
" >> ~/.config/fish/config.fish