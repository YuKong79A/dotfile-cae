#!/bin/bash

cursor_light="Bibata-Modern-Ice"
cursor_dark="Bibata-Modern-Classic"
cursor_size="24"

if [[ "$SCHEME_MODE" == "dark" ]]; then
    target_cursor="$cursor_dark"
else
    target_cursor="$cursor_light"
fi

echo "Setting $SCHEME_MODE cursor: $target_cursor"

hyprctl setcursor "$target_cursor" "$cursor_size"
gsettings set org.gnome.desktop.interface cursor-theme "$target_cursor"
gsettings set org.gnome.desktop.interface cursor-size "$cursor_size"

echo "Successfully set cursor to $SCHEME_MODE"
