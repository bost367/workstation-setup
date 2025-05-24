##!/usr/bin/env bash

#dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['']"
dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Ctrl>Right']"
#xdotool key --window="$(xdotool getactivewindow)" ctrl+Right
#xdotool key ctrl+Right

#sleep .3
#dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-right "['<Ctrl>Right']"

# dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['']"
#
# sleep .3
# dconf write /org/gnome/desktop/wm/keybindings/switch-to-workspace-left "['<Ctrl>Left']"


# code below is working in terminal
# example: 
#   1. run "sleep 2 && xdotool key --window="$(xdotool getactivewindow)" ctrl+Right" in terminal
#   2. switch in text area window
# xdotool key --window="$(xdotool getactivewindow)" ctrl+Right
