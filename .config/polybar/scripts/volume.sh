#!/usr/bin/env bash
# Âm lượng kiểu Caelestia.
#   volume.sh menu        popup rofi (←/→ hoặc nút -/+ chỉnh 5%, chọn thiết bị phát)
#   volume.sh up|down     tăng/giảm 5% + hiện OSD dunst
#   volume.sh mute        bật/tắt tiếng + hiện OSD dunst
DIR="$(cd "$(dirname "$0")" && pwd)"
SINK=@DEFAULT_AUDIO_SINK@
STEP=5

I_UP=$'' I_DOWN=$'' I_MUTE=$'' I_OFF=$''
I_MINUS=$'' I_PLUS=$'' I_SPEAKER=$'' I_HEADPHONES=$'' I_TV=$'' I_TUNE=$''

get_volume() { # -> "PERCENT MUTED(0/1)"
    local out; out=$(wpctl get-volume "$SINK")
    LC_ALL=C awk '{ printf "%d %d\n", $2 * 100 + 0.5, /MUTED/ }' <<<"$out"
}

vol_icon() { # $1 percent, $2 muted
    if (($2 || $1 == 0)); then echo "$I_OFF"; elif (($1 < 34)); then echo "$I_MUTE"
    elif (($1 < 67)); then echo "$I_DOWN"; else echo "$I_UP"; fi
}

osd() {
    local pct muted; read -r pct muted < <(get_volume)
    local text="$pct%" icon=volume-high
    if ((muted || pct == 0)); then icon=volume-off; ((muted)) && text="Đã tắt tiếng"
    elif ((pct < 34)); then icon=volume-low
    elif ((pct < 67)); then icon=volume-medium; fi
    dunstify -a volume -u low -t 1500 -h string:x-dunst-stack-tag:volume \
        -i "$HOME/.config/dunst/icons/$icon.svg" \
        -h int:value:"$((muted ? 0 : pct))" "Âm lượng" "$text"
}

change() {
    case $1 in
        up)   wpctl set-mute "$SINK" 0; wpctl set-volume -l 1.0 "$SINK" "$STEP%+" ;;
        down) wpctl set-volume "$SINK" "$STEP%-" ;;
        mute) wpctl set-mute "$SINK" toggle ;;
    esac
}

sink_icon() { # $1 sink name/description
    case ${1,,} in
        *headphone*|*headset*|*bluez*) echo "$I_HEADPHONES" ;;
        *hdmi*|*displayport*) echo "$I_TV" ;;
        *) echo "$I_SPEAKER" ;;
    esac
}

menu() {
    local X Y; read -r X Y < <("$DIR/popup-pos.sh" 360)
    local title=rofi-popup   # lần đầu trượt ra; mở lại sau khi bấm -/+ thì hiện tức thì
    while :; do
        local pct muted; read -r pct muted < <(get_volume)
        local default names=() rows=() active=""
        default=$(pactl get-default-sink)
        while IFS=$'\t' read -r name desc; do
            [[ $name == "$default" ]] && active=${#rows[@]}
            names+=("$name")
            rows+=("<span font='Material Symbols Rounded 14'>$(sink_icon "$name $desc")</span>  ${desc//&/&amp;}")
        done < <(pactl list sinks | awk -F': ' '/^\tName:/{n=$2} /^\tDescription:/{print n "\t" $2}')
        rows+=("<span font='Material Symbols Rounded 14'>$I_TUNE</span>  Cài đặt âm thanh…")

        local filled=$((pct * 20 / 100)) bar_fill bar_rest
        ((muted)) && filled=0
        bar_fill=$(printf '━%.0s' $(seq 1 $filled) 2>/dev/null); ((filled == 0)) && bar_fill=""
        bar_rest=$(printf '━%.0s' $(seq 1 $((20 - filled))) 2>/dev/null); ((filled == 20)) && bar_rest=""

        local theme="window { x-offset: ${X}px; y-offset: ${Y}px; }
textbox-vicon { content: \"$(vol_icon "$pct" "$muted")\"; }
textbox-vpct { content: \"$( ((muted)) && echo "—" || echo "$pct%")\"; }
textbox-fill { content: \"$bar_fill\"; }
textbox-rest { content: \"$bar_rest\"; }
button-down { content: \"$I_MINUS\"; }
button-up { content: \"$I_PLUS\"; }
button-mute { content: \"$( ((muted)) && echo "$I_OFF" || echo "$I_UP")\"; }"

        local sel rc
        sel=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -markup-rows -no-custom -format i \
            -mesg "<b>Âm lượng</b>" -window-title "$title" -theme volume -theme-str "$theme" \
            ${active:+-a "$active" -selected-row "$active"} \
            -kb-move-char-back Control+b -kb-move-char-forward Control+f \
            -kb-custom-1 Left -kb-custom-2 Right -kb-custom-3 m)
        rc=$? title=rofi-popup-re
        case $rc in
            10) change down ;;
            11) change up ;;
            12) change mute ;;
            0)
                if ((sel == ${#names[@]})); then
                    pavucontrol >/dev/null 2>&1 &
                else
                    pactl set-default-sink "${names[sel]}"
                    pactl list short sink-inputs | cut -f1 | xargs -r -I{} pactl move-sink-input {} "${names[sel]}"
                fi
                exit 0 ;;
            *) exit 0 ;;
        esac
    done
}

case ${1:-menu} in
    menu) menu ;;
    up|down|mute) change "$1"; osd ;;
    *) echo "usage: $0 [menu|up|down|mute]" >&2; exit 1 ;;
esac
