#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_file="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates/opencode.json"
readonly output_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/themes"
readonly output_file="$output_dir/caelestia.json"

[[ -f "$scheme_file" ]] || { echo "sync-opencode-theme: missing $scheme_file" >&2; exit 1; }
[[ -f "$template_file" ]] || { echo "sync-opencode-theme: missing $template_file" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync-opencode-theme: jq is required" >&2; exit 1; }

declare -A colour_map=(
  [primary]=primary
  [on_primary]=onPrimary
  [secondary]=secondary
  [on_secondary]=onSecondary
  [surface]=surface
  [on_surface]=onSurface
  [surface_variant]=surfaceVariant
  [on_surface_variant]=onSurfaceVariant
  [error]=error
  [on_error]=onError
  [outline]=outline
  [outline_variant]=outlineVariant
)

mkdir -p "$output_dir"
tmp_file="$(mktemp "$output_dir/.caelestia.json.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT
cp "$template_file" "$tmp_file"

for token in "${!colour_map[@]}"; do
  colour="$(jq -er --arg key "${colour_map[$token]}" '.colours[$key]' "$scheme_file")"
  [[ "$colour" =~ ^[0-9A-Fa-f]{6}$ ]] || {
    echo "sync-opencode-theme: invalid colour for $token" >&2
    exit 1
  }
  sed -i "s|{{colors\.${token}\.default\.hex}}|#${colour}|g" "$tmp_file"
done

if grep -q '{{colors\.' "$tmp_file"; then
  echo "sync-opencode-theme: unresolved colour token" >&2
  exit 1
fi

jq empty "$tmp_file"
mv "$tmp_file" "$output_file"
trap - EXIT
