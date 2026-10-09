#!/usr/bin/env python3
"""Copy Caelestia's active palette into Folia's custom day/night theme."""

import argparse
import base64
import json
import os
from pathlib import Path
import secrets
import socket
import struct
import time
from urllib.parse import urlparse
from urllib.request import urlopen


HOME = Path.home()
SCHEME = Path(os.environ.get(
    "CAELESTIA_SCHEME_FILE",
    Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "caelestia/scheme.json",
))
DEVTOOLS_PORT = Path(os.environ.get(
    "FOLIA_DEVTOOLS_PORT_FILE",
    Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "Folia/DevToolsActivePort",
))


def palette():
    scheme = json.loads(SCHEME.read_text())
    mode = scheme["mode"]
    if mode not in ("light", "dark"):
        raise ValueError(f"unsupported Caelestia mode: {mode}")
    colours = scheme["colours"]

    def color(name):
        value = colours[name]
        if not isinstance(value, str) or len(value) != 6 or any(c not in "0123456789abcdefABCDEF" for c in value):
            raise ValueError(f"invalid Caelestia colour: {name}")
        return "#" + value.lower()

    return mode, {
        "name": f"Caelestia {mode.title()}",
        "backgroundColor": color("background"),
        "primaryColor": color("primary"),
        "accentColor": color("secondary"),
        "secondaryColor": color("tertiary"),
    }


def websocket_message(url, payload):
    target = urlparse(url)
    if target.hostname != "127.0.0.1" or target.scheme != "ws":
        raise ValueError("unexpected DevTools address")
    port = target.port
    key = base64.b64encode(secrets.token_bytes(16)).decode()
    with socket.create_connection(("127.0.0.1", port), timeout=3) as sock:
        sock.settimeout(5)
        request = (
            f"GET {target.path} HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\n"
            f"Upgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {key}\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n"
        )
        sock.sendall(request.encode())
        response = bytearray()
        while b"\r\n\r\n" not in response:
            response.extend(sock.recv(4096))
            if len(response) > 16384:
                raise RuntimeError("oversized DevTools handshake")
        header, remaining = bytes(response).split(b"\r\n\r\n", 1)
        if not header.startswith(b"HTTP/1.1 101 "):
            raise RuntimeError("DevTools WebSocket handshake failed")

        data = json.dumps(payload, separators=(",", ":")).encode()
        mask = secrets.token_bytes(4)
        length = len(data)
        size = bytes([0x81, 0x80 | length]) if length < 126 else bytes([0x81, 0x80 | 126]) + struct.pack("!H", length)
        sock.sendall(size + mask + bytes(byte ^ mask[i % 4] for i, byte in enumerate(data)))

        buffer = bytearray(remaining)

        def read(count):
            while len(buffer) < count:
                chunk = sock.recv(65536)
                if not chunk:
                    raise RuntimeError("DevTools disconnected")
                buffer.extend(chunk)
            result = bytes(buffer[:count])
            del buffer[:count]
            return result

        while True:
            first, second = read(2)
            length = second & 0x7f
            if length == 126:
                length = struct.unpack("!H", read(2))[0]
            elif length == 127:
                length = struct.unpack("!Q", read(8))[0]
            if second & 0x80:
                frame_mask = read(4)
                body = bytes(byte ^ frame_mask[i % 4] for i, byte in enumerate(read(length)))
            else:
                body = read(length)
            if first & 0x0f == 1:
                message = json.loads(body)
                if message.get("id") == payload["id"]:
                    return message
            elif first & 0x0f == 8:
                raise RuntimeError("DevTools closed the connection")


