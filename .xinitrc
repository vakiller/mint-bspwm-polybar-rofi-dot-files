#!/bin/sh

# Optional fallback for manual startx.
# LightDM users normally do NOT need this file.

[ -f "$HOME/.xprofile" ] && . "$HOME/.xprofile"

xrandr --auto
exec bspwm
