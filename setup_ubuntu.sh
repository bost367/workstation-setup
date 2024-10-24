#!/bin/bash

export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:/usr/local/go/bin"
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

setup_color() {
  FMT_YELLOW=$(printf '\033[33m')
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log() {
  setup_color
  printf "%s\n" "${FMT_BOLD}${FMT_YELLOW}${1}${FMT_RESET}"
}

update_pakages() {
  log "Update and upgrade packages"
  sudo apt-get -q update && sudo apt-get -yq upgrade
  # Installing Complete Multimedia Support
  sudo apt-get -yq install ubuntu-restricted-extras
}

# Need to be install primarily: the required by other tools.
setup_required_cli() {
  log "Install required CLIs"
  sudo apt-get -yqq install \
    curl \
    git \
    wget
}

setup_zsh() {
  log "Install ZSH"
  local SHARE_FOLDER="/usr/local/share"
  mkdir -p "${ZDOTDIR}"
  sudo apt-get -yqq install zsh

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
  touch "$HOME/.hushlogin"

  printf "%s\n" "Make zsh default"
  chsh -s "$(which zsh)"

  # https://github.com/zsh-users/zsh-autosuggestions
  printf "%s\n" "Install commands autocompletition"
  sudo git clone https://github.com/zsh-users/zsh-autosuggestions ${SHARE_FOLDER}/zsh-autosuggestions
  echo "source ${SHARE_FOLDER}/zsh-autosuggestions/zsh-autosuggestions.zsh" >>"${ZDOTDIR:-$HOME}/.zshrc"

  # Enable highliting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  printf "%s\n" "Install commands highlighting."
  sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting ${SHARE_FOLDER}/zsh-syntax-highlighting
  echo "source ${SHARE_FOLDER}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"${ZDOTDIR:-$HOME}/.zshrc"
}

install_rust() {
  log "Install Rust."
  if check_cmd rustup; then
    printf "%s\n" "Rust is already installed"
  else
    printf "%s\n" "Rust is not found. Install it"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  fi
  rustup update
  rustup -V
}

install_golang() {
  log "Install Goalng."
  local GOLANG_VERSION="1.23.2"
  local GOLANG_FILE

  printf "%s\n" "Download binaries"
  GOLANG_FILE="go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
  wget -q "https://go.dev/dl/${GOLANG_FILE}"

  printf "%s\n" "Remove any previous Go installation and install new one"
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "${GOLANG_FILE}"

  printf "%s\n" "Remove binary"
  rm "${GOLANG_FILE}"
  go version
}

install_java() {
  log "Install sdkman - jvm toolchain management."
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"

  log "Install Java."
  sdk install java 21.0.5-tem

  sdk version
  java --version
}

install_nodejs() {
  log "Install Nodejs and npm."
  sudo apt-get -yqq install nodejs
  sudo apt-get -yqq install npm
  npm version
}

# Such toolchains requires bash/zsh file modification.
# Toolchains also is used to install bin files
setup_toolcahins() {
  log "Toolchains instalation"
  install_rust
  install_golang
  install_java
  install_nodejs
}

setup_neovim() {
  log "Install Neovim setup"
  # apt insltlls old verion of vim. snap conteins fresh release.
  snap install --classic nvim

  # Used by Nvim to share OS and Nvim buffers.
  # For more details run `:h clipboard` in nvim.
  sudo apt-get -yq install xclip

  # Shell linter. Used by bash-language-server.
  sudo apt-get -yq install shellcheck
  # Shell formatter.
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
  # Lua formatter.
  cargo -q install --locked stylua
  # YAML file formatter.
  go install github.com/mikefarah/yq/v4@latest
}

setup_tui() {
  log "Install TUI CLIs"

  printf "%s\n" "Install yazi - filemanager"
  cargo -q install --locked yazi-fm yazi-cli

  printf "%s\n" "Install zellij - terminal splitter"
  cargo -q install --locked zellij

  printf "%s\n" "Install eza - better ls"
  cargo -q install --locked eza

  printf "%s\n" "Install starship - beautify prompt for terminal input"
  cargo -q install --locked starship

  printf "%s\n" "Install git-delta - side by side diff view fo lazygit"
  cargo -q install --locked git-delta

  printf "%s\n" "Install lazygit"
  go install github.com/jesseduffield/lazygit@latest

  printf "%s\n" "Install lazydocker"
  go install github.com/jesseduffield/lazydocker@latest

  printf "%s\n" "Install alacritty"
  snap install --classic alacritty

  printf "%s\n" "Install btop - better htop"
  snap install btop
}

# https://docs.docker.com/engine/install/ubuntu/
install_docker() {
  log "Install Docker"
  # Uninstall any conflicting packages:
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove $pkg
  done

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get -yq install ca-certificates curl
  sudo install -myq 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update

  # Install the Docker packages:
  sudo apt-get -yq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  docker -v
}

install_nerd_fonts() {
  log "Install Nerd Fonts"
  git clone --filter=blob:none --sparse git@github.com:ryanoasis/nerd-fonts
  cd nerd-fonts
  git sparse-checkout add patched-fonts/JetBrainsMono
  bash install.sh JetBrainsMono
  cd .. && rm -rf nerd-fonts
}

install_flatpak() {
  log "Install Flatpak"
  sudo apt-get -yq install flatpak
  sudo apt-get -yq install gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_desktop_applications() {
  log "Install Desktop application"
  flatpak install -y flathub org.telegram.desktop
  flatpak install -y flathub com.getpostman.Postman
  flatpak install -y flathub md.obsidian.Obsidian
}

clean_trash() {
  sudo apt-get autoclean
  sudo apt-get clean -yq
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  update_pakages
  setup_required_cli
  setup_zsh
  setup_toolcahins
  setup_neovim
  setup_tui
  install_docker
  install_nerd_fonts
  install_flatpak
  install_desktop_applications
  clean_trash
}

main
# TODO:
# - setup git config --global user.name & user.email
# - setup ssh key and publish public key on github
# - Battary optimization
