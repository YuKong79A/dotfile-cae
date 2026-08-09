#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_dir="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates"
readonly flavor_dir="${XDG_CONFIG_HOME:-$HOME/.config}/yazi/flavors/caelestia.yazi"

[[ -f "$scheme_file" ]] || { echo "sync-yazi-theme: missing $scheme_file" >&2; exit 1; }
[[ -f "$template_dir/yazi-flavor.toml" ]] || { echo "sync-yazi-theme: missing flavor template" >&2; exit 1; }
[[ -f "$template_dir/yazi.tmTheme" ]] || { echo "sync-yazi-theme: missing syntax template" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync-yazi-theme: jq is required" >&2; exit 1; }

declare -A colour_map=(
  [background]=background
  [error]=error
  [error_container]=errorContainer
  [on_background]=onBackground
  [on_error_container]=onErrorContainer
  [on_primary]=onPrimary
  [on_secondary]=onSecondary
  [on_surface]=onSurface
  [on_surface_variant]=onSurfaceVariant
  [on_tertiary]=onTertiary
  [on_tertiary_container]=onTertiaryContainer
  [outline]=outline
  [outline_variant]=outlineVariant
  [primary]=primary
  [primary_container]=primaryContainer
  [primary_fixed_dim]=primaryFixedDim
  [secondary]=secondary
  [secondary_container]=secondaryContainer
  [surface]=surface
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
  [tertiary_container]=tertiaryContainer
  [tertiary_fixed_dim]=tertiaryFixedDim
)

render_template() {
  local source=$1 target=$2 tmp token colour
  tmp="$(mktemp "${target}.tmp.XXXXXX")"
  cp "$source" "$tmp"

  for token in "${!colour_map[@]}"; do
    colour="#$(jq -er --arg key "${colour_map[$token]}" '.colours[$key]' "$scheme_file")"
    sed -i "s/{{colors\.${token}\.default\.hex}}/${colour}/g" "$tmp"
  done

  if grep -q '{{colors\.' "$tmp"; then
    echo "sync-yazi-theme: unresolved colour token in $source" >&2
    rm -f "$tmp"
    return 1
  fi

  cmp -s "$target" "$tmp" || install -m 0600 "$tmp" "$target"
  rm -f "$tmp"
}

mkdir -p "$flavor_dir"
render_template "$template_dir/yazi-flavor.toml" "$flavor_dir/flavor.toml"
render_template "$template_dir/yazi.tmTheme" "$flavor_dir/tmtheme.xml"
