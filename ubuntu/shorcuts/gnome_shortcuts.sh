#!/usr/bin/env bash

macos() {
  dconf write /org/gnome/desktop/wm/keybindings/activate-window-menu "['']"           # Disable window menu
  dconf write /org/gnome/mutter/edge-tiling "false"                                   # Disable windos upscale, when drop windpw on sreen adge
  dconf write /org/gnome/shell/keybindings/show-screenshot-ui "['<Shift><Super>4']"   # Capture a portion of the screen
  dconf write /org/gnome/shell/keybindings/screenshot "['<Shift><Super>3']"           # Capture the entire screen
  dconf write /org/gnome/desktop/wm/keybindings/close "['<Super>q']"                  # Close window
  dconf write /org/gnome/desktop/wm/keybindings/minimize "['<Super>m']"               # Hide window
  dconf write /org/gnome/shell/keybindings/toggle-overview "['<Super>space']"         # Toogle application overview & search
  dconf write /org/gnome/mutter/overlay-key "''"                                      # Disable search application by [Super]
  dconf write /org/gnome/settings-daemon/plugins/media-keys/screensaver "['<Control><Super>q']"   # Lock screen

  # Switch keyboard language
  dconf write /org/gnome/desktop/wm/keybindings/switch-input-source "['<Alt>space', ':XF86Keyboard']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-input-source-backward "['<Shift><Alt>space', '<Shift>XF86Keyboard']"

  # Change window switching
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['<Super>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Shift><Super>Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group "['<Super>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-group-backward "['<Shift><Super>Above_Tab']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['']"

  # Workspace switching
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-up "['']"
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-down "['']"
  dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-right "['']"
  dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-left "['']"
  dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-up "['']"
  dconf write /org/gnome/desktop/wm/keybindings/move-to-workspace-down "['']"
}

reset() {
  dconf reset /org/gnome/desktop/wm/keybindings/activate-window-menu
  dconf reset /org/gnome/mutter/edge-tiling
  dconf reset /org/gnome/shell/keybindings/show-screenshot-ui
  dconf reset /org/gnome/shell/keybindings/screenshot
  dconf reset /org/gnome/desktop/wm/keybindings/close
  dconf reset /org/gnome/desktop/wm/keybindings/minimize
  dconf reset /org/gnome/shell/keybindings/toggle-overview
  dconf reset /org/gnome/mutter/overlay-key
  dconf reset /org/gnome/settings-daemon/plugins/media-keys/screensaver
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
  dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-up
  dconf reset /org/gnome/desktop/wm/keybindings/switch-to-workspace-down
  dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-right
  dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-left
  dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-up
  dconf reset /org/gnome/desktop/wm/keybindings/move-to-workspace-down
}

"$@"
