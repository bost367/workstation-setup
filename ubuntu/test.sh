#!/usr/bin/env bash

set -u

tempdir() {
  local tempprefix
  local tmpdir
  tempprefix=$(basename "$0")
  # https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
  #tmpdir=$(mktemp -d -t "$tempprefix" 2>/dev/null) || {
  tmpdir=$(mktemp -d 2>/dev/null || mktemp -d -t "$tempprefix") || {
    #log_warn "Create tmp directory is failure."
    echo "Create tmp directory is failure."
    return 1
  }
  echo "$tmpdir"
}

WORKSTATION_TMP_DIR="$(tempdir || exit 1)"
trap '{ rm -rf -- "$WORKSTATION_TMP_DIR"; }' EXIT

install_nerd_fonts() {
  #log_info "Install Nerd Fonts."
  echo "Install Nerd Fonts."
  local temp_dir="$WORKSTATION_TMP_DIR\nerd-fonts"
  git clone --depth=1 -q --filter=blob:none --sparse https://github.com/ryanoasis/nerd-fonts.git "$temp_dir"
  echo $temp_dir 
  ls $temp_dir 
  # git -C "$temp_dir" sparse-checkout add patched-fonts/JetBrainsMono
  # bash "${temp_dir}/install.sh" JetBrainsMono
  # rm -rf "$temp_dir"
}

install_nerd_fonts
