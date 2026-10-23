#!/bin/bash
# Build picom v13 (animations) into ~/.local/bin/picom without touching the system picom.
# Mint 22 ships libconfig 1.5 but picom v13 needs >= 1.7, so libconfig 1.7.3 is built
# as a static library in the build dir and linked in (no extra runtime dependency).
set -euo pipefail

PICOM_TAG=v13
LIBCONFIG_VER=1.7.3
WORK="${WORK:-$HOME/.cache/picom-build}"

DEPS=(libconfig-dev libdbus-1-dev libegl-dev libev-dev libgl-dev libepoxy-dev libpcre2-dev
      libpixman-1-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-damage0-dev
      libxcb-glx0-dev libxcb-image0-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev
      libxcb-render-util0-dev libxcb-shape0-dev libxcb-util-dev libxcb-xfixes0-dev
      meson ninja-build uthash-dev git curl build-essential)

missing=()
for p in "${DEPS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
if ((${#missing[@]})); then
    echo "Installing build dependencies: ${missing[*]}"
    sudo apt install -y "${missing[@]}"
fi

mkdir -p "$WORK"
cd "$WORK"

# libconfig >= 1.7 (static)
if [ ! -f "$WORK/libconfig/lib/libconfig.a" ]; then
    curl -fL -o libconfig.tar.gz \
        "https://github.com/hyperrealm/libconfig/releases/download/v$LIBCONFIG_VER/libconfig-$LIBCONFIG_VER.tar.gz"
    tar xzf libconfig.tar.gz
    (cd "libconfig-$LIBCONFIG_VER" &&
        ./configure --prefix="$WORK/libconfig" --disable-shared --enable-static --with-pic \
            --disable-cxx --disable-examples >/dev/null &&
        make -j"$(nproc)" >/dev/null && make install >/dev/null)
fi

# picom
rm -rf picom
git clone -q --depth 1 --branch "$PICOM_TAG" https://github.com/yshui/picom.git
cd picom
PKG_CONFIG_PATH="$WORK/libconfig/lib/pkgconfig" \
    meson setup --buildtype=release --prefix="$HOME/.local" -Dwith_docs=false build >/dev/null
ninja -C build

mkdir -p "$HOME/.local/bin"
install -m755 build/src/picom "$HOME/.local/bin/picom"
"$HOME/.local/bin/picom" --version

echo
echo "Installed ~/.local/bin/picom. bspwmrc uses it automatically on next login."
echo "To switch now:  pkill -x picom; ~/.local/bin/picom --config ~/.config/picom/picom.conf &"
echo "To go back to v10: rm ~/.local/bin/picom (bspwmrc then uses picom-legacy.conf)"
