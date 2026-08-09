#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_file="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates/bat.tmTheme"
readonly bat_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/bat"
readonly themes_dir="$bat_config_dir/themes"
readonly config_file="$bat_config_dir/config"
readonly theme_file="$themes_dir/caelestia.tmTheme"

[[ -f "$scheme_file" ]] || { echo "sync-bat-theme: missing $scheme_file" >&2; exit 1; }
[[ -f "$template_file" ]] || { echo "sync-bat-theme: missing $template_file" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync-bat-theme: jq is required" >&2; exit 1; }

declare -A colour_map=(
  [background]=background
  [error]=error
  [on_background]=onBackground
  [on_surface_variant]=onSurfaceVariant
  [on_tertiary_container]=onTertiaryContainer
  [outline]=outline
  [outline_variant]=outlineVariant
  [primary]=primary
  [primary_fixed_dim]=primaryFixedDim
  [secondary]=secondary
  [secondary_container]=secondaryContainer
  [surface_container_highest]=surfaceContainerHighest
  [surface_variant]=surfaceVariant
  [terminal_cursor]=onSurface
  [terminal_normal_black]=term0
  [terminal_normal_blue]=term4
  [terminal_normal_cyan]=term6
  [terminal_normal_green]=term2
  [terminal_normal_magenta]=term5
  [terminal_normal_yellow]=term3
  [tertiary]=tertiary
  [tertiary_fixed_dim]=tertiaryFixedDim
)

mkdir -p "$themes_dir"
touch "$config_file"
tmp_theme="$(mktemp "${theme_file}.tmp.XXXXXX")"
tmp_config="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_theme" "$tmp_config"' EXIT
cp "$template_file" "$tmp_theme"

for token in "${!colour_map[@]}"; do
  colour="#$(jq -er --arg key "${colour_map[$token]}" '.colours[$key]' "$scheme_file")"
  sed -i "s/{{colors\.${token}\.default\.hex}}/${colour}/g" "$tmp_theme"
done

if grep -q '{{colors\.' "$tmp_theme"; then
  echo "sync-bat-theme: unresolved colour token in template" >&2
  exit 1
fi

cmp -s "$theme_file" "$tmp_theme" || install -m 0600 "$tmp_theme" "$theme_file"

sed '/^--theme=/d' "$config_file" >"$tmp_config"
[[ ! -s "$tmp_config" ]] || [[ -z "$(tail -c1 "$tmp_config")" ]] || printf '\n' >>"$tmp_config"
printf '%s\n' '--theme=caelestia' >>"$tmp_config"
cmp -s "$config_file" "$tmp_config" || install -m 0600 "$tmp_config" "$config_file"

if command -v bat >/dev/null 2>&1; then
  bat cache --build >/dev/null
elif command -v batcat >/dev/null 2>&1; then
  batcat cache --build >/dev/null
else
  echo "sync-bat-theme: bat executable not found" >&2
fi
