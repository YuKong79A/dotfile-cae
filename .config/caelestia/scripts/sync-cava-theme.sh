#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/cava/themes/caelestia"
readonly config_file="${XDG_CONFIG_HOME:-$HOME/.config}/cava/config"

[[ -f "$scheme_file" ]] || { echo "sync-cava-theme: missing $scheme_file" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync-cava-theme: jq is required" >&2; exit 1; }

primary_container="#$(jq -er '.colours.primaryContainer' "$scheme_file")"
primary="#$(jq -er '.colours.primary' "$scheme_file")"
on_primary_container="#$(jq -er '.colours.onPrimaryContainer' "$scheme_file")"

mkdir -p "$(dirname "$theme_file")"
tmp_file="$(mktemp "${theme_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

sed \
  -e "s/{{primary_container}}/$primary_container/g" \
  -e "s/{{primary}}/$primary/g" \
  -e "s/{{on_primary_container}}/$on_primary_container/g" \
  >"$tmp_file" <<'EOF'
[color]
foreground = '{{primary}}'

gradient = 1
gradient_color_1 = '{{primary_container}}'
gradient_color_2 = '{{primary}}'
gradient_color_3 = '{{on_primary_container}}'

horizontal_gradient = 0
horizontal_gradient_color_1 = '{{primary_container}}'
horizontal_gradient_color_2 = '{{primary}}'
horizontal_gradient_color_3 = '{{on_primary_container}}'
horizontal_gradient_color_4 = '{{primary}}'
horizontal_gradient_color_5 = '{{primary_container}}'
EOF

if ! cmp -s "$theme_file" "$tmp_file"; then
  install -m 0600 "$tmp_file" "$theme_file"
fi

# Cava does not automatically load files from its themes directory. Replace the
# active config's [color] section so a normal `cava` launch follows Caelestia.
if [[ -f "$config_file" ]]; then
  config_tmp="$(mktemp "${config_file}.tmp.XXXXXX")"
  awk -v theme="$theme_file" '
    BEGIN {
      while ((getline line < theme) > 0) theme_text = theme_text line "\n"
      close(theme)
    }
    /^\[color\][[:space:]]*$/ {
      printf "%s", theme_text
      skipping = 1
      next
    }
    skipping && /^\[[^]]+\][[:space:]]*$/ { skipping = 0 }
    !skipping { print }
  ' "$config_file" >"$config_tmp"
  if ! cmp -s "$config_file" "$config_tmp"; then
    install -m 0600 "$config_tmp" "$config_file"
  fi
  rm -f "$config_tmp"
fi

if pgrep -x cava >/dev/null && ! pgrep -ax cava | grep -q -- '-p.*stdin'; then
  pkill -USR1 -x cava || true
fi
