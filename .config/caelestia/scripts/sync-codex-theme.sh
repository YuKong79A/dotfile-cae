#!/usr/bin/env bash

set -euo pipefail

readonly theme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/theme/codex.tmTheme"
readonly themes_dir="${CODEX_HOME:-$HOME/.codex}/themes"
readonly output_file="$themes_dir/caelestia.tmTheme"

[[ -f "$theme_file" ]] || { echo "sync-codex-theme: missing Caelestia-rendered $theme_file" >&2; exit 1; }
if grep -q '{{' "$theme_file"; then
  echo "sync-codex-theme: unresolved template variable in $theme_file" >&2
  exit 1
fi

mkdir -p "$themes_dir"
if [[ "$(readlink -- "$output_file" 2>/dev/null || true)" == "$theme_file" ]]; then
  exit 0
fi

# Keep the stable Codex theme path pointed at the file Caelestia updates.
ln -sfn -- "$theme_file" "$output_file"
