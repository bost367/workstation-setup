#!/usr/bin/env bash

set -u

# shellcheck source=utils.sh
source <(curl --proto "=https" --tlsv1.2 -sSfl https://raw.githubusercontent.com/bost367/workstation-setup/refs/heads/main/utils.sh)

# Specific tools for macos
install_macos_tui() {
  brew install -q \
    wget \
    grpcurl \
    telnet \
    k9s \
    helm \
    kubernetes-cli
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

install_docker() {
  brew install -q docker docker-compose
}

install_desktop_applications() {
  log_info "Install Desktop application."
  brew install -q --cask \
    brave-browser \
    openlens \
    postman \
    visualvm \
    redis-insight
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  check_ostype "Darwin"
  console_interface
  setup_toolcahins
  setup_alacritty
  install_docker
  install_desktop_applications
  print_to_do_list >&2
}

main
