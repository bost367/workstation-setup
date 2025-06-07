#!/usr/bin/env bash

source ../utils.sh

# Need to be install primarily: the required by other tools.
setup_alacritty() {
  brew install --cask alacritty
  brew install --cask \
    font-jetbrains-mono \
    font-jetbrains-mono-nerd-font
}

install_desktop_applications() {
  log_info "Install Desktop application."
  brew install --cask \
    brave-browser \
    openlens \
    postman \
    visualvm
}

console_interface() {
  install_homebrew
  setup_required_cli
  setup_zsh
  setup_tui
  # brew install -q docker
  # brew install -q docker-compose
  brew install -q derailed/k9s/k9s
  brew install -q grpcurl
  brew install -q helm
  brew install -q kubernetes-cli
  setup_neovim
}

setup_toolcahins() {
  log_info "Toolchains instalation."
  install_rust
  #install_golang
  install_java
  install_nodejs
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  check_ostype "Ubuntu"
  console_interface
  setup_toolcahins
  setup_alacritty
  install_desktop_applications
  print_to_do_list >&2
}

main
