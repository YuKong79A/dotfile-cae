# Optional Hardware dashboard tab

This opt-in component adds a Hardware tab to a **local copy** of Midnight Shell.
It shows two fan speeds and provides OMEN fan modes, Eco/Daily/Gaming presets,
keyboard backlight On/Off, and a Refresh button. Presets coordinate OMEN power
profiles with the `lavd` SCX scheduler. The script reads current hardware state
every 12 seconds, so external changes also appear in the tab.

It is specific to the HP OMEN hardware and services used on the source machine.
The regular tracked-file restore only copies `optional/hardware/` into the home
directory; it does not install the tab or alter Midnight Shell. The installer
needs `omen-cli` (OMEN Space), `scxctl`, `busctl`, and a working local Midnight
Shell copy at `~/.config/quickshell/caelestia`. Ensure the OMEN service and SCX
loader are running. The installer does not add system packages, services, or
Polkit rules. SCX profile switching must already be authorized for the user.

## Install

After installing Midnight Shell and making or restoring its local copy:

```bash
python3 "$HOME/optional/hardware/install.py"
caelestia shell -r -d
"$HOME/.local/bin/caelestia-hardware" status
```

The installer adds two marked blocks to the local `Content.qml`, copies the
Hardware page and helper, and stores replaced files under
`~/.local/state/caelestia-hardware/backups/`. It is safe to run again; unchanged
files are left alone. It does not modify `/etc/xdg/quickshell/caelestia` or
other dashboard tabs. Check the Hardware page after the Shell reload.

## After Midnight Shell updates

Package updates change `/etc/xdg/quickshell/caelestia`, while an existing local
copy takes precedence. Merge the updated Shell into the local copy, preserving
other customizations such as Notes, then run the installer again. It will
reapply the Hardware tab and will stop if the updated dashboard structure has
no recognizable insertion point. Review the new `Content.qml` in that case.

## Remove

```bash
python3 "$HOME/optional/hardware/install.py" --uninstall
caelestia shell -r -d
```

Removal deletes the marked integration and removes the page/helper only when
they still match this repository's copies. Locally edited page/helper files
are preserved and reported. The installer never changes power, fan, or light
settings during installation or removal.
