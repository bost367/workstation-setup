#!/usr/bin/env bash

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log_error() {
  echo -e "${1}" >&2
}

check_ostype() {
  if ! uname -a | grep -q "Ubuntu"; then
    log_error "This script aim to be run on Ubuntu distro only."
    exit 1
  fi
}

check_if_gnome_environment() {
  if ! check_cmd gnome-shell; then
    log_error "Gnome shell not found."
    exit 1
  fi
}

install_xremap() {
  if ! check_cmd cargo; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -yq
  fi
  rustup update
  cargo install xremap --features x11
}

# allow start xremap witout sudo
# https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
# reboot reboot PC
grand_uinput_access() {
  user=$(whoami)
  sudo gpasswd -a "$user" input
  echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
}

install_systemd_service() {
  echo "Install systemd service"
  mkdir -p "$XDG_CONFIG_HOME/xremap"
  cp config.yml "$XDG_CONFIG_HOME/xremap/"
  cp xremap.service "$XDG_CONFIG_HOME/systemd/user/"
  systemctl --user daemon-reload
  systemctl --user start xremap.service
  systemctl --user is-active --quiet xremap.service || {
    log_error "xremap failed to start."
    log_error "Debug by running cmd in next line."
    log_error "systemctl status xremap.service"
    exit 1
  }
  systemctl --user enable xremap.service
}

install() {
  check_ostype
  check_if_gnome_environment
  install_xremap
  grand_uinput_access
  install_systemd_service
}

uninstall() {
  systemctl --user stop xremap.service
  systemctl --user disable xremap.service
  rm "$XDG_CONFIG_HOME/systemd/user/xremap.service"
  rm -rf "$XDG_CONFIG_HOME/xremap"
  systemctl --user daemon-reload
  cargo uninstall xremap --features x11
}

install
#uninstall
