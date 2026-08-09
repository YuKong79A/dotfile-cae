# dotfile-cae

Backup of my Caelestia theme templates and Hyprland configuration.

## Contents

- `.config/caelestia/`: Caelestia settings, theme templates, synchronization scripts, and Hyprland user overrides.
- `.config/fish/functions/`: Selected personal Fastfetch wallpaper helper functions.
- `.config/hypr/`: Lua-based Hyprland configuration and generated colour-scheme integration.
- `.config/xdg-terminals.list`: Preferred XDG terminal order, with the Caelestia-aware Foot launcher first.
- `.local/bin/`: Personal Caelestia wallpaper and terminal helper scripts.
- `.local/share/applications/foot-caelestia.desktop`: Desktop entry for launching Foot with an interactive Fish environment.
- `.local/share/icons/Papirus-caelestia-dark/`: Custom Caelestia-generated Papirus icon theme.

## Restore

Clone the repository, then copy the backed-up configuration into the home directory:

```bash
cp -a .config/caelestia ~/.config/
mkdir -p ~/.config/fish/functions
cp -a .config/fish/functions/. ~/.config/fish/functions/
cp -a .config/hypr ~/.config/
cp -a .config/xdg-terminals.list ~/.config/
mkdir -p ~/.local/bin
cp -a .local/bin/. ~/.local/bin/
mkdir -p ~/.local/share/applications
cp -a .local/share/applications/foot-caelestia.desktop ~/.local/share/applications/
mkdir -p ~/.local/share/icons
cp -a .local/share/icons/Papirus-caelestia-dark ~/.local/share/icons/
gtk-update-icon-cache -f ~/.local/share/icons/Papirus-caelestia-dark
```

Review paths and installed dependencies before starting Hyprland. The theme synchronization scripts expect tools and applications referenced by the scripts to be installed.

The `Exec` line in `foot-caelestia.desktop` currently uses `/home/yukong`. Update it after restoring if the new account has a different home directory.
