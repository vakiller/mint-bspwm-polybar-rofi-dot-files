#!/bin/sh
killall -q polybar 2>/dev/null

while pgrep -x polybar >/dev/null; do
    sleep 0.2
done

polybar main >>"$HOME/.cache/polybar.log" 2>&1 &
