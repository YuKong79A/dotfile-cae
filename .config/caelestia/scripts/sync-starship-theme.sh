#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_file="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates/nyxniri-starship.toml"
readonly output_file="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

[[ -f "$scheme_file" && -f "$template_file" ]] || exit 0

colour() {
    local value
    value="$(jq -r --arg name "$1" '.colours[$name] // empty' "$scheme_file")"
    [[ "$value" =~ ^[0-9a-fA-F]{6}$ ]] || return 1
    printf '#%s' "$value"
}

sed \
    -e "s|__BLUE__|$(colour primary)|g" \
    -e "s|__RED__|$(colour error)|g" \
    -e "s|__GREEN__|$(colour primary)|g" \
    -e "s|__YELLOW__|$(colour tertiary)|g" \
    -e "s|__CYAN__|$(colour primaryFixedDim)|g" \
    -e "s|__MAGENTA__|$(colour secondaryFixedDim)|g" \
    -e "s|__WHITE__|$(colour onSurface)|g" \
    -e "s|__BLACK__|$(colour onPrimary)|g" \
    "$template_file" > "$output_file.tmp"

mv "$output_file.tmp" "$output_file"
