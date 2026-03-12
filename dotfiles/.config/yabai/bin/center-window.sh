#!/usr/bin/env sh

set -eu

window_json="$(yabai -m query --windows --window)"

if ! printf '%s\n' "$window_json" | grep -q '"is-floating":[[:space:]]*true'; then
  yabai -m window --toggle float
fi

# 1 row x 6 columns, start at column 1, span 4 columns:
# centered, 2/3 width, full height.
yabai -m window --grid 1:6:1:0:4:1
