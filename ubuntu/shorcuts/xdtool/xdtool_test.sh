#!/bin/bash
curr=$(xdotool getwindowfocus)
firefox=$(xdotool search -class alacritty)
if [[ $firefox = *$curr* ]]; then
    echo Current window is of firefox class.
else
    echo Current window is not firefox class.
fi
echo $curr
