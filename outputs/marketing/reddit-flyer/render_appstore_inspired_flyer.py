from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from reportlab.graphics.barcode import qrencoder


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "outputs" / "marketing" / "reddit-flyer"
SCREENS = OUT / "appstore-screens"
ICON = ROOT / "MyWealth" / "Assets.xcassets" / "AppIcon.appiconset" / "1024.png"
PNG = OUT / "wealth-map-reddit-flyer-appstyle.png"
QR_PNG = OUT / "wealth-map-appstore-qr.png"
APP_STORE_URL = "https://apps.apple.com/us/app/wealth-map/id6755058253"

W, H = 1080, 1350
INK = "#111716"
MUTED = "#686f6c"
CARD = "#f4f4f4"
CARD_2 = "#f0f0f0"
GOLD = "#b98513"
YELLOW = "#ffcc00"
MAGENTA = "#d016a4"
GREEN = "#34c759"
RED = "#ff3b44"
TEAL = "#12bfc2"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default(size=size)


F = {
    "brand": font(44, True),
    "meta": font(22, True),
    "chip": font(20, True),
    "h1": font(72, True),
    "sub": font(28, True),
    "card_title": font(26, True),
    "card_body": font(22, False),
    "small": font(17, True),
    "tiny": font(14, True),
    "value": font(31, True),
    "footer": font(30, True),
    "url": font(23, True),
}


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def rounded_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int, fill: str, alpha: int = 28, offset: tuple[int, int] = (0, 14), blur: int = 22, outline: str | None = None) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    ox, oy = offset
    d.rounded_rectangle((x0 + ox, y0 + oy, x1 + ox, y1 + oy), radius=radius, fill=(0, 0, 0, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)
    d = ImageDraw.Draw(base)
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=1)


def draw_dots(draw: ImageDraw.ImageDraw) -> None:
    spacing = 18
    for y in range(18, H, spacing):
        for x in range(0, W, spacing):
            if (x // spacing + y // spacing) % 2 == 0:
                r = 1.25
            else:
                r = 1.0
            draw.ellipse((x - r, y - r, x + r, y + r), fill=MAGENTA)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    current = ""
    for word in text.split():
        trial = f"{current} {word}".strip()
        if draw.textbbox((0, 0), trial, font=fnt)[2] <= width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def text_block(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt: ImageFont.FreeTypeFont, fill: str, width: int, gap: int = 7) -> int:
    x, y = xy
    for line in wrap(draw, text, fnt, width):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += draw.textbbox((0, 0), line, font=fnt)[3] + gap
    return y


def paste_icon(base: Image.Image) -> None:
    icon = Image.open(ICON).convert("RGBA").resize((82, 82), Image.Resampling.LANCZOS)
    rounded_shadow(base, (58, 56, 160, 158), 24, "#ffffff", alpha=18, offset=(0, 12), blur=28)
    base.alpha_composite(icon, (68, 66))


def screen_card(base: Image.Image, path: Path, xy: tuple[int, int], size: tuple[int, int], rotate: float = 0, alpha: float = 1.0) -> None:
    src = Image.open(path).convert("RGBA").resize(size, Image.Resampling.LANCZOS)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, size[0], size[1]), radius=38, fill=255)
    src.putalpha(mask)

    pad = 52
    stage = Image.new("RGBA", (size[0] + pad * 2, size[1] + pad * 2), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stage)
    sd.rounded_rectangle((pad + 10, pad + 18, pad + size[0] + 10, pad + size[1] + 18), radius=40, fill=(0, 0, 0, round(55 * alpha)))
    stage = stage.filter(ImageFilter.GaussianBlur(11))
    stage.alpha_composite(src, (pad, pad))
    if alpha < 1:
        a = stage.getchannel("A")
        a = a.point(lambda p: round(p * alpha))
        stage.putalpha(a)
    if rotate:
        stage = stage.rotate(rotate, resample=Image.Resampling.BICUBIC, expand=True)
    base.alpha_composite(stage, (xy[0] - pad, xy[1] - pad))


def chip(draw: ImageDraw.ImageDraw, xy: tuple[int, int], label: str, w: int | None = None) -> None:
    x, y = xy
    text_w = draw.textbbox((0, 0), label, font=F["chip"])[2]
    width = w or text_w + 54
    draw.rounded_rectangle((x, y, x + width, y + 46), radius=23, fill="#fff2ce", outline="#d8aa48", width=1)
    draw.ellipse((x + 18, y + 18, x + 28, y + 28), fill=GOLD)
    draw.text((x + 42, y + 11), label, font=F["chip"], fill="#845507")


def mini_row(base: Image.Image, xy: tuple[int, int], color: str, title: str, detail: str) -> None:
    d = ImageDraw.Draw(base)
    x, y = xy
    d.rounded_rectangle((x, y, x + 472, y + 58), radius=13, fill="#ffffff")
    d.rounded_rectangle((x + 12, y + 13, x + 44, y + 45), radius=10, fill=color)
    d.text((x + 24, y + 17), "✓", font=font(20, True), fill="#ffffff", anchor="ma")
    d.text((x + 58, y + 9), title, font=F["small"], fill=INK)
    d.text((x + 58, y + 31), detail, font=font(15, False), fill=MUTED)


