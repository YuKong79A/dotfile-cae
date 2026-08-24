# dotfile-cae

This repository backs up YuKong's CachyOS/Arch Linux desktop configuration for Hyprland and Caelestia.

This document is written primarily for Codex. If the user provides only this repository URL after reinstalling the system, read this file in full, inspect the actual state of the new system, and only then begin restoration. Treat the repository as the configuration source, but do not assume that packages, system services, the username, mount layout, or hardware are identical to the source machine.

## Codex Restoration Task

The goal is to restore the user-level configuration stored in this repository into the current user's home directory while preserving files on the new system that are outside the repository.

The following rules are mandatory:

1. Do not delete, empty, or reset the entire home directory.
2. Do not use `git reset --hard`, `git clean`, or recursive deletion as a restoration method.
3. Inspect the username, `$HOME`, distribution, current desktop, repository contents, and installed dependencies first.
4. Before overwriting any existing configuration, back up conflicting paths to a timestamped directory and report its location to the user.
5. Restore only files actually tracked by the repository. Do not modify unrelated files that are absent from the repository.
6. Treat `/etc`, `/boot`, PAM, display managers, Btrfs, Snapper, and package installation as separate system-level work. Inspect and handle them independently; never infer that they were restored from user-level files.
7. Explain the intended action and obtain user approval before using root privileges, installing packages, or changing service state.
8. Run the validation described in this document after restoration. A successful copy command alone does not prove that the desktop is restored.

## Current Backup Scope

The repository currently includes:

- `.codex/skills/restore-dotfile-cae/`: a Codex restoration skill with a safety-focused workflow and a tracked-file restore helper that defaults to read-only mode and applies changes only after confirmation.
- `.config/caelestia/`: Caelestia CLI and Shell configuration, theme templates, synchronization scripts, monitor configuration, and Hyprland user overrides.
- `.config/hypr/`: Lua-based Hyprland configuration, window rules, key bindings, and the currently generated color scheme.
- `.config/foot/foot.ini`: Foot as the default terminal, Fish as the shell, JetBrains Mono Nerd Font, and dark-background opacity set to `0.78`.
- `.config/fish/`: the active Fish startup configuration, Fish greeting, fzf.fish plugin files and bindings, `clean-cache`, package-update aliases, and wallpaper/Fastfetch helper functions.
- `.config/fastfetch/`, `.config/starship.toml`, and `.config/yazi/`: configuration and themes integrated with Caelestia.
- `.config/opencode/tui.json`: selects the generated `caelestia` OpenCode theme. The source template and renderer live under `.config/caelestia/`; the generated `~/.config/opencode/themes/caelestia.json` is intentionally not tracked.
- `.config/xdg-terminals.list`: XDG terminal preference order.
- `.local/bin/`: personal wallpaper, terminal, and transparency helper scripts, plus the `pac`, `pacr`, and `pacrrr` interactive package-management tools.
- `.local/share/applications/foot-caelestia.desktop`: the Caelestia-aware Foot desktop entry.
- `.local/share/icons/Papirus-caelestia-dark/`: the Papirus icon theme generated from the current Caelestia color scheme.
- `.face`: the user's profile image.

The repository does not include a complete package manifest, private keys or tokens, browser profiles, game data, unrelated Fish plugins, Kitty configuration, the Google Sans Flex installer, or system-level configuration. Do not claim that these items can be restored from this repository.

## Codex Skill

The repository includes `.codex/skills/restore-dotfile-cae/`. Codex will discover it from the default skill directory after a complete restoration. Alternatively, after reinstalling the system, ask Codex to install the skill directly from:

`https://github.com/YuKong79A/dotfile-cae/tree/main/.codex/skills/restore-dotfile-cae`

Then invoke `$restore-dotfile-cae`. The skill must first perform a read-only preflight and report conflicting paths, the backup directory, missing dependencies, and proposed system-level operations. It may copy files or perform installation or privileged actions only after the user confirms the plan.

## Recommended Restoration Workflow

The commands below are workflow references. Codex must adapt variables to the actual username and home path, execute them in stages, and inspect the results instead of pasting the entire sequence blindly.

### 1. Inspect the environment

```bash
id
printf '%s\n' "$HOME"
uname -a
command -v git
command -v caelestia
command -v hyprctl
```

The expected target account is usually `yukong`, with `/home/yukong` as its home directory. If either value differs, inspect absolute paths in the repository and make only targeted replacements. Do not copy `/home/yukong` paths blindly.

### 2. Clone into a temporary directory, not over the home directory

