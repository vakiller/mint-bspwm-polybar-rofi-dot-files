#!/usr/bin/env bash
# Menu nguồn kiểu Caelestia (rofi). Đăng xuất / khởi động lại / tắt máy sẽ hỏi xác nhận.
DIR="$(cd "$(dirname "$0")" && pwd)"
read -r X Y < <("$DIR/popup-pos.sh" 420)

I_POWER=$'' I_LOCK=$'' I_SLEEP=$'' I_LOGOUT=$'' I_RESTART=$''
I_CHECK=$'' I_CLOSE=$''

item() { printf "<span font='Material Symbols Rounded 22'>%s</span>\n<span size='small'>%s</span>|" "$1" "$2"; }

TITLE=rofi-popup   # hộp xác nhận mở sau menu → rofi-popup-re (hiện tức thì)

# $1 tiêu đề (markup), $2 icon tiêu đề, $3 dòng urgent (-u), rest: các item
popup() {
    local mesg=$1 icon=$2 urgent=$3; shift 3
    local cols=$(( $# / 2 ))
    local items="" i
    for ((i = 1; i <= $#; i += 2)); do items+=$(item "${!i}" "$(eval echo "\${$((i + 1))}")"); done
    printf '%s' "${items%|}" | rofi -dmenu -i -markup-rows -no-custom -format i -sep '|' -eh 2 \
        -mesg "$mesg" -window-title "$TITLE" -theme power -u "$urgent" \
        -theme-str "window { x-offset: ${X}px; y-offset: ${Y}px; }
textbox-picon { content: \"$icon\"; }
listview { columns: $cols; }"
}

confirm() { # $1 câu hỏi, $2 icon
    TITLE=rofi-popup-re
    [[ $(popup "<b>$1</b>" "$2" 0 "$I_CHECK" "Đồng ý" "$I_CLOSE" "Huỷ") == 0 ]]
}

up=$(uptime -p | sed 's/^up //; s/ hours\?/h/; s/ minutes\?/m/; s/ days\?/d/; s/,//g')
choice=$(popup "<b>$USER</b>  <span alpha='60%'>· bật $up</span>" "$I_POWER" 4 \
    "$I_LOCK" "Khoá" "$I_SLEEP" "Ngủ" "$I_LOGOUT" "Đăng xuất" "$I_RESTART" "Khởi động" "$I_POWER" "Tắt máy")

case $choice in
    0) light-locker-command -l 2>/dev/null || dm-tool lock ;;
    1) systemctl suspend ;;
    2) confirm "Đăng xuất khỏi bspwm?" "$I_LOGOUT" && bspc quit ;;
    3) confirm "Khởi động lại máy?" "$I_RESTART" && systemctl reboot ;;
    4) confirm "Tắt máy?" "$I_POWER" && systemctl poweroff ;;
esac
