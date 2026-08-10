# Celluloid mpv configuration

This directory mirrors the mpv configuration without the uosc theme.

Enable the configuration after restoring the dotfiles:

```sh
gsettings set io.github.celluloid-player.Celluloid mpv-config-file "$HOME/.config/celluloid/mpv.conf"
gsettings set io.github.celluloid-player.Celluloid mpv-config-enable true
gsettings set io.github.celluloid-player.Celluloid mpv-input-config-file "$HOME/.config/celluloid/input.conf"
gsettings set io.github.celluloid-player.Celluloid mpv-input-config-enable true
```
