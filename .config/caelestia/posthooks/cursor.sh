#!/usr/bin/env bash
set -euo pipefail
"$HOME/.local/bin/bibata-caelestia-builder" build --size 24 --dest "$HOME/.local/share/icons/Bibata-Caelestia"
if [[ -x /usr/local/sbin/caelestia-cursor-deploy ]]; then
    sudo -n /usr/local/sbin/caelestia-cursor-deploy
fi
