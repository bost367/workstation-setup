#!/usr/bin/env bash

export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:/usr/local/go/bin"
export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# color palette
clr_reset=$(tput sgr0)
clr_bold=$(tput bold)
clr_cyan="\e[0;36m"
clr_yellow="\e[0;33m"
clr_red="\e[0;31m"
clr_blue_underscore="\033[4;34m"

# variables
installed_versions=""

usage() {
  cat <<EOF
Description:
  Ubuntu workstation setup.

Usage:
  setup.sh [COMMAND]

Commands:
  shell     Setup shell: ZSH, CLI and TUI applications.
  desktop   Setup desktop (including shell): drivers, dev enviromnet,
            desktop applicaitons, GNOME settings and etc.
            Default command.
  help      Print help.
EOF
}

log_info() {
  echo -e "[$(date +"%F %T")] ${clr_cyan}info:${clr_reset} ${1}" >&2
}

log_warn() {
  echo -e "[$(date +"%F %T")] ${clr_yellow}warn:${clr_reset} ${1}" >&2
}

log_error() {
  echo -e "[$(date +"%F %T")] ${clr_red}error:${clr_reset} ${1}" >&2
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
  echo "Environment has been setup. Reboot your PC to finish."
  echo "Not all installations is automated. See the next steps to complete setup by your self."
  echo ""
  echo "${clr_bold}- Setup .gitconfig file.${clr_reset}"
  echo "  > git config --global user.name \"Name\""
  echo "  > git config --global user.email \"Email\""
  echo "  > git config --global pull.rebase true"
  echo ""
  echo "${clr_bold}- Generate ssh key and publish public key on GitHub.${clr_reset}"
  link "  - " "Geenrate ssh key" "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key"
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
  log_info "Update distro packages (including kernel). It takes some time."
  # update-distro must be run before drivers installations.
  # Otherwise ignoring distro updating can lead to broken drivers (like wi-fi).
  (sudo apt-get -q update && sudo apt-get -y dist-upgrade) || {
    log_error "Update distro is failure."
    exit 1
  }
  sudo ubuntu-drivers install
  # Installing Complete Multimedia Support.
  # ubuntu-restricted-extras during its installation, offers user to
  # input in interactive mode license agreement (it is ttf-mscorefonts-installer requirement).
  # To avoid this, writing answer in advance.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
  sudo apt-get -y install ubuntu-restricted-extras
}

# Need to be install primarily: required by other tools.
setup_required_cli() {
  log_info "Install required CLIs."
  sudo apt-get -y install \
    curl \
    git \
    wget \
    cmake \
    build-essential \
    procps \
    file

  # wget and curl has verbose output on `--version` command.
  report_version git
  report_version cmake
}

# Homebrew needs for support multiple OS: Linux & MacOS.
install_homebrew() {
  log_info "Install Homebrew."
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # https://docs.brew.sh/Tips-and-Tricks#loading-homebrew-from-the-same-dotfiles-on-different-operating-systems
  command -v brew || export PATH="$PATH:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin"
  command -v brew && eval "$(brew shellenv)"
  # https://docs.brew.sh/Analytics
  brew analytics off
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

  log_info "Make zsh default."
  sudo chsh -s "$(which zsh)" "$(whoami)"

  # https://github.com/zsh-users/zsh-autosuggestions
  log_info "Install zsh commands autocompletition."
  sudo git clone --depth=1 -q https://github.com/zsh-users/zsh-autosuggestions ${SHARE_FOLDER}/zsh-autosuggestions

  # Enable highlighting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  log_info "Install zsh commands highlighting."
  sudo git clone --depth=1 -q https://github.com/zsh-users/zsh-syntax-highlighting ${SHARE_FOLDER}/zsh-syntax-highlighting

  cat <<"EOF" >"$ZDOTDIR/.zshrc"
# Plugins
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Export brew env
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
EOF
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
  rustup -q update

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
  brew install -q nvim
  report_version nvim

  # Used by Nvim to share OS and Nvim buffers.
  # For more details run `:h clipboard` in nvim.
  brew install -q xclip
  # XML formatter.
  brew install -q libxml2
  report_version xmllint
  # Shell linter. Used by bash-language-server.
  brew install -q shellcheck
  report_version shellcheck
  # Shell formatter.
  brew install -q shfmt
  report_version shfmt
  # Lua formatter.
  brew install -q stylua
  report_version stylua
  # YAML file formatter.
  brew install -q yq
  report_version yq
}

setup_alacritty() {
  log_info "Install alacritty."
  snap install --classic alacritty
  report_version alacritty
  make_alacritty_default_terminal
  if [[ ! $(infocmp alacritty) ]]; then
    # https://github.com/alacritty/alacritty/blob/master/INSTALL.md#terminfo
    log_info "alacritty terminfo is not found. Install it."
    git clone --depth=1 -q https://github.com/alacritty/alacritty.git
    cd alacritty || return
    sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    cd .. && rm -rf alacritty
  fi
}

