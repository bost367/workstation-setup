#!/bin/bash

export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:/usr/local/go/bin"
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# colour palette
clr_reset=$(tput sgr0)
clr_bold=$(tput bold)
clr_cyan="\e[0;36m"
clr_yellow="\e[0;33m"
clr_red="\e[0;31m"
clr_blue_underscore="\033[4;34m"

# variables
installed_versions=""

log_info() {
  echo -e "${clr_cyan}info:${clr_reset} ${1}" >&2
}

log_warn() {
  echo -e "${clr_yellow}warn:${clr_reset} ${1}" >&2
}

log_error() {
  echo -e "${clr_red}error:${clr_reset} ${1}" >&2
}

report_version() {
  local version
  if [[ $# = 1 ]]; then
    version=$(command "$1" "--version" 2>&1)
  else
    version=$(command "$1" "$2" 2>&1)
  fi
  local cmd_name="${clr_bold}${1}${clr_reset}"
  installed_versions+="$cmd_name\n$version\n..........\n"
}

print_version() {
  log_info "Installed tools:"
  echo -e "$installed_versions"
}

link() {
  echo -e "${1}\e]8;;${3}\a${clr_blue_underscore}${2}${clr_reset}\e]8;;\a"
}

print_to_do_list() {
  echo "Environment has been setup. Reboot your PC to complete it all."
  echo "Not all installations is automated. See the next steps to complete setup by your self."
  echo ""
  echo "${clr_bold}1. Install next desktop application.${clr_reset}"
  link "  - " "Chrome" "https://www.google.com/chrome"
  link "  - " "IntelliJ" "https://www.jetbrains.com/idea/download"
  echo ""
  echo "${clr_bold}2. Setup identity .gitconfig file.${clr_reset}"
  echo "  > git config --global user.name \"Name\""
  echo "  > git config --global user.email \"Email\""
  echo ""
  echo "${clr_bold}3. Generate ssh key and publish public key on GitHub.${clr_reset}"
  link "  - " "Geenrate ssh key" "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key"
  echo ""
  echo "${clr_bold}4. Sync Obsidian vault.${clr_reset}"
  echo "  -  TBD: describe steps"
}

print_post_install_message() {
  log_info "Run docker hello world."
  if [[ $(docker run hello-world) ]]; then
    log_info "docker hello-world runs successfully."
  elif [[ $(sudo docker run hello-world) ]]; then
    log_warn "Docker requeres root access."
    log_warn "See post-installation steps in docker setup guide to fix in."
  else
    log_warn "docker hello-world faild."
  fi
  print_version >&2
  print_to_do_list >&2
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_ostype() {
  if ! uname -a | grep -q "Ubuntu"; then
    log_error "This script aim to be run on Ubuntu distro only."
    exit 1
  fi
}

update_distro() {
  log_info "Update distro ackages (including kernel). It takes some time."
  # update-distro must be run before drivers installations.
  # Otherwise ignoring distro updating can lead to broken drivers (like wi-fi).
  (sudo apt-get -q update && sudo apt-get -y dist-upgrade) || {
    log_error "Update distro is failure."
    exit 1
  }
  sudo ubuntu-drivers install
  # Installing Complete Multimedia Support.
  # ubuntu-restricted-extras during its installation, offers user to
  # input in interactive mode licence agreement (it is ttf-mscorefonts-installer requirement).
  # To avoid this, writing answer in advance.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
  sudo apt-get -y install ubuntu-restricted-extras
}

# Need to be install primarily: the required by other tools.
setup_required_cli() {
  log_info "Install required CLIs."
  sudo apt-get -y install \
    curl \
    git \
    wget \
    cmake

  # wget and curl has verbose output on `--version` command.
  report_version git
  report_version cmake
}

setup_zsh() {
  log_info "Install zsh."
  local SHARE_FOLDER="/usr/local/share"
  mkdir -p "${ZDOTDIR}"
  sudo apt-get -y install zsh

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

  log_info "Make zsh defaul."
  chsh -s "$(which zsh)"

  # https://github.com/zsh-users/zsh-autosuggestions
  log_info "Install zsh commands autocompletition."
  sudo git clone -q https://github.com/zsh-users/zsh-autosuggestions ${SHARE_FOLDER}/zsh-autosuggestions
  echo "source ${SHARE_FOLDER}/zsh-autosuggestions/zsh-autosuggestions.zsh" >>"${ZDOTDIR:-$HOME}/.zshrc"

  # Enable highliting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  log_info "Install zsh commands highlighting."
  sudo git clone -q https://github.com/zsh-users/zsh-syntax-highlighting ${SHARE_FOLDER}/zsh-syntax-highlighting
  echo "source ${SHARE_FOLDER}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>"${ZDOTDIR:-$HOME}/.zshrc"

  report_version zsh
}

install_rust() {
  log_info "Install Rust."
  if check_cmd rustup; then
    log_info "Rust is already installed."
  else
    log_info "Rust is not found. Install it."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -yq
  fi
  rustup update

  report_version rustup
  report_version cargo
}

install_golang() {
  log_info "Install Goalng."
  local GOLANG_VERSION="1.23.2"
  local GOLANG_FILE

  log_info "Download binaries."
  GOLANG_FILE="go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
  wget -q "https://go.dev/dl/${GOLANG_FILE}"

  log_info "Remove any previous Go installation and install new one."
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "${GOLANG_FILE}"

  log_info "Remove binary."
  rm "${GOLANG_FILE}"

  report_version go version
}

install_java() {
  log_info "Install sdkman - JVM toolchain management."
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"

  log_info "Install Java (21.0.5-tem)."
  sdk install java 21.0.5-tem

  report_version sdk version
  report_version java
}

install_nodejs() {
  log_info "Install Nodejs and npm."
  sudo apt-get -y install nodejs
  sudo apt-get -y install npm

  report_version npm version
}

# Such toolchains requires bash/zsh file modification.
# Toolchains also is used to install bin files
setup_toolcahins() {
  log_info "Toolchains instalation."
  install_rust
  install_golang
  install_java
  install_nodejs
}

setup_neovim() {
  log_info "Install Neovim setup."
  # apt insltlls old verion of vim. snap conteins fresh release.
  snap install --classic nvim
  report_version nvim

  # Used by Nvim to share OS and Nvim buffers.
  # For more details run `:h clipboard` in nvim.
  sudo apt-get -y install xclip
  # XML formatter.
  sudo apt-get -y install libxml2-utils
  report_version xmllint
  # Shell linter. Used by bash-language-server.
  sudo apt-get -y install shellcheck
  report_version shellcheck
  # Shell formatter.
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
  report_version shfmt
  # Lua formatter.
  cargo -q install --locked stylua
  report_version stylua
  # YAML file formatter.
  go install github.com/mikefarah/yq/v4@latest
  report_version yq
}

setup_alacritty() {
  log_info "Install alacritty."
  snap install --classic alacritty
  report_version alacritty
  if [[ ! $(infocmp alacritty) ]]; then
    # https://github.com/alacritty/alacritty/blob/master/INSTALL.md#terminfo
    log_info "alacritty terminfo is not found. Install it."
    git clone -q https://github.com/alacritty/alacritty.git
    cd alacritty || return
    sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    rm -rf alacritty
  fi
}

setup_tui() {
  log_info "Install TUI CLIs."

  log_info "Install yazi - filemanager."
  cargo -q install --locked yazi-fm yazi-cli
  report_version yazi

  log_info "Install zellij - terminal splitter."
  cargo -q install --locked zellij
  report_version zellij

  log_info "Install eza - better ls."
  cargo -q install --locked eza
  report_version eza

  log_info "Install starship - beautify prompt for terminal input."
  cargo -q install --locked starship
  report_version starship

  log_info "Install git-delta - side by side diff view fo lazygit."
  cargo -q install --locked git-delta
  report_version delta

  log_info "Install lazygit."
  go install github.com/jesseduffield/lazygit@latest
  report_version lazygit

  log_info "Install lazydocker."
  go install github.com/jesseduffield/lazydocker@latest
  report_version lazydocker

  log_info "Install btop - better htop."
  snap install btop
  report_version btop
}

# https://docs.docker.com/engine/install/ubuntu/
install_docker() {
  log_info "Install Docker."
  # Uninstall any conflicting packages:
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove $pkg
  done

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get -y install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update

  # Install the Docker packages:
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  report_version docker

  log_info "Add user to docker group."
  # https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
  sudo groupadd docker
  sudo usermod -aG docker "${USER}"
  newgrp docker <<'EOL'
EOL
}

install_nerd_fonts() {
  log_info "Install Nerd Fonts."
  git clone -q --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts.git
  cd nerd-fonts || return
  git sparse-checkout add patched-fonts/JetBrainsMono
  bash install.sh JetBrainsMono
  cd .. && rm -rf nerd-fonts
}

install_flatpak() {
  log_info "Install Flatpak."
  sudo apt-get -y install flatpak
  sudo apt-get -y install gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_desktop_applications() {
  log_info "Install Desktop application."
  flatpak install -y flathub org.telegram.desktop
  flatpak install -y flathub com.getpostman.Postman
  flatpak install -y flathub md.obsidian.Obsidian
}

check_if_gnome_environment() {
  if ! check_cmd gnome-shell; then
    log_warn "Gnome shell not found."
    log_warn "Personalization step will be skipped."
    return 1
  fi
}

setup_desktop_components() {
  log_info "Switch dark theme."
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
  dconf write /org/gnome/desktop/interface/gtk-theme "'Yaru-blue-dark'"
  dconf write /org/gnome/desktop/interface/icon-theme "'Yaru-blue'"

  log_info "Change dock panel settings."
  dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
  dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 48
  dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false
  dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts-network true
  dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false

  log_info "Change file explorer settings."
  dconf write /org/gnome/nautilus/icon-view/default-zoom-level "'small'"
  dconf write /org/gtk/gtk4/settings/file-chooser/show-hidden true

  log_info "Change desktop settings."
  dconf write /org/gnome/shell/extensions/ding/icon-size "'tiny'"
  dconf write /org/gnome/shell/extensions/ding/show-home false
  dconf write /org/gnome/shell/extensions/ding/start-corner "'top-right'"
}

download_fonts() {
  log_info "Download Inter fonts."
  wget -q -O Inter.zip https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip
  mkdir -p "${HOME}/.local/share/fonts/Inter"
  unzip -qq Inter.zip -d "${HOME}/.local/share/fonts/Inter" Inter.ttc InterVariable.ttf InterVariable-Italic.ttf
  rm Inter.zip
}

setup_desktop_fonts() {
  download_fonts
  log_info "Setup Inter fonts as desktop font."
  dconf write /org/gnome/desktop/interface/font-name "'Inter Display 11'"
  dconf write /org/gnome/desktop/interface/document-font-name "'Inter 11'"
  dconf write /org/gnome/desktop/interface/monospace-font-name "'JetBrainsMono Nerd Font 13'"
  dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'Inter Bold 11'"
  dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'Inter Display 11'"
}

setup_input_options() {
  log_info "Setup input options (mouse acceleration etc.)."
  # Mouse speed. May be different from PC to PC.
  dconf write /org/gnome/desktop/peripherals/mouse/speed -0.67
  # END & RUS keyboard input.
  dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'us'), ('xkb', 'ru')]"
}

personalyze_workstation() {
  log_info "Personalyze ui desktop."
  check_if_gnome_environment || return
  setup_desktop_components
  setup_desktop_fonts
  setup_input_options
}

clean_trash() {
  log_info "Clean up all mess."
  sudo apt-get autoclean
  sudo apt-get clean -y
}

# Order matters: some functions install cli which requered by the next installations.
main() {
  check_ostype
  update_distro
  setup_required_cli
  setup_zsh
  setup_toolcahins
  setup_alacritty
  setup_tui
  setup_neovim
  install_docker
  install_nerd_fonts
  install_flatpak
  install_desktop_applications
  personalyze_workstation
  clean_trash
  print_post_install_message
}

main
