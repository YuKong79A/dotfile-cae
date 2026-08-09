#!/usr/bin/env bash
set -euo pipefail

icons_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
source_theme="${CAELESTIA_PAPIRUS_SOURCE:-/usr/share/icons/Papirus-Dark}"
theme_name="${CAELESTIA_ICON_THEME:-Papirus-caelestia-dark}"
theme_dir="$icons_dir/$theme_name"
stamp_file="$theme_dir/.caelestia-accent"
template_version="6"
version_file="$theme_dir/.caelestia-template-version"

# Prefer the colour supplied by Caelestia's post-hook. Fall back to generated GTK CSS.
accent=""
accent_fg=""
if [[ -n "${SCHEME_COLOURS:-}" ]] && command -v jq >/dev/null 2>&1; then
  accent="$(jq -r '.primary // empty' <<<"$SCHEME_COLOURS")"
  accent_fg="$(jq -r '.onPrimary // empty' <<<"$SCHEME_COLOURS")"
fi

for css in "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"; do
  if [[ ! "$accent" =~ ^#?[0-9A-Fa-f]{6}$ ]] && [[ -r "$css" ]]; then
    accent="$(sed -nE 's/^@define-color[[:space:]]+accent_color[[:space:]]+(#[0-9A-Fa-f]{6});/\1/p' "$css" | head -n 1)"
    accent_fg="$(sed -nE 's/^@define-color[[:space:]]+accent_fg_color[[:space:]]+(#[0-9A-Fa-f]{6});/\1/p' "$css" | head -n 1)"
  fi
done

[[ "$accent" == \#* ]] || accent="#$accent"
[[ "$accent_fg" == \#* ]] || accent_fg="#$accent_fg"
if [[ ! "$accent" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "sync-papirus-icons: no valid Caelestia accent colour found" >&2
  exit 1
fi
[[ "$accent_fg" =~ ^#[0-9A-Fa-f]{6}$ ]] || accent_fg="#ffffff"
[[ -d "$source_theme" ]] || { echo "sync-papirus-icons: missing $source_theme" >&2; exit 1; }

dark_accent="$(ACCENT="$accent" perl -e '
  (my $hex = $ENV{ACCENT}) =~ s/^#//;
  my @rgb = map { hex($_) } ($hex =~ /(..)(..)(..)/);
  printf "#%02x%02x%02x\n", map { int($_ * 0.78 + 0.5) } @rgb;
')"

if [[ -r "$stamp_file" && -r "$version_file" ]] \
  && [[ "$(<"$stamp_file")" == "$accent" ]] \
  && [[ "$(<"$version_file")" == "$template_version" ]]; then
  exit 0
fi

rm -rf -- "$theme_dir"
mkdir -p "$theme_dir"
printf '%s\n' \
  '[Icon Theme]' \
  'Name=Papirus Caelestia Dark' \
  'Comment=Papirus-Dark folder icons coloured by Caelestia' \
  'Inherits=Papirus-Dark,breeze-dark,hicolor' \
  'Example=folder' \
  'FollowsColorScheme=true' \
  '' > "$theme_dir/index.theme"

icon_names=(
  desktop.svg folder.svg folder-blue.svg folder-blue-open.svg folder-home.svg
  folder-desktop.svg folder-documents.svg folder-download.svg folder-music.svg
  folder-open.svg folder-pictures.svg folder-projects.svg folder-publicshare.svg
  folder-templates.svg folder-video.svg folder-videos.svg folder-videos-open.svg
  user-desktop.svg user-home.svg user-home-open.svg
)
find_expr=()
for name in "${icon_names[@]}"; do
  ((${#find_expr[@]} == 0)) || find_expr+=(-o)
  find_expr+=(-name "$name")
done

directories=()
while IFS= read -r -d '' file; do
  rel="${file#"$source_theme"/}"
  rel_dir="${rel%/*}"
  mkdir -p "$theme_dir/$rel_dir"
  cp -L "$file" "$theme_dir/$rel"
  directories+=("$rel_dir")
done < <(find -L "$source_theme" -type f -path '*/places/*' \( "${find_expr[@]}" \) -print0)
mapfile -t directories < <(printf '%s\n' "${directories[@]}" | sort -u)

if ((${#directories[@]})); then
  joined="$(IFS=,; printf '%s' "${directories[*]}")"
  printf 'Directories=%s\n\n' "$joined" >> "$theme_dir/index.theme"
fi
for rel in "${directories[@]}"; do
  size="${rel%%x*}"
  [[ "$size" =~ ^[0-9]+$ ]] && printf '[%s]\nContext=Places\nSize=%s\nType=Fixed\n\n' "$rel" "$size" >> "$theme_dir/index.theme"
done

while IFS= read -r -d '' file; do
  ACCENT="$accent" ACCENT_FG="$accent_fg" DARK_ACCENT="$dark_accent" perl -0pi -e '
    s/#(?:5294e2|4285f4|a9cae8)/$ENV{ACCENT}/gi;
    s/#(?:4877b1|849eb5)/$ENV{DARK_ACCENT}/gi;
    s/#1d344f/$ENV{ACCENT_FG}/gi;
    s/(\.ColorScheme-Highlight\s*\{[^}]*?color:)#[0-9A-Fa-f]{6}/$1$ENV{ACCENT}/g;
  ' "$file"
done < <(find "$theme_dir" -type f -name '*.svg' -print0)

printf '%s\n' "$template_version" > "$version_file"
printf '%s\n' "$accent" > "$stamp_file"
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -q "$theme_dir" || true

for gtk_dir in "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"; do
  mkdir -p "$gtk_dir"
  settings="$gtk_dir/settings.ini"
  if [[ -f "$settings" ]] && grep -q '^gtk-icon-theme-name=' "$settings"; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$theme_name/" "$settings"
  elif [[ -f "$settings" ]]; then
    printf '\ngtk-icon-theme-name=%s\n' "$theme_name" >> "$settings"
  else
    printf '[Settings]\ngtk-icon-theme-name=%s\n' "$theme_name" > "$settings"
  fi
done
command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface icon-theme "$theme_name" >/dev/null 2>&1 || true
