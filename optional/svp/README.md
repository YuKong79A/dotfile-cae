# Optional SVP setup for mpv and Tsukimi

This directory is a snapshot of the user's mpv and Tsukimi playback settings on
an NVIDIA RTX 3060 Laptop GPU. Restoring the main dotfiles repository only puts
these files under `~/optional/svp`; it does not activate SVP or replace either
player's configuration.

The repository contains configuration and launch scripts only. It does not
contain SVP 4, mpv/libmpv binaries, the uosc program and fonts, generated SVP
scripts, SVP profiles, account data, or activation data. Install those from
their own sources. The `nvdec-copy` setting is specific to NVIDIA; use a
working copy-back decoder for different hardware.

## 1. Install the applications and build dependencies

Install Tsukimi, the NVIDIA driver, SVP 4 Linux, and the dependencies needed by
SVP and mpv. On Arch/CachyOS, check current package names before installing;
the source machine used `vapoursynth`, `ffmpeg`, `libplacebo`, `libass`,
`luajit`, `meson`, `ninja`, `pkgconf`, `git`, and `lsof`. See the
[SVP Linux instructions](https://www.svp-team.com/docs/linux/) for current
system and runtime requirements. Install SVP so its manager is executable at
`$HOME/.local/opt/svp4/SVPManager`, or adjust both launch scripts below.

The distribution's mpv package on the source machine lacked the VapourSynth
filter. Build a separate mpv and shared libmpv with Lua and VapourSynth enabled.
The source machine used mpv `v0.41.0-dev-g35af06172`; a fresh build may need a
different revision compatible with the installed FFmpeg and Tsukimi.

```bash
git clone https://github.com/mpv-player/mpv.git "$HOME/.local/src/mpv-svp-src"
cd "$HOME/.local/src/mpv-svp-src"
meson setup build --prefix="$HOME/.local/opt/mpv-svp" --libdir=lib \
  -Dlibmpv=true -Ddefault_library=shared \
  -Dvapoursynth=enabled -Dlua=enabled
meson compile -C build
meson install -C build
"$HOME/.local/opt/mpv-svp/bin/mpv" --vf=help | grep vapoursynth
test -e "$HOME/.local/opt/mpv-svp/lib/libmpv.so.2"
```

If Meson reports a missing required dependency, install that dependency and
rerun setup. The build options above come from [mpv's Meson
options](https://github.com/mpv-player/mpv/blob/master/meson.options).

The standalone mpv configuration disables its built-in OSC. Install
[uosc](https://github.com/tomasklaen/uosc#install) into `~/.config/mpv`
before using that configuration, including uosc's `scripts/` and `fonts/`.
The included `script-opts/uosc.conf` selects Simplified Chinese first.

## 2. Back up and restore the optional configuration

Run these commands after restoring the main repository. Inspect the target
files first. The backup loop preserves any existing files that will be
replaced; keep the backup until playback is verified.

```bash
svp_root="$HOME/optional/svp"
svp_backup="$HOME/dotfile-svp-backup-$(date +%Y%m%d-%H%M%S)"
for rel in \
  .config/mpv/mpv.conf \
  .config/mpv/script-opts/uosc.conf \
  .config/mpv/scripts/mpvSockets.lua \
  .config/tsukimi-svp/mpv.conf \
  .config/tsukimi-svp/scripts/hwdec-copy.lua \
  .local/bin/mpv \
  .local/bin/tsukimi-svp \
  .local/share/applications/mpv.desktop \
  .local/share/applications/moe.tsuna.tsukimi.desktop; do
  if [ -e "$HOME/$rel" ] || [ -L "$HOME/$rel" ]; then
    mkdir -p "$svp_backup/$(dirname "$rel")"
    cp -a -- "$HOME/$rel" "$svp_backup/$rel"
  fi
done
printf 'Existing files backed up to: %s\n' "$svp_backup"

install -Dm644 "$svp_root/config/mpv/mpv.conf" "$HOME/.config/mpv/mpv.conf"
install -Dm644 "$svp_root/config/mpv/script-opts/uosc.conf" "$HOME/.config/mpv/script-opts/uosc.conf"
install -Dm644 "$svp_root/config/mpv/scripts/mpvSockets.lua" "$HOME/.config/mpv/scripts/mpvSockets.lua"
install -Dm644 "$svp_root/config/tsukimi-svp/mpv.conf" "$HOME/.config/tsukimi-svp/mpv.conf"
install -Dm644 "$svp_root/config/tsukimi-svp/scripts/hwdec-copy.lua" "$HOME/.config/tsukimi-svp/scripts/hwdec-copy.lua"
install -Dm755 "$svp_root/bin/mpv" "$HOME/.local/bin/mpv"
install -Dm755 "$svp_root/bin/tsukimi-svp" "$HOME/.local/bin/tsukimi-svp"
```

`mpvSockets.lua` gives standalone mpv windows separate IPC sockets. Tsukimi
uses its own configuration directory and `/tmp/mpvsocket`. Do not copy the
standalone mpv scripts or uosc into the Tsukimi directory.

## 3. Select the launchers and Tsukimi configuration

Make user-level desktop entries from the installed packages, then replace only
their main `Exec` line. This makes desktop launches use the wrappers without
changing `/usr/share/applications` or depending on the desktop session's PATH.

```bash
install -Dm644 /usr/share/applications/mpv.desktop \
  "$HOME/.local/share/applications/mpv.desktop"
sed -i \
  -e "0,/^Exec=/s#^Exec=.*#Exec=$HOME/.local/bin/mpv --player-operation-mode=pseudo-gui -- %U#" \
  -e "s#^TryExec=.*#TryExec=$HOME/.local/bin/mpv#" \
  "$HOME/.local/share/applications/mpv.desktop"

install -Dm644 /usr/share/applications/moe.tsuna.tsukimi.desktop \
  "$HOME/.local/share/applications/moe.tsuna.tsukimi.desktop"
sed -i "0,/^Exec=/s#^Exec=.*#Exec=$HOME/.local/bin/tsukimi-svp#" \
  "$HOME/.local/share/applications/moe.tsuna.tsukimi.desktop"

gsettings set moe.tsuna.tsukimi mpv-config true
gsettings set moe.tsuna.tsukimi mpv-config-path "$HOME/.config/tsukimi-svp"
gsettings set moe.tsuna.tsukimi mpv-hwdec 1
```

Tsukimi's hardware-decoding menu will show `auto-safe` (value `1`). The
`hwdec-copy.lua` on-load hook changes the actual decoder to `nvdec-copy`
before each file opens so SVP can read frames in system memory. Launch
Tsukimi through `~/.local/bin/tsukimi-svp` or its user desktop entry; launching
`/usr/bin/tsukimi` directly uses the distribution's libmpv instead.

## 4. Verify playback

```bash
sh -n "$HOME/.local/bin/mpv" "$HOME/.local/bin/tsukimi-svp"
luac -p "$HOME/.config/mpv/scripts/mpvSockets.lua" \
  "$HOME/.config/tsukimi-svp/scripts/hwdec-copy.lua"
"$HOME/.local/opt/mpv-svp/bin/mpv" --vf=help | grep vapoursynth
gsettings get moe.tsuna.tsukimi mpv-config-path
```

Open a video in Tsukimi through its desktop entry, enable interpolation in
SVP Manager, and check SVP's active-video panel. With Tsukimi playing alone,
the following IPC check should show `hwdec-current` as `nvdec-copy` and an
enabled VapourSynth filter labeled `svp`:

```bash
python3 - <<'PY'
import json
import socket

with socket.socket(socket.AF_UNIX) as client:
    client.connect('/tmp/mpvsocket')
    for request_id, name in enumerate(('hwdec-current', 'vf'), 1):
        request = {'command': ['get_property', name], 'request_id': request_id}
        client.sendall((json.dumps(request) + '\n').encode())
    replies = client.makefile()
    for _ in range(2):
        print(json.loads(replies.readline()))
PY
```

For standalone mpv, `mpvSockets.lua` changes the socket path to
`/tmp/mpvSockets/<pid>`. The two players may be tested separately. Check
`hwdec-current` during playback: it can legitimately fall back to software
decoding for an unsupported codec. The SVP filter is added by SVP Manager when
it recognizes the video, not by a permanent `vf=` line in these configs.
