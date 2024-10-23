#!/bin/bash

export PATH="$PATH:$HOME/.cargo/bin"

rm -rf ~/.local/share/fonts
rustup self uninstall
sudo apt-get remove zsh nodejs npm

# Uninstall go
rm -rf ~/go
sudo rm -rf /usr/local/go
# Uninstall zsh
rm -rf ~/.zsh*
rsudo rm -rf /usr/local/share/zsh-autosuggestions
sudo rm -rf /usr/local/share/zsh-syntax-highlightingm -rf ~/.config/zsh

# Uninstall docker
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
