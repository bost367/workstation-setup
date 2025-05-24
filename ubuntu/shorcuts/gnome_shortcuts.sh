#!/usr/bin/env bash

osx() {
  # Disable window menu
  dconf write /org/gnome/desktop/wm/keybindings/activate-window-menu "['']"
  # Disable windos upscale, when drop windpw on sreen adge
  dconf write /org/gnome/mutter/edge-tiling "false"
  # Capture the entire screen
  dconf write /org/gnome/shell/keybindings/screenshot "['<Shift><Super>3']"
  # Capture a portion of the screen
  dconf write /org/gnome/shell/keybindings/show-screenshot-ui "['<Shift><Super>4']"
  # Close window
  dconf write /org/gnome/desktop/wm/keybindings/close "['<Super>q']"
  # Hide window
  dconf write /org/gnome/desktop/wm/keybindings/minimize "['<Super>m']"
  # Lock screen
  dconf write /org/gnome/settings-daemon/plugins/media-keys/screensaver "['<Control><Super>q']"
  # Toogle application overview & search
  dconf write /org/gnome/shell/keybindings/toggle-overview "['<Super>space']"
  # Disable search application by [Super]
  dconf write /org/gnome/mutter/overlay-key "''"
  # Switch keyboard language
  dconf write /org/gnome/desktop/wm/keybindings/switch-input-source "['<Alt>space', ':XF86Keyboard']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-input-source-backward "['<Shift><Alt>space', '<Shift>XF86Keyboard']"

  # Next setting change window switching
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['<Super>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Shift><Super>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group "['<Super>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group-backward "['<Shift><Super>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['']"

  # Workspace switching
  # dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Ctrl>Right']"
  # dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['<Ctrl>Left']"
}

reset() {
  dconf reset /org/gnome/desktop/wm/keybindings/activate-window-menu
  dconf reset /org/gnome/mutter/edge-tiling
  dconf reset /org/gnome/shell/keybindings/show-screenshot-ui
  dconf reset /org/gnome/shell/keybindings/screenshot
  dconf reset /org/gnome/desktop/wm/keybindings/close
  dconf reset /org/gnome/desktop/wm/keybindings/minimize
  dconf reset /org/gnome/settings-daemon/plugins/media-keys/screensaver
  dconf reset /org/gnome/shell/keybindings/toggle-overview
  dconf reset /org/gnome/mutter/overlay-key
  dconf reset /org/gnome/desktop/wm/keybindings/switch-input-source
  dconf reset /org/gnome/desktop/wm/keybindings/switch-input-source-backward
  dconf reset /org/gnome/desktop/wm/keybindings/switch-applications
  dconf reset /org/gnome/desktop/wm/keybindings/switch-applications-backward
  dconf reset /org/gnome/desktop/wm/keybindings/switch-group
  dconf reset /org/gnome/desktop/wm/keybindings/switch-group-backward
  dconf reset /org/gnome/desktop/wm/keybindings/switch-windows
  dconf reset /org/gnome/desktop/wm/keybindings/switch-windows-backward
  dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-right
  dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-left
}

"$@"
