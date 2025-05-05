#!/usr/bin/env bash

set -e
set -u

declare -A keymap=(
  ["/org/gnome/desktop/wm/keybindings/activate-window-menu"]="['']"           # Disable window menu
  ["/org/gnome/mutter/edge-tiling"]="false"                                   # Disable windos upscale, when drop windpw on sreen adge
  ["/org/gnome/shell/keybindings/show-screenshot-ui"]="['<Shift><Super>4']"   # Capture a portion of the screen
  ["/org/gnome/shell/keybindings/screenshot"]="['<Shift><Super>3']"           # Capture the entire screen
  ["/org/gnome/desktop/wm/keybindings/close"]="['<Super>q']"                  # Close window
  ["/org/gnome/desktop/wm/keybindings/minimize"]="['<Super>m']"               # Hide window
  ["/org/gnome/shell/keybindings/toggle-overview"]="['<Super>space']"         # Toogle application overview & search
  ["/org/gnome/mutter/overlay-key"]="''"                                      # Disable search application by [Super]
  ["/org/gnome/settings-daemon/plugins/media-keys/screensaver"]="['<Control><Super>q']"   # Lock screen

  # Switch keyboard language
  ["/org/gnome/desktop/wm/keybindings/switch-input-source"]="['<Alt>space', ':XF86Keyboard']"
  ["/org/gnome/desktop/wm/keybindings/switch-input-source-backward"]="['<Shift><Alt>space', '<Shift>XF86Keyboard']"

  # Change window switching
  ["/org/gnome/desktop/wm/keybindings/switch-applications"]="['<Super>Tab']"
  ["/org/gnome/desktop/wm/keybindings/switch-applications-backward"]="['<Shift><Super>Tab']"
  ["/org/gnome/desktop/wm/keybindings/switch-group"]="['<Super>Above_Tab']"
  ["/org/gnome/desktop/wm/keybindings/switch-group-backward"]="['<Shift><Super>Above_Tab']"
  ["/org/gnome/desktop/wm/keybindings/switch-windows"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-windows-backward"]="['']"

  # Workspace switching
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-right"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-left"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-right"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-left"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-up"]="['']"
  ["/org/gnome/desktop/wm/keybindings/switch-to-workspace-down"]="['']"
  ["/org/gnome/desktop/wm/keybindings/move-to-workspace-right"]="['']"
  ["/org/gnome/desktop/wm/keybindings/move-to-workspace-left"]="['']"
  ["/org/gnome/desktop/wm/keybindings/move-to-workspace-up"]="['']"
  ["/org/gnome/desktop/wm/keybindings/move-to-workspace-down"]="['']"
)

switch_macos_keymap() {
  for path in "${!keymap[@]}"; do
    local shortcut
    shortcut="${keymap[$path]}";
    dconf write "$path" "$shortcut"
  done
}

switch_gnome_keymap() {
  for path in "${!keymap[@]}"; do
    dconf reset "$path"
  done
}
