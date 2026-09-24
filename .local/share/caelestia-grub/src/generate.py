import sys
import os
import subprocess
import json
import re

os.environ["QT_QPA_PLATFORM"] = "offscreen"

from PIL import Image, ImageFilter, ImageOps
from PyQt6.QtWidgets import QApplication
from PyQt6.QtQuick import QQuickView
from PyQt6.QtCore import QUrl, QTimer, QRectF, Qt
from PyQt6.QtGui import QImage, QPainter, QColor, QPen, QPainterPath

def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def get_scheme_colors():
    colors = {
        "primary_paletteKeyColor": "#7171ac", "secondary_paletteKeyColor": "#76758e", "tertiary_paletteKeyColor": "#9e648e",
        "background": "#131317", "surface": "#131317", "surfaceContainerHigh": "#2a292e", "surfaceContainerHighest": "#353438",
        "surfaceContainer": "#201f23", "primary": "#c2c1ff", "primaryContainer": "#7171ac", "text": "#e5e1e7", "textDark": "#918f9a"
    }
    meta = {
        "Name": "catppuccin", "Flavour": "mocha", "Mode": "dark", "Variant": "tonalspot"
    }
    try:
        output = subprocess.check_output(["caelestia", "scheme", "get"], text=True)
        output = strip_ansi(output)
        in_colours = False
        parsed_colors = {}
        parsed_meta = {}
        for line in output.split('\n'):
            line = line.strip()
            if line.startswith("Colours:"):
                in_colours = True
                continue
            if in_colours and ":" in line:
                key, val = line.split(":", 1)
                parsed_colors[key.strip()] = "#" + val.strip()
            elif ":" in line:
                key, val = line.split(":", 1)
                parsed_meta[key.strip()] = val.strip()
        if parsed_colors:
            colors = parsed_colors
        if parsed_meta:
            meta = parsed_meta
    except Exception as e:
        print("Failed to get scheme, falling back to default Catppuccin Mocha:", e)

    if "textDark" not in colors and "subtext0" in colors:
        colors["textDark"] = colors["subtext0"]
    return colors, meta

def get_shell_config():
    config = {
        "transparency_base": 0.75,
        "transparency_layers": 0.4,
        "rounding_scale": 1.0,
        "rounding_window": 16, # Default smaller than before
        "rounding_item": 12,
        "wallpaperRecolor": True,
        "wallpaperRecolorStrength": 1.0,
        "item_height": 52,
        "item_padding": 10,
        "item_spacing": 20,
        "timeout_height": 12
    }

    shell_json_path = os.path.expanduser("~/.config/caelestia/shell.json")
    if os.path.exists(shell_json_path):
        try:
            with open(shell_json_path) as f:
                data = json.load(f)
                app = data.get("appearance", {})
                transp = app.get("transparency", {})
                if "base" in transp:
                    config["transparency_base"] = transp["base"]
                if "layers" in transp:
                    config["transparency_layers"] = transp["layers"]
                bg = data.get("background", {})
                if "wallpaperRecolor" in bg:
                    config["wallpaperRecolor"] = bg["wallpaperRecolor"]
                if "wallpaperRecolorStrength" in bg:
                    config["wallpaperRecolorStrength"] = bg["wallpaperRecolorStrength"]
                rounding = app.get("rounding", {})
                if "scale" in rounding:
                    config["rounding_scale"] = rounding["scale"]
        except:
            pass

    tokens_json_path = os.path.expanduser("~/.config/caelestia/shell-tokens.json")
    if os.path.exists(tokens_json_path):
        try:
            with open(tokens_json_path) as f:
                data = json.load(f)
                rounding = data.get("appearance", {}).get("rounding", {})
                if "extraExtraLarge" in rounding:
                    config["rounding_window"] = rounding["extraExtraLarge"]
                if "large" in rounding:
                    config["rounding_item"] = rounding["large"]

                # Keep boot-menu geometry independent of desktop padding tokens.
        except:
            pass

    return config

