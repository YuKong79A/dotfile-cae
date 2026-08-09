#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/theme"
theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/themes/OriDark"

mkdir -p "$theme_dir"
install -m 0644 "$state_dir/fcitx5-ori-theme.conf" "$theme_dir/theme.conf"
install -m 0644 "$state_dir/fcitx5-ori-panel.svg" "$theme_dir/panel.svg"
install -m 0644 "$state_dir/fcitx5-ori-highlight.svg" "$theme_dir/highlight.svg"

if command -v fcitx5 >/dev/null 2>&1; then
  if command -v setsid >/dev/null 2>&1; then
    setsid -f fcitx5 -r >/dev/null 2>&1 || true
  else
    fcitx5 -r >/dev/null 2>&1 &
  fi
fi
