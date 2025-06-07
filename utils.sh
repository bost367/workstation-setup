#!/usr/bin/env bash

set -u

export XDG_CONFIG_HOME="$HOME/.config"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# color palette
clr_reset=$(tput sgr0)
clr_bold=$(tput bold)
clr_cyan="\e[0;36m"
clr_yellow="\e[0;33m"
clr_red="\e[0;31m"

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
    log_error "This script aim to be run on Ubuntu distro only."
    exit 1
  fi
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

download() {
  if check_cmd curl; then
    curl --proto "=https" --tlsv1.2 --location --silent --show-error --fail "$1"
  elif check_cmd wget; then
    wget --https-only --secure-protocol=TLSv1_2 --quiet -O - "$1"
  else
    log_error "No curl or wget on your distro were found."
    exit 1
  fi
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
  log_info "Install zsh."
  mkdir -p "${ZDOTDIR}"
  brew install -q zsh

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
  brew install -q zsh-autosuggestions

  # Enable highlighting whilst they are typed at a zsh.
  # This helps in reviewing commands before running them.
  # https://github.com/zsh-users/zsh-syntax-highlighting
  log_info "Install zsh commands highlighting."
  brew install -q zsh-syntax-highlighting

  cat <<EOF >"$ZDOTDIR/.zshrc"
# Plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Export brew env
eval "\$($(brew --prefix)/bin/brew shellenv)"
EOF
}

# Required by other tools.
install_required_cli() {
  log_info "Install required cli."
  brew install -q \
    git \
    cmake \
    unzip \
    zip \
    procps \
    file
}

install_tui() {
  log_info "Install TUI CLIs."
  brew install -q yazi      # Filemanager
  brew install -q zellij    # Terminal splitter
  brew install -q eza       # Better ls
  brew install -q starship  # beautify prompt for terminal input
  brew install -q lazygit   # Git interactive tool
  brew install -q git-delta # Side by side diff view fo lazygit
  brew install -q fzf       # Fuzzy finder
  brew install -q btop      # Better htop
  brew install -q bat       # Better cat
  brew install -q cloc      # Project file summary
  brew install -q lazydocker
}

setup_neovim() {
  log_info "Install Neovim setup."
  brew install -q nvim
  brew install -q xclip      # Used by Nvim to share OS and Nvim buffers (run `:h clipboard` for details)
  brew install -q libxml2    # XML formatter
  brew install -q shellcheck # Shell linter. Used by bash-language-server.
  brew install -q shfmt      # Shell formatter
  brew install -q stylua     # Lua formatter
  brew install -q yq         # YAML file formatter
  brew install -q jq         # JSON file formatter
}

# Such toolchains requires bash/zsh file modification.
setup_toolcahins() {
  log_info "Toolchains instalation."
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
  log_info "Install Goalng."
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

Environment has been setup. Reboot your PC to finish.
Not all installations is automated.
See the next steps to complete setup by your self.

${clr_bold}Setup .gitconfig file:${clr_reset}
> git config --global user.name <Name>
> git config --global user.email <Email>
> git config --global pull.rebase true

${clr_bold}Generate ssh key and publish public key on GitHub:${clr_reset}
  https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key

EOF
}