def get_active_wallpaper():
    path = os.path.expanduser("~/.local/state/caelestia/wallpaper/current")
    if os.path.exists(path):
        return os.path.realpath(path)
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "background.png")

def get_luminance(hex_color):
    hex_color = hex_color.lstrip('#')
    if len(hex_color) == 6:
        r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    else:
        return 0
    return (0.299 * r + 0.587 * g + 0.114 * b)

def process_icons(scheme_colors):
    import shutil
    src_dir = "icons"
    dst_dir = "../theme/icons"
    if not os.path.exists(src_dir):
        return

    os.makedirs(dst_dir, exist_ok=True)
    text_hex = scheme_colors.get("text", "#ffffff")
    # If text is dark (luminance < 128), we must invert the white icons to black
    invert = get_luminance(text_hex) < 128

    for filename in os.listdir(src_dir):
        if not filename.endswith(".png"):
            continue
        src_path = os.path.join(src_dir, filename)
        dst_path = os.path.join(dst_dir, filename)

        if invert:
            try:
                img = Image.open(src_path).convert("RGBA")
                r, g, b, a = img.split()
                rgb = Image.merge("RGB", (r, g, b))
                rgb = ImageOps.invert(rgb)
                r2, g2, b2 = rgb.split()
                img = Image.merge("RGBA", (r2, g2, b2, a))
                img.save(dst_path)
            except Exception as e:
                print(f"Failed to process icon {filename}:", e)
        else:
            shutil.copy2(src_path, dst_path)
    print(f"Processed {len(os.listdir(src_dir))} icons (Inverted: {invert})")

def update_theme_txt(scheme_colors, shell_cfg):
    theme_txt_path = "../theme/theme.txt"
    if not os.path.exists(theme_txt_path):
        return

    with open(theme_txt_path, "r") as f:
        content = f.read()

    text_color = scheme_colors.get("textDark", "#a2adac")
    selected_text_color = scheme_colors.get("text", "#dce8e6")

    content = re.sub(r'item_color\s*=\s*".*"', f'item_color = "{text_color}"', content)
    content = re.sub(r'selected_item_color\s*=\s*".*"', f'selected_item_color = "{selected_text_color}"', content)
    content = re.sub(r'item_height\s*=\s*\d+', f'item_height = {shell_cfg["item_height"]}', content)
    content = re.sub(r'item_padding\s*=\s*\d+', f'item_padding = {shell_cfg["item_padding"]}', content)
    content = re.sub(r'item_spacing\s*=\s*\d+', f'item_spacing = {shell_cfg["item_spacing"]}', content)

    # Update progress bar height dynamically
    content = re.sub(r'(\+ progress_bar \{[^}]*height\s*=\s*)\d+', rf'\g<1>{shell_cfg["timeout_height"]}', content)

    with open(theme_txt_path, "w") as f:
        f.write(content)

from PIL import Image, ImageFilter, ImageOps, ImageEnhance