def qr_image(data: str, size: int = 124, border: int = 4) -> Image.Image:
    qr = qrencoder.QRCode(None, qrencoder.QRErrorCorrectLevel.M)
    qr.addData(data)
    qr.make()
    modules = qr.modules
    module_count = qr.getModuleCount()
    total = module_count + border * 2
    module_size = size // total
    pixel_size = module_size * total
    img = Image.new("RGB", (pixel_size, pixel_size), "#ffffff")
    draw = ImageDraw.Draw(img)
    for row_index, row in enumerate(modules):
        for col_index, is_dark in enumerate(row):
            if is_dark:
                x0 = (col_index + border) * module_size
                y0 = (row_index + border) * module_size
                draw.rectangle((x0, y0, x0 + module_size - 1, y0 + module_size - 1), fill="#111716")
    return img.resize((size, size), Image.Resampling.NEAREST).convert("RGBA")


def draw_qr_card(base: Image.Image, xy: tuple[int, int]) -> None:
    d = ImageDraw.Draw(base)
    x, y = xy
    rounded_shadow(base, (x, y, x + 342, y + 128), 22, "#ffffff", alpha=14, offset=(0, 10), blur=18, outline="#e3e3e3")
    qr = qr_image(APP_STORE_URL, 108)
    base.alpha_composite(qr, (x + 16, y + 10))
    d.text((x + 138, y + 22), "Scan for App Store", font=F["small"], fill=INK)
    d.text((x + 138, y + 50), "Wealth Map", font=F["url"], fill="#805408")
    d.text((x + 138, y + 84), "or search the name", font=font(15, True), fill=MUTED)
    QR_PNG.parent.mkdir(parents=True, exist_ok=True)
    qr_image(APP_STORE_URL, 512).convert("RGB").save(QR_PNG, quality=96)


def draw_left_panel(base: Image.Image) -> None:
    d = ImageDraw.Draw(base)
    paste_icon(base)
    d.text((186, 74), "Wealth Map", font=F["brand"], fill=INK)
    d.text((188, 124), "No account required", font=F["meta"], fill=MUTED)
    d.rounded_rectangle((750, 70, 1010, 124), radius=27, fill="#ffffff", outline="#e0b557", width=1)
    d.text((784, 87), "Free on App Store", font=F["chip"], fill="#805408")

    chip(d, (64, 286), "Assets • Debts • Rates")
    y = text_block(d, (64, 368), "Your whole net worth, mapped clearly.", F["h1"], INK, 520, 4)
    y += 20
    y = text_block(d, (64, y), "Track assets, liabilities, exchange rates, precious metals, history, reminders, and widgets in one focused iOS app.", F["sub"], "#3e4543", 500, 6)
    y += 30

    rounded_shadow(base, (64, y, 568, y + 276), 20, CARD, alpha=12, offset=(0, 8), blur=18, outline="#ededed")
    d.text((92, y + 24), "Portfolio Insights", font=F["card_title"], fill=INK)
    band_y = y + 70
    d.rounded_rectangle((92, band_y, 540, band_y + 86), radius=13, fill="#ffffff")
    d.text((118, band_y + 16), "Assets", font=F["tiny"], fill=MUTED)
    d.text((210, band_y + 16), "$210,000.00", font=F["small"], fill=INK)
    d.rounded_rectangle((92, band_y + 48, 540, band_y + 86), radius=0, fill=YELLOW)
    d.text((118, band_y + 57), "Net Worth", font=F["small"], fill=INK)
    d.text((326, band_y + 57), "$200,000.00", font=F["small"], fill=INK)
    mini_row(base, (92, y + 172), GREEN, "Multi-currency totals", "Base + display currencies")
    mini_row(base, (92, y + 236), "#f0c95a", "Metals and rates", "Gold, silver, platinum + more")

    d.line((64, 1192, 1010, 1192), fill="#d8d8d8", width=1)
    d.text((64, 1222), "Try it. Roast it. Tell me what to improve.", font=F["footer"], fill=INK)
    d.text((64, 1264), "App Store: Wealth Map", font=F["url"], fill="#805408")
    draw_qr_card(base, (668, 1204))


def main() -> None:
    base = Image.new("RGBA", (W, H), "#ffffff")
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(bg)
    draw_dots(d)
    base.alpha_composite(bg)

    # Soft bottom tint like the tab bar glow in the screenshots.
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-130, 980, 480, 1510), fill=(255, 204, 0, 35))
    gd.ellipse((700, 70, 1260, 520), fill=(52, 199, 89, 24))
    glow = glow.filter(ImageFilter.GaussianBlur(52))
    base.alpha_composite(glow)

    # Screenshot stack: actual app UI is the hero.
    screen_card(base, SCREENS / "rates.png", (618, 198), (250, 500), rotate=-8, alpha=0.55)
    screen_card(base, SCREENS / "net-worth.png", (810, 246), (240, 480), rotate=7, alpha=0.55)
    screen_card(base, SCREENS / "dashboard-assets.png", (642, 314), (360, 720), rotate=0, alpha=1)

    draw_left_panel(base)

    # Small app-style floating chip over the hero screenshot.
    d = ImageDraw.Draw(base)
    rounded_shadow(base, (678, 1014, 1002, 1088), 27, "#ffffff", alpha=16, offset=(0, 10), blur=18, outline="#e7e7e7")
    d.text((704, 1030), "Actual app screens", font=F["small"], fill=INK)
    d.text((704, 1053), "Dashboard, net worth, rates", font=font(15, False), fill=MUTED)
    d.rounded_rectangle((936, 1030, 974, 1068), radius=12, fill=YELLOW)
    d.line((946, 1051, 954, 1059, 966, 1040), fill=INK, width=4)

    base.convert("RGB").save(PNG, quality=96)
    print(PNG)


if __name__ == "__main__":
    main()
