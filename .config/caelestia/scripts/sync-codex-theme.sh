#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_file="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates/codex.tmTheme"
readonly themes_dir="${CODEX_HOME:-$HOME/.codex}/themes"
readonly output_file="$themes_dir/caelestia.tmTheme"

[[ -f "$scheme_file" ]] || { echo "sync-codex-theme: missing $scheme_file" >&2; exit 1; }
[[ -f "$template_file" ]] || { echo "sync-codex-theme: missing $template_file" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "sync-codex-theme: python3 is required" >&2; exit 1; }

mkdir -p "$themes_dir"
tmp_file="$(mktemp "${output_file}.tmp.XXXXXX")"
trap 'rm -f -- "$tmp_file"' EXIT

python3 - "$scheme_file" "$template_file" "$tmp_file" <<'PY'
import json
import re
import sys

scheme_path, template_path, output_path = sys.argv[1:]
with open(scheme_path, encoding="utf-8") as handle:
    colours = json.load(handle)["colours"]
with open(template_path, encoding="utf-8") as handle:
    template = handle.read()

names = {
    "error": "error",
    "error_container": "errorContainer",
    "on_error_container": "onErrorContainer",
    "on_secondary_container": "onSecondaryContainer",
    "on_surface": "onSurface",
    "on_surface_variant": "onSurfaceVariant",
    "on_tertiary_container": "onTertiaryContainer",
    "outline": "outline",
    "outline_variant": "outlineVariant",
    "primary": "primary",
    "secondary": "secondary",
    "secondary_container": "secondaryContainer",
    "surface": "surface",
    "surface_container_high": "surfaceContainerHigh",
    "surface_container_low": "surfaceContainerLow",
    "surface_variant": "surfaceVariant",
    "tertiary": "tertiary",
    "tertiary_container": "tertiaryContainer",
}

token_pattern = re.compile(
    r"\{\{colors\.([a-z_]+)\.default\.hex(?:\s*\|\s*set_alpha\s+([0-9.]+))?\}\}"
)

def replace(match):
    source_name = names.get(match.group(1))
    if source_name is None or source_name not in colours:
        raise SystemExit(f"sync-codex-theme: no Caelestia mapping for {match.group(1)}")
    value = "#" + colours[source_name].lstrip("#")
    if match.group(2) is not None:
        alpha = max(0, min(255, round(float(match.group(2)) * 255)))
        value += f"{alpha:02x}"
    return value

rendered = token_pattern.sub(replace, template)
if "{{colors." in rendered:
    raise SystemExit("sync-codex-theme: unresolved colour token")
with open(output_path, "w", encoding="utf-8") as handle:
    handle.write(rendered)
PY

if [[ -f "$output_file" ]] && cmp -s "$output_file" "$tmp_file"; then
  exit 0
fi
install -m 0600 "$tmp_file" "$output_file"