def create_composite_bg(scheme_colors, scheme_meta, shell_cfg):
    wp_path = get_active_wallpaper()

    if wp_path.lower().endswith(('.mp4', '.mkv', '.webm', '.avi', '.gif', '.mov')):
        import tempfile
        import subprocess
        tmp_frame = os.path.join(tempfile.gettempdir(), 'caelestia_grub_frame.png')
        subprocess.run(
            ["ffmpeg", "-i", wp_path, "-vframes", "1", "-q:v", "2", tmp_frame, "-y"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        if os.path.exists(tmp_frame):
            wp_path = tmp_frame

    sharp_path = os.path.abspath("../theme/sharp.png")
    blur_path = os.path.abspath("../theme/blur.png")
    comp_path = os.path.abspath("../theme/composite_bg.png")

    try:
        img = Image.open(wp_path).convert("RGB")
        img = ImageOps.fit(img, (1920, 1080), Image.Resampling.LANCZOS)

        # Read properties
        should_recolor = shell_cfg.get("wallpaperRecolor", True)
        is_dynamic = scheme_meta.get("Name") == "dynamic"
        is_monochrome = scheme_meta.get("Variant") == "monochrome"
        is_hard = scheme_meta.get("Flavour") == "hard"

        should_recolor_active = should_recolor and (not is_dynamic or is_monochrome)

        # 1. Grayscale
        if should_recolor and is_dynamic and is_monochrome:
            img = ImageOps.grayscale(img).convert("RGB")

        # 2. Contrast
        if should_recolor_active and is_hard:
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(1.45)

        img.save(sharp_path)

        blur = img.filter(ImageFilter.GaussianBlur(radius=30))
        blur.save(blur_path)
    except Exception as e:
        print("PIL processing failed:", e)
        return wp_path

    qimg_sharp = QImage(sharp_path)
    qimg_blur = QImage(blur_path)

    painter = QPainter(qimg_sharp)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)

    # 3. Colorization (MultiEffect simulation via QPainter)
    should_recolor = shell_cfg.get("wallpaperRecolor", True)
    is_dynamic = scheme_meta.get("Name") == "dynamic"
    is_monochrome = scheme_meta.get("Variant") == "monochrome"
    should_recolor_active = should_recolor and (not is_dynamic or is_monochrome)

    if should_recolor_active and not is_monochrome:
        strength = shell_cfg.get("wallpaperRecolorStrength", 1.0)
        if strength > 0:
            painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_Overlay)
            painter.setOpacity(strength)
            painter.fillRect(0, 0, 1920, 1080, QColor(scheme_colors.get("primary", "#9bd0cc")))
            painter.setOpacity(1.0)
            painter.setCompositionMode(QPainter.CompositionMode.CompositionMode_SourceOver)

    win_w, win_h = 1200, 800
    win_x = (1920 - win_w) / 2
    win_y = (1080 - win_h) / 2
    rect = QRectF(win_x, win_y, win_w, win_h)

    radius = int(shell_cfg["rounding_window"] * shell_cfg["rounding_scale"])

    primary_color = QColor(scheme_colors.get("primary", "#9bd0cc"))
    painter.setBrush(Qt.BrushStyle.NoBrush)

    for i in range(1, 6):
        glow_color = QColor(primary_color)
        glow_color.setAlpha(int(30 / i))
        pen = QPen(glow_color, i * 3)
        painter.setPen(pen)
        painter.drawRoundedRect(rect, radius, radius)

    path = QPainterPath()
    path.addRoundedRect(rect, radius, radius)
    painter.setClipPath(path)

    painter.drawImage(0, 0, qimg_blur)

    tint = QColor(scheme_colors.get("surfaceContainer", "#131b1a"))
    tint.setAlpha(int(shell_cfg["transparency_base"] * 255))
    painter.setBrush(tint)
    painter.setPen(Qt.PenStyle.NoPen)
    painter.drawRect(0, 0, 1920, 1080)

    painter.setClipping(False)

    pen = QPen(primary_color, 1.5)
    painter.setPen(pen)
    painter.setBrush(Qt.BrushStyle.NoBrush)
    painter.drawRoundedRect(rect, radius, radius)

    painter.end()

    qimg_sharp.save(comp_path)
    return comp_path