# https://gist.github.com/aanari/08ca93d84e57faad275c7f74a23975e6?permalink_comment_id=3822304#gistcomment-3822304
make_alacritty_default_terminal() {
  log_info "Make alacrutty default terminal."
  local start_alacritty_script
  start_alacritty_script="/usr/bin/start-alacritty"
  cat <<'EOF' | sudo tee "$start_alacritty_script"
#!/bin/sh

/usr/bin/snap run alacritty
EOF
  sudo chown root:root "$start_alacritty_script"
  sudo chmod --reference=/usr/bin/ls "$start_alacritty_script"
  sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$start_alacritty_script" 50
  sudo update-alternatives --set x-terminal-emulator "$start_alacritty_script"
}

setup_tui() {
  log_info "Install TUI CLIs."

  log_info "Install yazi - filemanager."
  brew install -q yazi
  report_version yazi

  log_info "Install zellij - terminal splitter."
  brew install -q zellij
  report_version zellij

  log_info "Install eza - better ls."
  brew install -q eza
  report_version eza

  log_info "Install starship - beautify prompt for terminal input."
  brew install -q starship
  report_version starship

  log_info "Install git-delta - side by side diff view fo lazygit."
  brew install -q git-delta
  report_version delta

  log_info "Install lazygit."
  brew install -q lazygit
  report_version lazygit

  log_info "Install lazydocker."
  brew install -q lazydocker
  report_version lazydocker

  log_info "Install fzf."
  brew install -q fzf
  report_version fzf

  log_info "Install btop - better htop."
  brew install -q btop
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
  git clone --depth=1 -q --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts.git
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
  # Brave flatpack package not yet working as well:
  # https://brave.com/linux/#flatpak. Can't be set as default browser.
  snap install brave
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
  dconf write /org/gnome/shell/extensions/dash-to-dock/hot-keys "false"

  log_info "Change file explorer settings."
  dconf write /org/gnome/nautilus/icon-view/default-zoom-level "'small'"
  dconf write /org/gtk/gtk4/settings/file-chooser/show-hidden true

  log_info "Change desktop settings."
  dconf write /org/gnome/shell/extensions/ding/icon-size "'tiny'"
  dconf write /org/gnome/shell/extensions/ding/show-home false
  dconf write /org/gnome/shell/extensions/ding/start-corner "'top-right'"
}

download_fonts() {
  log_info "Download San Francisco fonts."
  git clone --depth=1 -q https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git
  mv San-Francisco-Pro-Fonts "${HOME}/.local/share/fonts/SF_Pro"
}

setup_desktop_fonts() {
  download_fonts
  log_info "Setup San Francisco fonts as desktop font"
  dconf write /org/gnome/desktop/interface/font-name "'SF Pro Display 10'"
  dconf write /org/gnome/desktop/interface/document-font-name "'SF Pro Text 11'"
  dconf write /org/gnome/desktop/interface/monospace-font-name "'JetBrainsMono Nerd Font 13'"
  dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'SF Pro Display 11'"
}

setup_input_options() {
  log_info "Setup input options (mouse acceleration etc.)."
  # Mouse speed. May be different from PC to PC.
  dconf write /org/gnome/desktop/peripherals/mouse/speed -0.67
  # END & RUS keyboard input.
  dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'us'), ('xkb', 'ru')]"
}

setup_rounded_corner() {
  wget -q -O rounded-window-cornersfxgn.zip https://extensions.gnome.org/extension-data/rounded-window-cornersfxgn.v7.shell-extension.zip
  gnome-extensions install rounded-window-cornersfxgn.zip
  gnome-extensions enable rounded-window-corners@fxgn
  rm rounded-window-cornersfxgn.zip
}

personalyze_workstation() {
  log_info "Personalyze GUI desktop."
  check_if_gnome_environment || return
  setup_desktop_components
  setup_desktop_fonts
  setup_input_options
  setup_rounded_corner
}

clean_trash() {
  log_info "Clean up all mess."
  sudo apt-get autoclean
  sudo apt-get clean -y
  brew cleanup
}

console_interface() {
  sudo apt-get -q update
  setup_required_cli
  install_homebrew
  setup_zsh
  setup_tui
  setup_neovim
}

# Order matters: some functions install cli which required by the next installations.
desktop_interface() {
  update_distro
  console_interface
  setup_toolcahins
  setup_alacritty
  install_docker
  install_nerd_fonts
  install_flatpak
  install_desktop_applications
  personalyze_workstation
  print_post_install_message
}

setup_workstation() {
  check_ostype
  "$@"
  clean_trash
}

if [[ $# = 0 ]]; then
  log_info "Install desktop environment."
  setup_workstation desktop_interface
elif [ "$#" = 1 ]; then
  for opt in "$@"; do
    case "$opt" in
      help)
        usage
        exit 1
        ;;
      desktop)
        log_info "Install desktop environment."
        setup_workstation desktop_interface
        ;;
      shell)
        log_info "Install shell environment."
        setup_workstation console_interface
        ;;
      *)
        log_error "Unknown argument."
        usage
        exit 1
    esac
  done
else
  log_error "Too many arguments."
  usage
  exit 1
fi
