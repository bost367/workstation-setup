#!/usr/bin/env bash

# allow start xream witout sudo
# reboot reboot PC
# user=$(whoami)
# sudo gpasswd -a "$user" input
# echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules

# setup systemd service
cp xremap.service "$XDG_CONFIG_HOME/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable xremap.service
systemctl --user start xremap.service