def generate_9slice(name, bg_color_hex, shell_cfg, border_color_hex=None, radius=None, alpha_override=None, exact_height=None, max_height=None):
    if exact_height is not None:
        h = exact_height
    else:
        if max_height is not None:
            h = max_height
        else:
            h = 42

    if radius is None:
        r = int(shell_cfg.get("rounding_item", 12) * shell_cfg.get("rounding_scale", 1.0))
    else:
        r = radius

    r = min(r, h // 2)

    c_w = max(r, 2)

    # Crucial Fix: Make the middle slice (e) as large as possible to contain the whole chevron (if used).
    # This ensures GRUB scales the middle uniformly.
    # We MUST ensure c_h * 2 < h so the middle slice has at least 1px height.
    c_h = r + 2
    if c_h * 2 >= h:
        c_h = max((h - 1) // 2, 1)

    mid_w = 20
    w = c_w * 2 + mid_w

    img = QImage(w, h, QImage.Format.Format_ARGB32)
    img.fill(Qt.GlobalColor.transparent)
    painter = QPainter(img)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)

    bg_color = QColor(bg_color_hex)
    if alpha_override is not None:
        bg_color.setAlphaF(alpha_override)
    else:
        bg_color.setAlphaF(shell_cfg.get("transparency_layers", 0.4))
    painter.setBrush(bg_color)

    if border_color_hex:
        border_color = QColor(border_color_hex)
        border_color.setAlphaF(0.8)
        painter.setPen(QPen(border_color, 2))
    else:
        painter.setPen(Qt.PenStyle.NoPen)

    painter.drawRoundedRect(QRectF(0, 0, w, h), r, r)

    painter.end()

    parts = {
        "nw": (0, 0, c_w, c_h),
        "n":  (c_w, 0, mid_w, c_h),
        "ne": (w - c_w, 0, c_w, c_h),
        "w":  (0, c_h, c_w, h - 2 * c_h),
        "c":  (c_w, c_h, mid_w, h - 2 * c_h),
        "e":  (w - c_w, c_h, c_w, h - 2 * c_h),
        "sw": (0, h - c_h, c_w, c_h),
        "s":  (c_w, h - c_h, mid_w, c_h),
        "se": (w - c_w, h - c_h, c_w, c_h)
    }

    for suffix, rect in parts.items():
        comp_path = f"../theme/{name}_{suffix}.png"
        part_img = img.copy(rect[0], rect[1], rect[2], rect[3])
        part_img.save(comp_path)

def save_image():
    try:
        img = view.grabWindow()
        if "--preview" in sys.argv:
            out_path = os.path.abspath("../theme/preview.png")
            img.save(out_path)
            print(f"Saved preview to {out_path}")
        else:
            out_path = os.path.abspath("../theme/background.png")
            img.save(out_path)
            print(f"Saved {out_path}")

            grub_rendered_height = max(30 + 2 * shell_cfg.get("item_padding", 12), shell_cfg.get("item_height", 36))

            generate_9slice("item", scheme_colors.get("surfaceContainerHigh", "#192120"), shell_cfg,
                            exact_height=grub_rendered_height)

            generate_9slice("select", scheme_colors.get("surfaceContainerHighest", "#1d2827"), shell_cfg,
                            exact_height=grub_rendered_height)
            generate_9slice("timeout_bg", scheme_colors.get("surfaceContainerHigh", "#192120"), shell_cfg, exact_height=shell_cfg["timeout_height"], alpha_override=1.0)
            generate_9slice("timeout_hl", scheme_colors.get("primary", "#9bd0cc"), shell_cfg, exact_height=shell_cfg["timeout_height"], alpha_override=1.0)
            print("Saved item and select 9-slice boxes")
            process_icons(scheme_colors)
            update_theme_txt(scheme_colors, shell_cfg)
    except Exception as e:
        print("Error saving:", e)
    finally:
        app.quit()

app = QApplication(sys.argv)
scheme_colors, scheme_meta = get_scheme_colors()
shell_cfg = get_shell_config()

comp_path = create_composite_bg(scheme_colors, scheme_meta, shell_cfg)

with open("theme_config.js", "w") as f:
    f.write(".pragma library\n")
    f.write(f"var scheme = {json.dumps(scheme_colors)};\n")
    f.write(f"var layersTransparency = {shell_cfg['transparency_layers']};\n")
    f.write(f"var bgPath = '{comp_path}';\n")
    f.write(f"var previewMode = {'true' if '--preview' in sys.argv else 'false'};\n")
    f.write(f"var itemHeight = {shell_cfg['item_height']};\n")
    f.write(f"var itemPadding = {shell_cfg['item_padding']};\n")
    f.write(f"var itemSpacing = {shell_cfg['item_spacing']};\n")

view = QQuickView()
view.setResizeMode(QQuickView.ResizeMode.SizeRootObjectToView)
view.setSource(QUrl.fromLocalFile("theme.qml"))
view.setGeometry(0, 0, 1920, 1080)
view.show()
QTimer.singleShot(1000, save_image)
sys.exit(app.exec())
