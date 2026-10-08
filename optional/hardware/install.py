#!/usr/bin/env python3
"""Opt-in Hardware dashboard tab for a local Midnight Shell copy."""

import argparse
import datetime
import os
import shutil
import sys
from pathlib import Path


MARK = "caelestia-hardware"
TAB = '''            // >>> caelestia-hardware >>>
            {
                component: hardwareComponent,
                iconName: "developer_board",
                text: qsTr("Hardware"),
                enabled: true
            },
            // <<< caelestia-hardware <<<'''
COMPONENT = '''            // >>> caelestia-hardware >>>
            Component {
                id: hardwareComponent

                HardwareTab {}
            }
            // <<< caelestia-hardware <<<'''
OLD_TAB = '''            {
                component: hardwareComponent,
                iconName: "developer_board",
                text: qsTr("Hardware"),
                enabled: true
            },'''
OLD_COMPONENT = '''            Component {
                id: hardwareComponent

                HardwareTab {}
            }'''


def edit_section(text, block, legacy, anchor, reference, remove):
    start = f"            // >>> {MARK} >>>"
    end = f"            // <<< {MARK} <<<"
    if text.count(start) != text.count(end):
        raise ValueError("Incomplete Hardware markers in Content.qml")
    if text.count(start):
        if text.count(start) > 2:
            raise ValueError("Duplicate Hardware markers in Content.qml")
        # The tab and component share markers; select the one containing this reference.
        for first in (i for i in range(len(text)) if text.startswith(start, i)):
            last = text.find(end, first)
            if last >= 0 and reference in text[first:last]:
                return text[:first] + ("" if remove else block) + text[last + len(end):]
    if legacy in text:
        return text.replace(legacy, "" if remove else block, 1)
    if reference in text:
        raise ValueError(f"Unrecognized Hardware integration: {reference}")
    if remove:
        return text
    if text.count(anchor) != 1:
        raise ValueError(f"Cannot find a unique insertion point for {reference}")
    return text.replace(anchor, block + "\n" + anchor, 1)


def changed_copy(source, destination, backup):
    if destination.exists() and destination.read_bytes() == source.read_bytes():
        return False
    if destination.exists():
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(destination, backup)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uninstall", action="store_true", help="remove the Hardware tab")
    args = parser.parse_args()

    home = Path.home()
    source = Path(__file__).resolve().parent
    dashboard = home / ".config/quickshell/caelestia/modules/dashboard"
    content = dashboard / "Content.qml"
    if not content.is_file():
        parser.error(f"Local Midnight Shell copy missing: {content}")
    if not args.uninstall:
        missing = [name for name in ("omen-cli", "scxctl", "busctl") if not shutil.which(name)]
        if missing:
            parser.error("Missing hardware commands: " + ", ".join(missing))

    original = content.read_text()
    updated = edit_section(original, TAB, OLD_TAB,
                           "            {\n                component: terminalComponent,",
                           "component: hardwareComponent", args.uninstall)
    updated = edit_section(updated, COMPONENT, OLD_COMPONENT,
                           "            Component {\n                id: terminalComponent",
                           "id: hardwareComponent", args.uninstall)

    targets = (
        (source / "HardwareTab.qml", dashboard / "HardwareTab.qml"),
        (source / "caelestia-hardware", home / ".local/bin/caelestia-hardware"),
    )
    backup = home / ".local/state/caelestia-hardware/backups" / (
        datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + f"-{os.getpid()}")
    changed = False
    if updated != original:
        backup_file = backup / ".config/quickshell/caelestia/modules/dashboard/Content.qml"
        backup_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(content, backup_file)
        content.write_text(updated)
        changed = True

    for payload, target in targets:
        backup_file = backup / target.relative_to(home)
        if args.uninstall:
            if target.exists() and target.read_bytes() == payload.read_bytes():
                target.unlink()
                changed = True
            elif target.exists():
                print(f"Kept modified file: {target}")
        else:
            changed = changed_copy(payload, target, backup_file) or changed

    print("Hardware tab removed." if args.uninstall else "Hardware tab installed.")
    if backup.exists():
        print(f"Previous files: {backup}")
    if changed:
        print("Reload with: caelestia shell -r -d")
    return 0


if __name__ == "__main__":
    sys.exit(main())
