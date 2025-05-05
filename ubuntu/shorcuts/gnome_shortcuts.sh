#!/bin/bash

osx() {
  # Disable window menu
  dconf write /org/gnome/desktop/wm/keybindings/activate-window-menu "['']"
  # Disable windos upscale, when drop windpw on sreen adge
  dconf write /org/gnome/mutter/edge-tiling "false"
  # Capture the entire screen
  dconf write /org/gnome/shell/keybindings/screenshot "['<Shift><Alt>3']"
  # Capture a portion of the screen
  dconf write /org/gnome/shell/keybindings/show-screenshot-ui "['<Shift><Alt>4']"
  # Close window
  dconf write /org/gnome/desktop/wm/keybindings/close "['<Alt>q']"
  # Hide window
  dconf write /org/gnome/desktop/wm/keybindings/minimize "['<Alt>h']"
  # Lock screen
  dconf write /org/gnome/settings-daemon/plugins/media-keys/screensaver "['<Control><Alt>q']"
  # Toogle application overview & search
  dconf write /org/gnome/shell/keybindings/toggle-overview "['<Alt>space']"
  # Disable search application by [Super]
  dconf write /org/gnome/mutter/overlay-key "'Super_R'"

  # Next setting change window switching
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['<Alt>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Shift><Alt>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group "['<Alt>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group-backward "['<Shift><Alt>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['']"

  # Workspace switching
  # dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Ctrl>Right']"
  # dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['<Ctrl>Left']"
  # Swap Super and Control keys - per user setting
  # dconf write /org/gnome/desktop/input-sources xkb-options "'ctrl:swap_lwin_lctl', 'ctrl:swap_rwin_rctl'"
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
