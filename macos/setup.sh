#!/usr/bin/env bash

set -u

# shellcheck source=utils.sh
source <(curl --proto "=https" --tlsv1.2 -sSfl https://raw.githubusercontent.com/bost367/workstation-setup/refs/heads/main/utils.sh)

suggest_desktop_application() {
  cat <<EOF
Not all casks in Homebrew are added by verified developers.
It may lead to vulnerability issues to install them with Homebrew.
Install the following applications by yourself from official origins:

• Intellij IDEA
• OpenLens
• Offset Explorer
• Redis Insight
• Postman
• VisualVM
• Brave Browser
• Telegram
• Obsidian

EOF
}

# Tools for my daily work.
install_macos_tui() {
  brew install -q \
    wget \
    grpcurl \
    telnet \
    k9s \
    helm \
    kubernetes-cli \
    graphviz \
    plantuml
}

console_interface() {
  install_homebrew
  install_required_cli
  setup_zsh
  install_tui
  install_macos_tui
  setup_neovim
}

setup_alacritty() {
  brew install -q --cask \
    alacritty \
    font-jetbrains-mono-nerd-font
}

# This function installs only docker-cli.
# Macos also needs container environment.
# The first one that comes to mind is the Docker Desktop.
# But it requires a licens for enterprise usage.
# Thre are others docker environments:
# - OrbStack
# - colima
# - Multipass
install_docker() {
  brew install -q docker docker-compose
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  check_ostype "Darwin"
  console_interface
  setup_toolchains
  setup_alacritty
  install_docker
  brew cleanup
  print_to_do_list >&2
  suggest_desktop_application >&2
}

main
