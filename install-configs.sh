#!/bin/bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-bspwm-$STAMP"

echo "Backup existing configs -> $BACKUP"
mkdir -p "$BACKUP"

for p in bspwm sxhkd picom polybar rofi dunst btop kitty flameshot; do
    if [ -e "$HOME/.config/$p" ]; then
        cp -a "$HOME/.config/$p" "$BACKUP/"
    fi
done

for f in .xprofile .xinitrc; do
    if [ -e "$HOME/$f" ]; then
        cp -a "$HOME/$f" "$BACKUP/"
    fi
done

mkdir -p "$HOME/.config"

for p in bspwm sxhkd picom polybar rofi dunst btop kitty flameshot; do
    rm -rf "$HOME/.config/$p"
    cp -a "$SRC/.config/$p" "$HOME/.config/"
done

cp "$SRC/.xprofile" "$HOME/.xprofile"
cp "$SRC/.xinitrc" "$HOME/.xinitrc"

chmod +x "$HOME/.config/bspwm/bspwmrc"
chmod +x "$HOME/.config/polybar/launch.sh"
chmod +x "$HOME/.config/polybar/scripts/"*.sh

# Font icon cho polybar/rofi/popup: Material Symbols Rounded (Apache 2.0) + Symbols Nerd Font (logo Mint, MIT/OFL)
mkdir -p "$HOME/.local/share/fonts"
cp "$SRC/fonts/"*.ttf "$HOME/.local/share/fonts/"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null
chmod +x "$HOME/.xinitrc"

mkdir -p "$HOME/Pictures/Wallpapers"

echo
echo "Configs installed."
echo "Next:"
echo "  1) Put wallpaper at ~/Pictures/Wallpapers/wall.jpg"
echo "  2) Run fcitx5-configtool and add Unikey (Telex/Unicode)"
echo "  3) Log out and select bspwm in LightDM"
echo
echo "If bspwm is missing from login menu:"
echo "  sudo cp \"$SRC/session/bspwm.desktop\" /usr/share/xsessions/bspwm.desktop"
