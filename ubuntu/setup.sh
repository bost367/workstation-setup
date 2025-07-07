#!/usr/bin/env bash

set -u

# shellcheck source=utils.sh
source <(wget --https-only --secure-protocol=TLSv1_2 -qO - https://raw.githubusercontent.com/bost367/workstation-setup/refs/heads/main/utils.sh)

usage() {
  cat <<EOF
Description:
  Ubuntu workstation setup.

Usage:
  setup.sh [COMMAND]

Commands:
  shell     Setup shell: ZSH, CLI and TUI applications.
  desktop   Setup desktop (including shell): drivers, dev environment,
            desktop applications, GNOME settings and etc.
            Default command.
  help      Displays this help message.
EOF
}

update_distro() {
  log_info "Update distro packages (including kernel)."
  # update-distro must be run before drivers installations.
  # Otherwise ignoring distro updating can lead to broken drivers (like wi-fi).
  (sudo apt-get -q update && sudo apt-get -y dist-upgrade) || {
    log_error "Failed to update distribution."
    exit 1
  }
  sudo apt-get -y install build-essential curl git # Required by homebrew.
  sudo apt-get -y install zip unzip                # Required by sdkman.
}

install_drivers() {
  log_info "Install drivers."
  sudo ubuntu-drivers install
  # Installing Complete Multimedia Support.
  # ubuntu-restricted-extras during its installation, offers user to
  # input in interactive mode license agreement (it is ttf-mscorefonts-installer requirement).
  # To avoid this, writing answer in advance.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
  sudo apt-get -y install ubuntu-restricted-extras
}

# Zsh from Homebrew not fully compatible for Ubuntu distro.
# https://unix.stackexchange.com/a/685000
install_zsh() {
  log_info "Installing zsh."
  sudo apt-get -y install zsh
  log_info "Set Zsh as default shell."
  sudo chsh -s "$(which zsh)" "$(whoami)"
  setup_zsh
}

# https://gist.github.com/aanari/08ca93d84e57faad275c7f74a23975e6?permalink_comment_id=3822304#gistcomment-3822304
set_alacritty_as_default_terminal() {
  log_info "Make alacrutty default terminal."
  local start_alacritty_script="/usr/bin/start-alacritty"
  cat <<'EOF' | sudo tee "$start_alacritty_script"
#!/bin/sh

/usr/bin/snap run alacritty
EOF
  sudo chown root:root "$start_alacritty_script"
  sudo chmod --reference=/usr/bin/ls "$start_alacritty_script"
  sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$start_alacritty_script" 50
  sudo update-alternatives --set x-terminal-emulator "$start_alacritty_script"
}

install_nerd_fonts() {
  log_info "Install Nerd Fonts."
  git clone --depth=1 -q --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts.git
  git -C nerd-fonts sparse-checkout add patched-fonts/JetBrainsMono
  bash nerd-fonts/install.sh JetBrainsMono
  rm -rf nerd-fonts
}

setup_alacritty() {
  log_info "Install alacritty."
  snap install --classic alacritty
  set_alacritty_as_default_terminal
  if [[ ! $(infocmp alacritty) ]]; then
    # https://github.com/alacritty/alacritty/blob/master/INSTALL.md#terminfo
    log_info "alacritty terminfo is not found. Install it."
    git clone --depth=1 -q https://github.com/alacritty/alacritty.git
    cd alacritty || return
    sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    cd .. && rm -rf alacritty
  fi
  install_nerd_fonts
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
  # shellcheck source=/dev/null
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update

  # Install the Docker packages:
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log_info "Add user to docker group."
  # https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
  sudo groupadd docker
  sudo usermod -aG docker "${USER}"
}

install_flatpak() {
  log_info "Install Flatpak."
  sudo apt-get -y install flatpak
  sudo apt-get -y install gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_desktop_applications() {
  log_info "Install Desktop applications."
  flatpak install -y flathub org.telegram.desktop
  # Brave flatpack package not yet working as well:
  # https://brave.com/linux/#flatpak. Can't be set as default browser.
  sudo snap install brave
  sudo snap install postman
  sudo snap install telegram-desktop
}

check_if_gnome_environment() {
  if ! check_cmd gnome-shell; then
    log_warn "Gnome shell not found."
    log_warn "Personalization step will be skipped."
    return 1
  fi
}

# Configures GNOME desktop settings, including theme, dock, file explorer, and desktop icons.
# Assumes GNOME shell is installed and dconf is available.
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
  git clone --depth=1 -q https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git "${HOME}/.local/share/fonts/SF_Pro"
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
  dconf write /org/gnome/desktop/peripherals/mouse/speed -0.67
  # ENG & RUS keyboard input.
  dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'us'), ('xkb', 'ru')]"
}

setup_rounded_corner() {
  wget -q -O rounded-window-cornersfxgn.zip https://extensions.gnome.org/extension-data/rounded-window-cornersfxgn.v7.shell-extension.zip
  gnome-extensions install rounded-window-cornersfxgn.zip
  gnome-extensions enable rounded-window-corners@fxgn
  rm rounded-window-cornersfxgn.zip
}

personalize_workstation() {
  log_info "Personalyze GUI desktop."
  check_if_gnome_environment || return
  setup_desktop_components
  setup_desktop_fonts
  setup_input_options
  setup_rounded_corner
}

cleanup_trash() {
  log_info "Cleaning up temporary files and package caches."
  sudo apt-get autoclean
  sudo apt-get clean -y
  brew cleanup
}

setup_shell_environment() {
  install_homebrew
  install_required_cli
  install_zsh
  install_tui
  setup_neovim
}

# Order matters: some functions install cli which required by the next installations.
setup_desktop_environment() {
  install_drivers
  setup_shell_environment
  setup_toolchains
  setup_alacritty
  install_docker
  install_flatpak
  install_desktop_applications
  personalize_workstation
}

setup_workstation() {
  check_ostype "Ubuntu"
  update_distro
  "$@"
  cleanup_trash
  print_to_do_list >&2
}

if [[ $# = 0 ]]; then
  log_info "Install desktop environment."
  setup_workstation setup_desktop_environment
elif [ "$#" = 1 ]; then
  case "$1" in
  help)
    usage
    exit 0
    ;;
  desktop)
    log_info "Installing desktop environment."
    setup_workstation setup_desktop_environment
    ;;
  shell)
    log_info "Installing shell environment."
    setup_workstation setup_shell_environment
    ;;
  *)
    log_error "Unknown argument: $1"
    usage
    exit 1
    ;;
  esac
else
  log_error "Too many arguments."
  usage
  exit 1
fi
