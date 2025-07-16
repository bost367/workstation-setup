#!/usr/bin/env bash

set -u

export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# color palette
clr_reset=$(tput sgr0)
clr_bold=$(tput bold)
clr_cyan=$(tput setaf 6)
clr_yellow=$(tput setaf 3)
clr_red=$(tput setaf 1)

log_info() {
  echo -e "[$(date +"%F %T")] ${clr_cyan}info:${clr_reset} ${1}" >&2
}

log_warn() {
  echo -e "[$(date +"%F %T")] ${clr_yellow}warn:${clr_reset} ${1}" >&2
}

log_error() {
  echo -e "[$(date +"%F %T")] ${clr_red}error:${clr_reset} ${1}" >&2
}

check_ostype() {
  if ! uname -a | grep -q "$1"; then
    log_error "This script is designed to run only on $1."
    exit 1
  fi
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

download() {
  if check_cmd curl; then
    curl --proto "=https" --tlsv1.2 --location --silent --show-error --fail "$1" && return 0
  elif check_cmd wget; then
    wget --https-only --secure-protocol=TLSv1_2 --quiet -O - "$1" && return 0
  else
    log_error "Neither curl nor wget is installed."
    exit 1
  fi
  return 1
}

# Homebrew needs for support multiple OS: Linux & MacOS.
install_homebrew() {
  log_info "Install Homebrew."
  NONINTERACTIVE=1 bash -c "$(download https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # https://docs.brew.sh/Tips-and-Tricks#loading-homebrew-from-the-same-dotfiles-on-different-operating-systems
  command -v brew || export PATH="$PATH:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin"
  command -v brew && eval "$(brew shellenv)"
  # https://docs.brew.sh/Analytics
  brew analytics off
}

setup_zsh() {
  log_info "Setup zsh."
  mkdir -p "${ZDOTDIR}"

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

  # https://github.com/zsh-users/zsh-autosuggestions
  log_info "Install zsh commands autocompletition."
  brew install -q zsh-autosuggestions

  # Enable highlighting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  log_info "Install zsh commands highlighting."
  brew install -q zsh-syntax-highlighting

  cat <<'EOF' >"$ZDOTDIR/.zshrc"
# https://docs.brew.sh/Tips-and-Tricks#load-homebrew-from-the-same-dotfiles-on-different-operating-systems
command -v brew &> /dev/null || PATH="$PATH:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin"
command -v brew &> /dev/null && eval "$(brew shellenv)"

# Zsh plugins
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
EOF
}

install_tui() {
  log_info "Install TUI CLIs."
  local tools=(
    yazi      # File manager
    zellij    # Terminal splitter
    eza       # Better ls
    starship  # Prompt beautifier
    lazygit   # Git interactive tool
    git-delta # Side-by-side diff for lazygit
    fzf       # Fuzzy finder
    btop      # Better htop
    bat       # Better cat
    cloc      # Project file summary
    lazydocker
  )
  brew install -q "${tools[@]}"
}

setup_neovim() {
  log_info "Installing Neovim and related tools (xclip, shellcheck, etc.)."
  local tools=(
    nvim
    xclip      # Used by Nvim to share OS and Nvim buffers (run `:h clipboard` for details)
    libxml2    # XML formatter
    shellcheck # Shell linter. Used by bash-language-server.
    shfmt      # Shell formatter
    stylua     # Lua formatter
    yq         # YAML file formatter
    jq         # JSON file formatter
  )
  brew install -q "${tools[@]}"
}

# Such toolchains requires bash/zsh file modification.
setup_toolchains() {
  log_info "Installing toolchains."
  install_rust
  install_golang
  install_java
  install_nodejs
}

install_rust() {
  log_info "Install Rust."
  download https://sh.rustup.rs | sh -s -- -yq
}

install_golang() {
  log_info "Installing Goalng."
  brew install -q go
}

install_java() {
  log_info "Install sdkman - JVM toolchain management."
  set +u # https://github.com/sdkman/sdkman-cli/issues/597
  download "https://get.sdkman.io" | bash
  # shellcheck source=/dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh"

  log_info "Install Java (21.0.5-tem)."
  sdk install java 21.0.5-tem
  set -u
}

install_nodejs() {
  log_info "Install Nodejs and npm."
  brew install -q node
}

print_to_do_list() {
  cat <<EOF

Environment setup complete. Reboot your PC to apply changes.
Additional steps to complete manually:

${clr_bold}Setup .gitconfig file:${clr_reset}
> git config --global user.name <Name>
> git config --global user.email <Email>
> git config --global pull.rebase true

${clr_bold}Generate SSH key for GitHub:${clr_reset}
  Follow instructions at: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key

EOF
}
