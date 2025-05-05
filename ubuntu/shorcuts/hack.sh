#!/usr/bin/env bash

right() {
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['']"
  xdotool key --clearmodifiers --window="$(xdotool getactivewindow)" ctrl+Right
  sleep .1
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Ctrl>Right']"
}

left() {
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['']"
  xdotool key --clearmodifiers --window="$(xdotool getactivewindow)" ctrl+Left
  sleep .1
  dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['<Ctrl>Left']"
}

"$@"
