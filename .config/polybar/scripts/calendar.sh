#!/usr/bin/env bash
# Popup lịch kiểu Caelestia (rofi). ←/→ hoặc nút ‹ › để chuyển tháng, nút "hôm nay" để quay về.
# Đóng bằng Esc hoặc bấm ra ngoài; bấm vào ô ngày không đóng lịch.
DIR="$(cd "$(dirname "$0")" && pwd)"
read -r X Y < <("$DIR/popup-pos.sh" 364)

I_PREV=$'' I_NEXT=$'' I_TODAY=$''
WEEKDAYS=(T2 T3 T4 T5 T6 T7 CN)
DAYNAMES=("" "Thứ Hai" "Thứ Ba" "Thứ Tư" "Thứ Năm" "Thứ Sáu" "Thứ Bảy" "Chủ Nhật")

today_y=$(date +%Y) today_m=$((10#$(date +%m))) today_d=$((10#$(date +%d)))
y=$today_y m=$today_m
title=rofi-popup   # lần đầu: picom cho trượt ra từ bar; mở lại: rofi-popup-re (hiện tức thì)

while :; do
    first="$(printf '%04d-%02d-01' "$y" "$m")"
    lead=$(( $(date -d "$first" +%u) - 1 ))                       # số ô của tháng trước
    dim=$((10#$(date -d "$first +1 month -1 day" +%d)))           # số ngày trong tháng
    prev_dim=$((10#$(date -d "$first -1 day" +%d)))

    rows=() active=""
    for w in "${WEEKDAYS[@]}"; do rows+=("<span size='small' weight='bold'>$w</span>"); done
    for ((i = lead; i > 0; i--)); do rows+=("<span alpha='35%'>$((prev_dim - i + 1))</span>"); done
    for ((d = 1; d <= dim; d++)); do
        [[ $y -eq $today_y && $m -eq $today_m && $d -eq $today_d ]] && active=$(( ${#rows[@]} ))
        rows+=("$d")
    done
    for ((d = 1; ${#rows[@]} < 49; d++)); do rows+=("<span alpha='35%'>$d</span>"); done

    theme="window { x-offset: ${X}px; y-offset: ${Y}px; }
textbox-clock { content: \"$(date +%H:%M)\"; }
textbox-today { content: \"${DAYNAMES[$(date +%u)]}, $(date +%d/%m/%Y)\"; }
button-prev { content: \"$I_PREV\"; }
button-next { content: \"$I_NEXT\"; }
button-today { content: \"$I_TODAY\"; }"

    printf '%s\n' "${rows[@]}" | rofi -dmenu -i -markup-rows -no-custom \
        -mesg "<b>Tháng $m · $y</b>" \
        -window-title "$title" -theme calendar -theme-str "$theme" \
        -u 0-6 ${active:+-a "$active" -selected-row "$active"} \
        -kb-move-char-back Control+b -kb-move-char-forward Control+f \
        -kb-custom-1 Left -kb-custom-2 Right -kb-custom-3 t >/dev/null
    rc=$? title=rofi-popup-re
    case $rc in
        10) ((m == 1)) && { m=12; ((y--)); } || ((m--)) ;;
        11) ((m == 12)) && { m=1; ((y++)); } || ((m++)) ;;
        12) y=$today_y m=$today_m ;;
        0) ;;            # bấm vào ô ngày/thứ: giữ lịch mở, không đóng
        *) exit 0 ;;     # Esc hoặc bấm ra ngoài
    esac
done
