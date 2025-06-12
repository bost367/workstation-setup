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
  desktop   Setup desktop (including shell): drivers, dev enviromnet,
            desktop applicaitons, GNOME settings and etc.
            Default command.
  help      Print help.
EOF
}

update_distro() {
  log_info "Update distro packages (including kernel)."
  # update-distro must be run before drivers installations.
  # Otherwise ignoring distro updating can lead to broken drivers (like wi-fi).
  (sudo apt-get -q update && sudo apt-get -y dist-upgrade) || {
    log_error "Update distro is failure."
    exit 1
  }
  # Required by homebrew during installation.
  sudo apt-get -y install build-essential curl
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

# https://gist.github.com/aanari/08ca93d84e57faad275c7f74a23975e6?permalink_comment_id=3822304#gistcomment-3822304
make_alacritty_default_terminal() {
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
  cd nerd-fonts || return
  git sparse-checkout add patched-fonts/JetBrainsMono
  bash install.sh JetBrainsMono
  cd .. && rm -rf nerd-fonts
}

setup_alacritty() {
  log_info "Install alacritty."
  snap install --classic alacritty
  make_alacritty_default_terminal
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

verify_docker() {
  log_info "Run docker hello world."
  if [[ $(docker run hello-world) ]]; then
    log_info "docker hello-world runs successfully."
  elif [[ $(sudo docker run hello-world) ]]; then
    log_warn "Docker requeres root access."
    log_warn "See post-installation steps in docker setup guide to fix in."
  else
    log_warn "docker hello-world faild."
  fi
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
  newgrp docker <<'EOL'
EOL
  verify_docker
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
  flatpak install -y flathub md.obsidian.Obsidian
  # Brave flatpack package not yet working as well:
  # https://brave.com/linux/#flatpak. Can't be set as default browser.
  sudo snap install brave
  sudo snap install postman
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
  install_homebrew
  install_required_cli
  setup_zsh
  install_tui
  setup_neovim
}

# Order matters: some functions install cli which required by the next installations.
desktop_interface() {
  install_drivers
  console_interface
  setup_toolcahins
  setup_alacritty
  install_docker
  install_flatpak
  install_desktop_applications
  personalyze_workstation
}

setup_workstation() {
  check_ostype "Ubuntu"
  update_distro
  "$@"
  clean_trash
  print_to_do_list >&2
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
      ;;
    esac
  done
else
  log_error "Too many arguments."
  usage
  exit 1
fi
