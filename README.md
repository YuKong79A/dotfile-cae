# dotfile-cae

Backup of my Caelestia theme templates and Hyprland configuration.

## Contents

- `.config/caelestia/`: Caelestia settings, theme templates, synchronization scripts, and Hyprland user overrides.
- `.config/hypr/`: Lua-based Hyprland configuration and generated colour-scheme integration.
- `.local/bin/`: Personal Caelestia wallpaper and terminal helper scripts.
- `.local/share/icons/Papirus-caelestia-dark/`: Custom Caelestia-generated Papirus icon theme.

## Restore

Clone the repository, then copy the backed-up configuration into the home directory:

```bash
cp -a .config/caelestia ~/.config/
cp -a .config/hypr ~/.config/
mkdir -p ~/.local/bin
cp -a .local/bin/. ~/.local/bin/
mkdir -p ~/.local/share/icons
cp -a .local/share/icons/Papirus-caelestia-dark ~/.local/share/icons/
gtk-update-icon-cache -f ~/.local/share/icons/Papirus-caelestia-dark
```

Review paths and installed dependencies before starting Hyprland. The theme synchronization scripts expect tools and applications referenced by the scripts to be installed.
