# Wormhole portal

`~/.config/xdg-desktop-portal/portals.conf` selects Wormhole as the default
desktop portal. Hyprland still handles GlobalShortcuts and InputCapture, while
GNOME Keyring handles Secret. The file falls back to Hyprland and GTK when
Wormhole is unavailable.

The portal binary is installed as a system package and is not in the dotfiles
backup. On an Arch/CachyOS restore, inspect the pinned commit and dependencies
in `PKGBUILD`, then run `makepkg -si` from this directory. The package includes
the D-Bus service and user systemd unit. Restart the user portal after install:

```sh
systemctl --user restart xdg-desktop-portal.service
```

The pinned source revision embeds its own FileChooser, so the README's older
Atlas runtime requirement does not apply to this revision. Recheck this when
updating the source commit.

The local `folder-icon.patch` makes ordinary directories request the theme's
`folder` icon. Without it, Wormhole requests `inode-directory`, which resolves
to an outline icon instead of the Caelestia-coloured folder used elsewhere.

Validate with `systemctl --user status xdg-desktop-portal-wormhole.service`
after a portal request. A file chooser request should create a window with
class `wormhole`.
