#!/bin/sh

TMUX_CONF="$HOME/.tmux.conf"
OUT="$HOME/.tmux/cheatsheet.txt"

mkdir -p "$HOME/.tmux"

# Generate cheatsheet only if markers exist
if grep -q '^# @cheatsheet_start$' "$TMUX_CONF"; then
  sed -n '
    /^# @cheatsheet_start$/,/^# @cheatsheet_end$/{
      /^# @cheatsheet_/d
      s/^# //
      p
    }
  ' "$TMUX_CONF" > "$OUT"
else
  echo "Cheatsheet block not found in tmux.conf" > "$OUT"
fi

exit 0