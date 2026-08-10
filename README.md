# dotfile-cae

Backup of my Caelestia desktop, Hyprland configuration, application themes,
Kitty setup, and personal helper scripts.

## Contents

- `.config/caelestia/`: Caelestia settings, theme templates, synchronization scripts, and Hyprland user overrides.
- `.face`: User avatar used by greeters and desktop account interfaces.
- `.config/fish/functions/`: Selected personal Fastfetch wallpaper helper functions.
- `.config/fastfetch/`: Fastfetch layout and Caelestia colour-template configuration.
- `.config/hypr/`: Lua-based Hyprland configuration and generated colour-scheme integration.
- `.config/kitty/`: Kitty configuration plus the custom split-window search kitten.
- `.config/starship.toml`: Starship prompt configuration generated from the Caelestia theme template.
- `.config/xdg-terminals.list`: Preferred XDG terminal order, with Caelestia-aware Foot first and Kitty as fallback.
- `.config/yazi/`: Yazi theme selection and the rendered Caelestia flavor.
- `.local/bin/`: Personal Caelestia wallpaper and terminal helper scripts.
- `.local/bin/install-google-sans-flex`: Installs the complete Google Sans Flex
  variable font from Google Fonts, including the `ROND` axis used by Caelestia.
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
cp -a .config/kitty ~/.config/
cp -a .config/starship.toml ~/.config/
cp -a .config/xdg-terminals.list ~/.config/
cp -a .config/yazi ~/.config/
mkdir -p ~/.local/bin
cp -a .local/bin/. ~/.local/bin/
~/.local/bin/install-google-sans-flex
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

## Synced desktop features

### Hyprland and special workspaces

- `special:special` uses the scrolling layout.
- `special:communication`, `special:music`, and `special:sysmon` use the
  monocle layout.
- Caelestia toggle groups cover communication, Google web apps, music,
  On-Together, Steam, and todo apps. The local `cnmplayer` group is retained.
- `Super+P` toggles Steam and `Super+O` toggles On-Together.
- `Ctrl+Super+Up/Down` cycles special workspaces.
- `Alt+Tab` and `Shift+Alt+Tab` use monocle-aware layout cycling so windows
  can be switched inside monocle special workspaces.
- Codex is available on `Ctrl+Super+O`.
- Window rules float and centre Zoom, float `Chat`, route Slack/ZapZap and todo
  apps to their special workspaces, and route Thunar to
  `special:communication` as a floating `1200x800` window.
- Caelestia shows custom icons for the Steam, Google, and On-Together special
  workspaces and a gamepad icon for Steam windows.

### Autostart and clipboard history

`~/.config/caelestia/hypr-user.lua` starts:

- `arch-update --tray`
- `scripts/copy.sh`, which records text and image clipboard entries with
  `wl-paste --watch` and `cliphist`

Install the runtime dependencies before logging in:

```bash
sudo pacman -S --needed kitty cliphist wl-clipboard
paru -S --needed arch-update
```

Clipboard history can contain passwords, tokens, and other copied secrets.
Clear it with `cliphist wipe` when needed.

### Cursor and interface font

- Dark mode uses `Bibata-Modern-Classic`; light mode uses
  `Bibata-Modern-Ice`, both at size 24.
- `posthooks/cursor.sh` updates Hyprland and GTK whenever the Caelestia colour
  mode changes. Both Bibata themes must already be installed.
- Caelestia clocks and headlines use Google Sans Flex with headline weight
  500 and `ROND=25`. Run `install-google-sans-flex` during restore.
- The font is downloaded from Google Fonts and is distributed under the SIL
  Open Font License 1.1; the binary is intentionally not stored in this repo.
- The optional `dynamic_cursors` block is guarded by a plugin-existence check.
  `Super+Ctrl+Z` magnification only works after that Hyprland plugin is
  installed and enabled.

### Kitty

Foot is the default terminal for Hyprland, Caelestia, and XDG terminal
launching. Kitty remains available as an alternative and uses Fish, JetBrains Mono Nerd Font at size 12, 85% background opacity,
cursor trail, 21.75px margins, and no close confirmation. `Ctrl+F` opens the
vendored search kitten in a horizontal split. Page Up/Down scroll and
Ctrl+Plus/Minus/0 adjust the font size.

Required fonts and shell:

```bash
sudo pacman -S --needed fish ttf-jetbrains-mono-nerd
```

The Google Sans Flex installer additionally requires `curl`, `coreutils`, and
`fontconfig`. It verifies the pinned Google Fonts v22 file with SHA-256 before
installing it.

### Validation after restore

```bash
jq empty ~/.config/caelestia/cli.json ~/.config/caelestia/shell.json
luac -p ~/.config/caelestia/hypr-user.lua
bash -n ~/.config/caelestia/scripts/copy.sh
bash -n ~/.config/caelestia/posthooks/cursor.sh
python -c 'from pathlib import Path; [compile(p.read_text(), str(p), "exec") for p in (Path.home()/".config/kitty/search.py", Path.home()/".config/kitty/scroll_mark.py")]'
hyprctl reload
hyprctl configerrors
```
