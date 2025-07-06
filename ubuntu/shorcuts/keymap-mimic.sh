#!/usr/bin/env bash

set -e
set -u

source ./gnome-keymap.sh

usage() {
  cat <<EOF
Description:
  Set up Ubuntu keyboard layout to mimic macOS

Usage:
  keymap-mimic.sh [COMMAND]

Commands:
  install     Change Ubuntu keymap to match macOS
  uninstall   Return keymap to default settings
  help        Displays this help message
EOF
}

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
    log_error "GNOME Shell not found."
    exit 1
  fi
  local shell_version_out
  local shell_version
  shell_version_out=$(gnome-shell --version)
  if [[ $shell_version_out =~ GNOME\ Shell\ ([0-9]+) ]]; then
    shell_version=${BASH_REMATCH[1]}
    if [[ $shell_version == 46 ]]; then return; fi
    cat <<EOF >&2

The current GNOME Shell (version $shell_version) is unsupported. You may bypass this check by
editing the script yourself, but keep in mind that the script was tested only with version 46.

EOF
    exit 1
  fi
}

install_xremap() {
  if ! check_cmd cargo; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -yq
  fi
  rustup -q update
  cargo install -q xremap --features x11
}

# allow start xremap witout sudo
# https://github.com/xremap/xremap?tab=readme-ov-file#running-xremap-without-sudo
# reboot PC needed after execution
grand_uinput_access() {
  user=$(whoami)
  sudo gpasswd -a "$user" input
  echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules
}

install_systemd_service() {
  echo "Install systemd service"
  mkdir -p "$XDG_CONFIG_HOME/xremap"
  cp config.yml "$XDG_CONFIG_HOME/xremap/"
  mkdir -p "$XDG_CONFIG_HOME/systemd/user/"
  cp xremap.service "$XDG_CONFIG_HOME/systemd/user/"
  systemctl --user daemon-reload
  systemctl --user start xremap.service
  systemctl --user is-active --quiet xremap.service || {
    log_error "xremap failed to start. Try to debug by running cmd in next line:"
    log_error "systemctl --user status xremap.service"
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
  switch_macos_keymap
}

uninstall() {
  systemctl --user stop xremap.service
  systemctl --user disable xremap.service
  rm "$XDG_CONFIG_HOME/systemd/user/xremap.service"
  rm -rf "$XDG_CONFIG_HOME/xremap"
  systemctl --user daemon-reload
  cargo uninstall -q xremap
  switch_gnome_keymap
}

if [[ $# = 0 ]]; then
  usage
  exit 1
elif [ "$#" = 1 ]; then
  case "$1" in
  help)
    usage
    exit 0
    ;;
  install)
    install
    ;;
  uninstall)
    uninstall
    ;;
  *)
    usage
    exit 1
    ;;
  esac
else
  log_error "Too many arguments."
  usage
  exit 1
fi
