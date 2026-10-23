#!/bin/sh
# In ra "X Y" để đặt popup có độ rộng $1 ngay dưới con trỏ chuột (căn giữa), sát mép dưới polybar.
# Biến môi trường: POPUP_GAP (khoảng cách tới bar, mặc định 0 = dính liền), BAR_BOTTOM (mặc định 46 = offset-y 8 + height 38).
exec python3 - "${1:-340}" <<'PY'
import os, sys
import gi
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk

width = int(sys.argv[1])
d = Gdk.Display.get_default()
_, px, py = d.get_default_seat().get_pointer().get_position()
geo = d.get_monitor_at_point(px, py).get_geometry()
margin = round(geo.width * 0.01)  # khớp offset-x = 1% của bar
x = px - width // 2
x = max(geo.x + margin, min(x, geo.x + geo.width - width - margin))
y = geo.y + int(os.environ.get("BAR_BOTTOM", 46)) + int(os.environ.get("POPUP_GAP", 0))
print(x, y)
PY
