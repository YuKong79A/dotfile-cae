#!/usr/bin/env bash

set -euo pipefail

readonly scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
readonly template_file="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/templates/libreoffice-theme.xcu"
readonly state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/libreoffice-theme"
readonly stamp_file="$state_dir/installed-scheme.sha256"
readonly extension_id="dev.caelestia.libreoffice.theme"

[[ -f "$scheme_file" ]] || { echo "sync-libreoffice-theme: missing $scheme_file" >&2; exit 1; }
[[ -f "$template_file" ]] || { echo "sync-libreoffice-theme: missing $template_file" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "sync-libreoffice-theme: jq is required" >&2; exit 1; }
command -v bsdtar >/dev/null 2>&1 || { echo "sync-libreoffice-theme: bsdtar is required" >&2; exit 1; }

scheme_hash="$(sha256sum "$scheme_file" | cut -d' ' -f1)"
[[ -r "$stamp_file" && "$(<"$stamp_file")" == "$scheme_hash" ]] && exit 0

if pgrep -x soffice.bin >/dev/null 2>&1; then
  echo "sync-libreoffice-theme: LibreOffice is running; close it and reapply the Caelestia theme" >&2
  exit 0
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/caelestia-libreoffice.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
mkdir -p "$work_dir/pkg/META-INF"
cp "$template_file" "$work_dir/Theme_Colors.hex.xcu"

for token in surface onSurface surfaceContainerHigh primary outlineVariant onSurfaceVariant surfaceContainer onPrimary outline; do
  colour="$(jq -er --arg key "$token" '.colours[$key]' "$scheme_file")"
  [[ "$colour" =~ ^[0-9A-Fa-f]{6}$ ]] || { echo "sync-libreoffice-theme: invalid $token colour" >&2; exit 1; }
  sed -i "s/{{${token}}}/${colour}/g" "$work_dir/Theme_Colors.hex.xcu"
done
grep -q '{{' "$work_dir/Theme_Colors.hex.xcu" && { echo "sync-libreoffice-theme: unresolved colour token" >&2; exit 1; }

perl -0pe 's{<value>([0-9A-Fa-f]{6})</value>}{"<value>" . hex($1) . "</value>"}ge' \
  "$work_dir/Theme_Colors.hex.xcu" > "$work_dir/pkg/Theme_Colors.xcu"

printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<oor:component-data xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" oor:name="Paths" oor:package="org.openoffice.Office">' \
  '  <node oor:name="Paths"><node oor:name="Palette"><node oor:name="InternalPaths"><node oor:name="%origin%/palettes" oor:op="fuse"/></node></node></node>' \
  '</oor:component-data>' > "$work_dir/pkg/Paths.xcu"

printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<manifest:manifest xmlns:manifest="http://openoffice.org/2001/manifest">' \
  '  <manifest:file-entry manifest:full-path="Theme_Colors.xcu" manifest:media-type="application/vnd.sun.star.configuration-data"/>' \
  '  <manifest:file-entry manifest:full-path="Paths.xcu" manifest:media-type="application/vnd.sun.star.configuration-data"/>' \
  '</manifest:manifest>' > "$work_dir/pkg/META-INF/manifest.xml"

printf '%s\n' \
  '<?xml version="1.0" encoding="UTF-8"?>' \
  '<description xmlns="http://openoffice.org/extensions/description/2006" xmlns:xlink="http://www.w3.org/1999/xlink">' \
  "  <identifier value=\"$extension_id\"/>" \
  '  <version value="1.0.0"/>' \
  '  <display-name><name lang="en">Caelestia Theme</name></display-name>' \
  '</description>' > "$work_dir/pkg/description.xml"

bsdtar --format zip -cf "$work_dir/caelestia-theme.oxt" -C "$work_dir/pkg" \
  Theme_Colors.xcu Paths.xcu description.xml META-INF
installed=0
if command -v unopkg >/dev/null 2>&1; then
  unopkg remove "$extension_id" >/dev/null 2>&1 || true
  unopkg add --force "$work_dir/caelestia-theme.oxt" && installed=1
fi
if command -v flatpak >/dev/null 2>&1 && flatpak info org.libreoffice.LibreOffice >/dev/null 2>&1; then
  flatpak run --command=/app/libreoffice/program/unopkg org.libreoffice.LibreOffice remove "$extension_id" >/dev/null 2>&1 || true
  flatpak run --command=/app/libreoffice/program/unopkg org.libreoffice.LibreOffice add --force "$work_dir/caelestia-theme.oxt" && installed=1
fi
((installed)) || { echo "sync-libreoffice-theme: no LibreOffice installation found" >&2; exit 1; }

mkdir -p "$state_dir"
printf '%s\n' "$scheme_hash" > "$stamp_file"