```bash
restore_root=$(mktemp -d /tmp/dotfile-cae-restore.XXXXXX)
git clone https://github.com/YuKong79A/dotfile-cae.git "$restore_root/repo"
git -C "$restore_root/repo" status --short --branch
```

Read the following before continuing:

```bash
sed -n '1,260p' "$restore_root/repo/README.md"
git -C "$restore_root/repo" ls-files
```

### 3. Back up existing conflicting files

Create a backup directory dedicated to this restoration, then back up only paths that the repository will write and that already exist on the target. Do not back up the entire home directory or move unrelated files.

```bash
backup_root="$HOME/dotfile-restore-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_root"
```

Codex must derive a conflict list from `git ls-files`, preserve relative paths, permissions, and symbolic links, and report the list before copying. Do not delete the backup until restoration has been fully validated.

### 4. Copy only tracked repository content

Copy from the repository's tracked-file list instead of copying the temporary clone's `.git` directory. From the temporary clone, use:

```bash
git -C "$restore_root/repo" ls-files -z | \
  tar -C "$restore_root/repo" --null -T - -cf - | \
  tar -C "$HOME" -xpf -
```

After copying, confirm that key files exist, verify that they belong to the current user, and search for stale absolute paths from the source home:

```bash
stat -c '%U:%G %a %n' \
  "$HOME/.config/caelestia/cli.json" \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/foot/foot.ini"
rg -n '/home/yukong' \
  "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" 2>/dev/null
```

If the restored account is still `yukong`, a `/home/yukong` match is not necessarily an error; inspect each match. If the account differs, modify only paths that genuinely depend on the old home directory.

### 5. Connect the home directory as this repository's worktree

Create Git metadata only after files have been copied and inspected. The following mixed reset establishes the remote index baseline without overwriting worktree files:

```bash
git -C "$HOME" init -b main
git -C "$HOME" remote add origin https://github.com/YuKong79A/dotfile-cae.git
git -C "$HOME" fetch origin main
git -C "$HOME" reset --mixed origin/main
git -C "$HOME" branch --set-upstream-to=origin/main main
```

To prevent the home-root repository from exposing every unrelated untracked file, append this rule to the local `$HOME/.git/info/exclude` file:

```gitignore
# Ignore every untracked home path. Existing tracked files remain managed.
/*
```

This is a machine-local rule and is not uploaded to GitHub. Verify that `git status` reports only genuine differences in tracked configuration and does not expose the entire home directory, games, secrets, or personal data. When adding a configuration path that the repository does not already track, use `git add -f <path>` explicitly.

## Software and Runtime Dependencies

Inspect first and install only what is missing. Repository scripts may require at least:

- Caelestia Shell/CLI and a compatible Hyprland environment
- `fish`, `foot`, `fastfetch`, `starship`, and `yazi`
- `fzf` for Fish fuzzy search and the interactive package scripts
- `jq`, `python`, `perl`, `bash`, and `bsdtar`
- OpenCode for the Caelestia-generated OpenCode TUI theme
- `curl`, `gzip`, `git`, and an AUR helper such as `paru` or `yay` for `pac`
- `strace` for `pacrrr`; Flatpak integration is used by `pacr` when `flatpak` is installed
- `wl-clipboard` and `cliphist`
- `papirus-icon-theme`, a Bibata cursor theme, and JetBrains Mono Nerd Font
- Optional components: LibreOffice, Fcitx5, Cava, Bat, Codex CLI, and `arch-update`

On Arch or CachyOS, query installed packages and use `pacman -Si` or `paru -Si` to confirm package names before installation. Do not install guessed package names from this README without checking them, and do not assume that an AUR helper is available.

Caelestia theme synchronization depends on `~/.local/state/caelestia/scheme.json`. This state file is normally generated by Caelestia and is not tracked by the repository. Start Caelestia and generate a color scheme normally before running synchronization scripts; do not fabricate the state file.

After the scheme exists, generate the untracked OpenCode theme before starting OpenCode:

```bash
bash "$HOME/.config/caelestia/scripts/sync-opencode-theme.sh"
```

Both the Caelestia theme and wallpaper post-hooks rerun this script. The generated file remains untracked so ordinary wallpaper changes do not create Git noise.

The current theme and wallpaper post-hooks in `cli.json` invoke:

```bash
sudo -n astra-airlock --sync
```

This step may fail if Airlock is not installed or its narrowly scoped sync command is not authorized on the new system. Inspect Airlock, sudoers, greetd, and the active display-manager configuration first. Do not broaden sudo permissions merely to suppress the error.

## Current Desktop Behavior

