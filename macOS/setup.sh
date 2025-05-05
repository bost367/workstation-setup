#!/usr/bin/env bash

setup_color() {
  FMT_YELLOW=$(printf '\033[33m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

check_ostype() {
  local os_type
  os_type="$(uname -s)"
  if [[ ! $os_type = "Darwin" ]]; then
    echo "This script aim to be run on Darwin system only."
    echo "Current host is running on $os_type."
    exit 1
  fi
}

setup_homebrew() {
  if ! type "$brew -v" >/dev/null; then
    echo "${FMT_YELLOW}Brew is already installed.${FMT_RESET}"
  else
    echo "${FMT_YELLOW}Homebrew not found in system.${FMT_YELLOW}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

# Need to be install primarily: the required by other tools.
setup_required_cli() {
  printf "%s\n" "${FMT_YELLOW}Install required CLIs${FMT_RESET}"
  brew install \
    curl \
    git \
    wget
}

setup_zsh() {
  printf "%s\n" "${FMT_BOLD}${FMT_YELLOW}Setup zsh.${FMT_RESET}"
  export ZDOTDIR="$HOME/.config/zsh"
  brew install zsh

  # Change default zsh directory. All main files will be stored
  # in custom directory exept .zshenv: it points to .zshrc and
  # load defined variables from .zshenv.
  cat <<'EOF' >|~/.zshenv
export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
EOF

  # Save the terminal space on enter
  # https://askubuntu.com/questions/1492841/how-to-disable-daily-message-in-ubuntu-22-04-3-lts-message-of-the-day-motd
  # https://stackoverflow.com/questions/15769615/remove-last-login-message-for-new-tabs-in-terminal
  touch .hushlogin

  # Install commands autocompletition
  # https://github.com/zsh-users/zsh-autosuggestions
  brew install zsh-autosuggestions
  echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >>${ZDOTDIR:-$HOME}/.zshrc

  # Install commands highlighting.
  # Enable highliting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  brew install zsh-syntax-highlighting
  echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>${ZDOTDIR:-$HOME}/.zshrc

  # Install powerline (beautify prompt for input)
  # https://github.com/romkatv/powerlevel10k
  brew install powerlevel10k
  echo "source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >>${ZDOTDIR:-$HOME}/.zshrc
}

setup_alacritty() {
  brew install --cask alacritty
  # Install nerd fonts
  brew install --cask \
    font-jetbrains-mono \
    font-jetbrains-mono-nerd-font
}

setup_common_utilities() {
  printf "%s\n" "${FMT_YELLOW}Install common CLIs${FMT_RESET}"
  brew install \
    cloc \
    docker \
    docker-compose \
    grpcurl \
    helm \
    jq \
    kubernetes-cli \
    rustup-init \
    eza
}

setup_tui() {
  printf "%s\n" "${FMT_YELLOW}Install TUI CLIs${FMT_RESET}"
  brew install \
    derailed/k9s/k9s \
    nvim \
    lazydocker \
    lazygit \
    zellij
}

setup_gui() {
  printf "%s\n" "${FMT_YELLOW}Install GUI applications${FMT_RESET}"
  brew install --cask \
    openlens \
    postman \
    visualvm
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  check_ostype
  setup_color
  setup_homebrew
  setup_required_cli
  setup_zsh
  setup_alacritty
  setup_common_utilities
  setup_tui
  setup_gui
}

main
