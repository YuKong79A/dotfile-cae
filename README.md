# dotfile-cae

Backup of my Caelestia theme templates and Hyprland configuration.

## Contents

- `.config/caelestia/`: Caelestia settings, theme templates, synchronization scripts, and Hyprland user overrides.
- `.face`: User avatar used by greeters and desktop account interfaces.
- `.config/fish/functions/`: Selected personal Fastfetch wallpaper helper functions.
- `.config/fastfetch/`: Fastfetch layout and Caelestia colour-template configuration.
- `.config/hypr/`: Lua-based Hyprland configuration and generated colour-scheme integration.
- `.config/starship.toml`: Starship prompt configuration generated from the Caelestia theme template.
- `.config/xdg-terminals.list`: Preferred XDG terminal order, with the Caelestia-aware Foot launcher first.
- `.config/yazi/`: Yazi theme selection and the rendered Caelestia flavor.
- `.local/bin/`: Personal Caelestia wallpaper and terminal helper scripts.
- `.local/share/applications/foot-caelestia.desktop`: Desktop entry for launching Foot with an interactive Fish environment.
- `.local/share/icons/Papirus-caelestia-dark/`: Custom Caelestia-generated Papirus icon theme.
- `docs/backup-conversation-2026-08-09.md`: Sanitized user-visible transcript of the backup session.
- `docs/restore-with-codex-prompt.md`: Reusable Chinese prompt for restoring this backup with Codex after reinstalling.

## Restore

Clone the repository, then copy the backed-up configuration into the home directory:

```bash
cp -a .face ~/.face
cp -a .config/caelestia ~/.config/
mkdir -p ~/.config/fish/functions
cp -a .config/fish/functions/. ~/.config/fish/functions/
cp -a .config/fastfetch ~/.config/
cp -a .config/hypr ~/.config/
cp -a .config/starship.toml ~/.config/
cp -a .config/xdg-terminals.list ~/.config/
cp -a .config/yazi ~/.config/
mkdir -p ~/.local/bin
cp -a .local/bin/. ~/.local/bin/
mkdir -p ~/.local/share/applications
cp -a .local/share/applications/foot-caelestia.desktop ~/.local/share/applications/
mkdir -p ~/.local/share/icons
cp -a .local/share/icons/Papirus-caelestia-dark ~/.local/share/icons/
gtk-update-icon-cache -f ~/.local/share/icons/Papirus-caelestia-dark
```

Review paths and installed dependencies before starting Hyprland. The theme synchronization scripts expect tools and applications referenced by the scripts to be installed.

### Caelestia application themes

The Caelestia post-hook also renders application themes from the current
`~/.local/state/caelestia/scheme.json` palette:

- **Codex CLI**: renders `~/.codex/themes/caelestia.tmTheme`. After the first
  restore, start Codex, run `/theme`, and select `Caelestia` once.
- **LibreOffice**: builds and installs a `Caelestia` ColorScheme extension for
  native and Flatpak installations. In LibreOffice, select it once under
  Tools > Options > LibreOffice > Application Colors. LibreOffice must be
  closed while the synchronization script installs an updated extension.

These integrations require `python3`, `jq`, `bsdtar`, and LibreOffice's
`unopkg` for a native LibreOffice installation. Generated themes and extension
caches are deliberately excluded from the backup; the post-hook recreates them.

The `Exec` line in `foot-caelestia.desktop` currently uses `/home/yukong`. Update it after restoring if the new account has a different home directory.