- Caelestia uses a 12-hour clock and the weather location `Tangshan, China`.
- Foot is the preferred terminal and runs Fish; dark-background opacity is `0.78`.
- Fish starts Fastfetch without the extra Caelestia ASCII banner. `fa` runs Fastfetch, `clean` runs the interactive cache cleaner, and `up`/`update` selects Paru, Yay, Shelly, or Pacman for a full system update.
- fzf.fish provides `Ctrl+Alt+F` for files/directories, `Ctrl+Alt+L` for Git log, `Ctrl+Alt+S` for Git status, and `Ctrl+R` for command history.
- `pac` searches and installs repository/AUR packages, `pacr` interactively removes native or Flatpak packages, and `pacrrr` traces an application with `strace` before offering residual files for removal. Review every selection before confirming removal.
- OpenCode uses the `caelestia` TUI theme generated from the current Caelestia Material palette. Its main background is `none`, so it inherits Foot's background and transparency; panels retain Caelestia surface colours. Restart a running OpenCode TUI after the palette changes.
- Do not add `GTK_IM_MODULE=fcitx` back to `user-config.fish`. Keep the Qt, XMODIFIERS, and SDL Fcitx settings under Wayland.
- `hypr-user.lua` starts `arch-update --tray` and the clipboard-history script.
- Clipboard history may contain sensitive information. Use `cliphist wipe` when necessary.
- Treat the repository's Lua files as authoritative for Hyprland special workspaces, window rules, and key bindings, then validate them against the installed Hyprland version.
- Regenerating the Caelestia color scheme may legitimately produce many color changes in Papirus, Fastfetch, Starship, Yazi, and the Hyprland scheme.

## Post-Restoration Validation

Run static checks first:

```bash
jq empty \
  "$HOME/.config/caelestia/cli.json" \
  "$HOME/.config/caelestia/shell.json" \
  "$HOME/.config/caelestia/templates/opencode.json" \
  "$HOME/.config/opencode/tui.json"
luac -p "$HOME/.config/caelestia/hypr-user.lua"
bash -n "$HOME/.config/caelestia/scripts/copy.sh"
bash -n "$HOME/.config/caelestia/posthooks/cursor.sh"
bash -n "$HOME/.config/caelestia/scripts/sync-libreoffice-theme.sh"
bash -n "$HOME/.config/caelestia/scripts/sync-opencode-theme.sh"
fish -n "$HOME/.config/caelestia/user-config.fish"
fish -n "$HOME/.config/fish/config.fish" \
  "$HOME/.config/fish/conf.d/fzf.fish" \
  "$HOME/.config/fish/functions/fish_greeting.fish"
bash -n "$HOME/.config/fish/clean-cache" \
  "$HOME/.local/bin/pac" \
  "$HOME/.local/bin/pacr" \
  "$HOME/.local/bin/pacrrr"
bash "$HOME/.config/caelestia/scripts/sync-opencode-theme.sh"
jq empty "$HOME/.config/opencode/themes/caelestia.json"
```

Then validate inside a real graphical session:

```bash
hyprctl reload
hyprctl configerrors
```

Reopen Foot, Caelestia, Yazi, and other relevant applications to check fonts, icons, transparency, input methods, special workspaces, and theme synchronization. In Fish, verify `type fa clean up pac pacr pacrrr` and inspect the fzf bindings with `bind ctrl-alt-f`, `bind ctrl-alt-l`, `bind ctrl-alt-s`, and `bind ctrl-r`. Persistent-file checks cannot substitute for visual and session validation after an actual login or restart.

Finally, inspect the Git scope:

```bash
git -C "$HOME" status --short --branch
git -C "$HOME" check-ignore -v .config/fish/functions/fisher.fish 2>/dev/null || true
```

If validation fails, retain the conflict backup and report the exact failure and validation layer. Do not delete existing user configuration merely to force a clean state.

## Future Backups

The repository currently uses an HTTPS remote. This machine can use `git-credential-libsecret` to store a GitHub Personal Access Token in the desktop keyring.

For routine updates, inspect changes first and stage only reviewed paths:

```bash
git -C "$HOME" status --short
git -C "$HOME" diff --name-status
git -C "$HOME" add -- README.md  # Example: stage only a reviewed path.
git -C "$HOME" diff --cached --name-status
git -C "$HOME" commit -m "Update desktop configuration"
git -C "$HOME" push origin main
```

Do not use a blanket `git add -u` without first classifying deletions, especially repository-only README or Markdown documentation. For a new path that is absent from the repository but has been explicitly approved for backup, use:

```bash
git -C "$HOME" add -f .config/example
```

Before committing, inspect the staged content and ensure it does not include tokens, passwords, SSH private keys, browser data, clipboard databases, game saves, or other private files.
