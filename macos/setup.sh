#!/usr/bin/env bash

set -u

# shellcheck source=utils.sh
source <(curl --proto "=https" --tlsv1.2 -sSfl https://raw.githubusercontent.com/bost367/workstation-setup/refs/heads/main/utils.sh)

suggest_desktop_applications() {
  cat <<EOF
Some Homebrew casks may come from unverified sources, posing security risks.
Install the following applications manually from their official websites:

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
  local tools=(
    wget
    grpcurl
    telnet
    k9s
    helm
    kubernetes-cli
    graphviz
    plantuml
  )
  brew install -q "${tools[@]}"
}

setup_shell_environment() {
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
  # Run Alacritty as not authorized application with apple.
  # https://github.com/alacritty/alacritty/issues/6500#issuecomment-2399558282
  xattr -dr com.apple.quarantine "/Applications/Alacritty.app"
}

# Installs Docker CLI and Compose plugin.
# Note: A container runtime (e.g., OrbStack, Colima, or Multipass)
# is required separately, as Docker Desktop requires a license
# for enterprise use.
install_docker() {
  brew install -q docker docker-compose
}

# Order matters: some functions install cli which required by the next installations.
main() {
  check_ostype "Darwin"
  setup_shell_environment
  setup_toolchains
  setup_alacritty
  install_docker
  brew cleanup
  print_to_do_list >&2
  suggest_desktop_applications >&2
}

main
