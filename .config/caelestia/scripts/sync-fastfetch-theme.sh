#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="$HOME/.local/state/caelestia/scheme.json"
readonly template_file="$HOME/.config/fastfetch/nyxniri-template.jsonc"
readonly output_file="$HOME/.config/fastfetch/config.jsonc"

[[ -f "$scheme_file" && -f "$template_file" ]] || exit 0

colour() {
    jq -r --arg name "$1" '.colours[$name] // empty' "$scheme_file"
}

sgr() {
    local hex="${1#\#}"
    printf '\\\\u001b[38;2;%d;%d;%dm' \
        "$((16#${hex:0:2}))" \
        "$((16#${hex:2:2}))" \
        "$((16#${hex:4:2}))"
}

primary="#$(colour primary)"
secondary="#$(colour secondary)"
tertiary="#$(colour tertiary)"
primary_dim="#$(colour primaryFixedDim)"
secondary_dim="#$(colour secondaryFixedDim)"
tertiary_dim="#$(colour tertiaryFixedDim)"
text="#$(colour onSurface)"

for value in "$primary" "$secondary" "$tertiary" "$primary_dim" "$secondary_dim" "$tertiary_dim" "$text"; do
    [[ "$value" =~ ^#[0-9a-fA-F]{6}$ ]] || exit 1
done

sed \
    -e "s|__PRIMARY__|$primary|g" \
    -e "s|__SECONDARY__|$secondary|g" \
    -e "s|__TERTIARY__|$tertiary|g" \
    -e "s|__TEXT__|$text|g" \
    -e "s|__C1__|$(sgr "$primary")|g" \
    -e "s|__C2__|$(sgr "$secondary")|g" \
    -e "s|__C3__|$(sgr "$tertiary")|g" \
    -e "s|__C4__|$(sgr "$primary_dim")|g" \
    -e "s|__C5__|$(sgr "$secondary_dim")|g" \
    -e "s|__C6__|$(sgr "$tertiary_dim")|g" \
    "$template_file" > "$output_file.tmp"

mv "$output_file.tmp" "$output_file"
rm -rf "$HOME/.cache/fastfetch/images"