def sync():
    mode, colors = palette()
    if not DEVTOOLS_PORT.exists():
        return False
    port = int(DEVTOOLS_PORT.read_text().splitlines()[0])
    if not 1 <= port <= 65535:
        return False
    with urlopen(f"http://127.0.0.1:{port}/json/list", timeout=2) as response:
        pages = json.load(response)
    candidates = [page for page in pages if page.get("type") == "page" and
                  (page.get("url", "").startswith("file://") or page.get("title") == "Folia")]
    page = next((page for page in candidates if page.get("title") == "Folia"), None)
    if page is None:
        page = next((page for page in candidates if page.get("title") != "Folia Remote"), None)
    if page is None:
        return False

    expression = """(() => {
      const incoming = INCOMING;
      const key = 'custom_dual_theme';
      const root = document.getElementById('root');
      const rootKey = root && Object.keys(root).find(k => k.startsWith('__reactContainer$'));
      if (!rootKey) return { ready: false };
      const stack = [root[rootKey]];
      let hooks = null;
      let settings = null;
      while (stack.length && (!hooks || !settings)) {
        const fiber = stack.pop();
        if (!fiber) continue;
        let hook = fiber.memoizedState;
        for (let count = 0; hook && count < 500; count++, hook = hook.next) {
          const value = hook.memoizedState;
          if (value && typeof value.isDaylight === 'boolean' &&
              typeof value.setDaylightPreference === 'function' &&
              typeof value.setDaylightPreferenceFromSystem === 'function') {
            settings = value;
          }
          const preference = hook.next;
          const auto = preference?.next;
          const generate = auto?.next;
          const mode = generate?.next?.next;
          if (value?.light?.backgroundColor && value?.dark?.backgroundColor &&
              typeof hook.queue?.dispatch === 'function' &&
              typeof preference?.memoizedState === 'boolean' &&
              typeof auto?.memoizedState === 'boolean' &&
              typeof generate?.memoizedState === 'boolean' &&
              ['default', 'custom', 'ai'].includes(mode?.memoizedState) &&
              typeof mode.queue?.dispatch === 'function') {
            hooks = { theme: hook, preference, auto, generate, mode };
            if (settings) break;
          }
        }
        if (fiber.sibling) stack.push(fiber.sibling);
        if (fiber.child) stack.push(fiber.child);
      }
      if (!hooks || !settings) return { ready: false };

      const dual = { ...hooks.theme.memoizedState };
      const fallback = side => ({
        name: 'Caelestia ' + side, backgroundColor: side === 'light' ? '#faf8fa' : '#110d11',
        primaryColor: side === 'light' ? '#211b20' : '#efe2ec',
        accentColor: incoming.colors.accentColor, secondaryColor: incoming.colors.secondaryColor,
        fontStyle: 'sans', animationIntensity: 'normal', wordColors: [], lyricsIcons: [],
        provider: 'Custom', description: ''
      });
      for (const side of ['light', 'dark']) {
        dual[side] = { ...fallback(side), ...(dual[side] || {}) };
      }
      const sides = localStorage.getItem('follow_system_theme') === 'true'
        ? [incoming.mode] : ['light', 'dark'];
      for (const side of sides) {
        dual[side] = { ...dual[side], ...incoming.colors,
          name: 'Caelestia ' + side[0].toUpperCase() + side.slice(1) };
      }
      const next = JSON.stringify(dual);
      const isDaylight = incoming.mode === 'light';
      const modeChanged = settings.isDaylight !== isDaylight;
      const changed = JSON.stringify(hooks.theme.memoizedState) !== next ||
        hooks.preference.memoizedState !== true || hooks.auto.memoizedState !== false ||
        hooks.generate.memoizedState !== false || hooks.mode.memoizedState !== 'custom' ||
        modeChanged;
      if (changed) {
        localStorage.setItem(key, next);
        localStorage.setItem('custom_theme_preferred', 'true');
        localStorage.setItem('last_applied_theme_pointer', 'custom');
        localStorage.setItem('theme_auto_switch_enabled', 'false');
        localStorage.setItem('theme_auto_generate_enabled', 'false');
        hooks.theme.queue.dispatch(dual);
        hooks.preference.queue.dispatch(true);
        hooks.auto.queue.dispatch(false);
        hooks.generate.queue.dispatch(false);
        hooks.mode.queue.dispatch('custom');
        if (modeChanged) {
          if (settings.followSystemTheme) {
            settings.setDaylightPreferenceFromSystem(isDaylight);
          } else {
            settings.setDaylightPreference(isDaylight);
          }
        }
      }
      return { ready: true, changed, mode: incoming.mode };
    })()""".replace("INCOMING", json.dumps({"mode": mode, "colors": colors}, separators=(",", ":")))
    result = websocket_message(page["webSocketDebuggerUrl"], {
        "id": 1, "method": "Runtime.evaluate",
        "params": {"expression": expression, "returnByValue": True, "awaitPromise": True},
    })
    if "error" in result or "exceptionDetails" in result.get("result", {}):
        exception = result.get("result", {}).get("exceptionDetails", {})
        detail = exception.get("exception", {}).get("description") or exception.get("text") or result.get("error", {}).get("message")
        raise RuntimeError(f"Folia rejected the theme update: {detail or 'unknown error'}")
    value = result.get("result", {}).get("result", {}).get("value", {})
    if not value.get("ready"):
        return False
    print(f"Folia theme: {mode}, {'updated' if value.get('changed') else 'already current'}")
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wait", type=int, default=0, help="wait for Folia DevTools at startup")
    parser.add_argument("--check", action="store_true", help="show palette without connecting to Folia")
    args = parser.parse_args()
    if args.check:
        print(json.dumps(dict(zip(("mode", "colors"), palette())), ensure_ascii=False))
        return
    deadline = time.monotonic() + args.wait
    while True:
        try:
            if sync():
                return
        except (OSError, ValueError, RuntimeError) as exc:
            if time.monotonic() >= deadline:
                print(f"Folia theme sync: {exc}", file=os.sys.stderr)
                return
        if time.monotonic() >= deadline:
            return
        time.sleep(0.5)


if __name__ == "__main__":
    main()
