from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "outputs" / "marketing" / "reddit-flyer"
ICON = ROOT / "MyWealth" / "Assets.xcassets" / "AppIcon.appiconset" / "1024.png"
PNG = OUT / "wealth-map-reddit-flyer.png"

W, H = 1080, 1350
INK = "#18211f"
MUTED = "#61706b"
GOLD = "#b37f12"
GOLD_2 = "#f4b33d"
MINT = "#74d687"
TEAL = "#5fae8c"
PAPER = "#fffdf7"
LINE = "#dfe7e2"


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
    "meta": font(24, True),
    "badge": font(22, True),
    "eyebrow": font(22, True),
    "h1": font(70, True),
    "sub": font(27, True),
    "feature": font(22, True),
    "small": font(16, True),
    "label": font(17, True),
    "amount": font(50, True),
    "metric": font(26, True),
    "footer": font(31, True),
    "footer_small": font(21, True),
    "url": font(20, True),
}


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def vertical_gradient(top: str, bottom: str, size: tuple[int, int]) -> Image.Image:
    w, h = size
    a = hex_to_rgb(top)
    b = hex_to_rgb(bottom)
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        color = tuple(lerp(a[i], b[i], t) for i in range(3))
        for x in range(w):
            px[x, y] = color
    return img.convert("RGBA")


def glow(base: Image.Image, center: tuple[int, int], radius: int, color: str, alpha: int) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = center
    d.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*hex_to_rgb(color), alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    base.alpha_composite(layer)


def rounded_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int, fill: str, shadow_alpha: int = 35, offset: tuple[int, int] = (0, 14), blur: int = 24, outline: str | None = None, width: int = 1) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    x0, y0, x1, y1 = box
    ox, oy = offset
    sd.rounded_rectangle((x0 + ox, y0 + oy, x1 + ox, y1 + oy), radius=radius, fill=(24, 33, 31, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow)
    d = ImageDraw.Draw(base)
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font_obj: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textbbox((0, 0), trial, font=font_obj)[2] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_multiline(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, font_obj: ImageFont.FreeTypeFont, fill: str, max_width: int, line_gap: int = 8) -> int:
    x, y = xy
    for line in wrap_text(draw, text, font_obj, max_width):
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += draw.textbbox((0, 0), line, font=font_obj)[3] + line_gap
    return y


def paste_icon(base: Image.Image) -> None:
    icon = Image.open(ICON).convert("RGBA").resize((88, 88), Image.Resampling.LANCZOS)
    rounded_shadow(base, (72, 64, 176, 168), 27, "#ffffff", shadow_alpha=28, offset=(0, 16), blur=30)
    base.alpha_composite(icon, (80, 72))


def draw_check(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    draw.rounded_rectangle((x, y, x + 36, y + 36), radius=12, fill=TEAL)
    draw.line((x + 10, y + 19, x + 17, y + 27, x + 28, y + 10), fill="#ffffff", width=6, joint="curve")


def draw_phone(base: Image.Image) -> None:
    phone_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(phone_layer)
    x, y, w, h = 676, 330, 316, 660

    # Shadow and phone shell.
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x - 8, y + 32, x + w + 8, y + h + 38), radius=62, fill=(24, 33, 31, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    phone_layer.alpha_composite(shadow)
    d.rounded_rectangle((x, y, x + w, y + h), radius=58, fill="#111816")
    d.rounded_rectangle((x + 13, y + 13, x + w - 13, y + h - 13), radius=43, fill="#fbfdfb", outline="#ffffff", width=2)

    sx, sy = x + 34, y + 42
    d.text((sx, sy), "Dashboard", font=F["meta"], fill="#42534e")
    d.rounded_rectangle((x + w - 104, sy - 4, x + w - 35, sy + 28), radius=16, fill="#eaf6ed")
    d.text((x + w - 94, sy + 1), "Synced", font=font(14, True), fill="#477a58")

    d.text((sx, sy + 70), "NET WORTH", font=F["label"], fill="#83958f")
    d.text((sx, sy + 102), "$428.6K", font=F["amount"], fill=INK)
    d.rounded_rectangle((sx, sy + 164, sx + 154, sy + 197), radius=17, fill="#fff0cc")
    d.polygon([(sx + 14, sy + 185), (sx + 20, sy + 173), (sx + 26, sy + 185)], fill="#7a560a")
    d.text((sx + 35, sy + 170), "4.8% this month", font=F["small"], fill="#6b4a05")

    chart = (sx - 4, sy + 214, x + w - 34, sy + 344)
    d.rounded_rectangle(chart, radius=28, fill="#edf8f0", outline="#dbe9e1")
    points = [(chart[0] + i, chart[3] - 34 - (math.sin(i / 38) * 9 + i * 0.22)) for i in range(0, chart[2] - chart[0], 7)]
    poly = points + [(chart[2], chart[3]), (chart[0], chart[3])]
    d.polygon(poly, fill="#cef1d6")
    d.line(points, fill="#51a56f", width=8, joint="curve")
    d.ellipse((chart[2] - 72, chart[1] + 44, chart[2] - 54, chart[1] + 62), fill=GOLD)

    cards_y = sy + 368
    for i, (label, value) in enumerate((("ASSETS", "$512K"), ("LIABILITIES", "$83K"))):
        cx = sx + i * 136
        d.rounded_rectangle((cx, cards_y, cx + 118, cards_y + 96), radius=23, fill="#ffffff", outline="#dfeae4", width=2)
        d.text((cx + 17, cards_y + 19), label, font=F["small"], fill="#7f918a")
        d.text((cx + 17, cards_y + 57), value, font=font(24, True), fill=INK)

    list_y = cards_y + 116
    d.rounded_rectangle((sx - 2, list_y, x + w - 34, list_y + 156), radius=28, fill="#ffffff", outline="#dfeae4", width=2)
    rows = [("$", "USD", "Base currency", "$428.6K"), ("INR", "INR", "Display total", "3.58Cr"), ("EUR", "EUR", "Display total", "397K")]
    for i, (coin, code, subtitle, value) in enumerate(rows):
        ry = list_y + 15 + i * 44
        d.rounded_rectangle((sx + 12, ry, sx + 46, ry + 34), radius=14, fill="#f6cf70")
        coin_text = coin if len(coin) == 1 else coin[:1]
        d.text((sx + 23 - len(coin_text) * 4, ry + 7), coin_text, font=font(14, True), fill="#5f4107")
        d.text((sx + 57, ry), code, font=font(14, True), fill=INK)
        d.text((sx + 57, ry + 19), subtitle, font=font(11, True), fill="#87958f")
        d.text((x + w - 94, ry + 6), value, font=font(13, True), fill=INK)

    # Floating widget card.
    rounded_shadow(phone_layer, (616, 950, 835, 1064), 28, "#ffffff", shadow_alpha=28, offset=(0, 16), blur=22, outline="#dfe7e2")
    d.text((636, 974), "Widget-ready", font=F["small"], fill="#73847e")
    d.text((636, 1003), "Home + Lock", font=font(26, True), fill=INK)
    d.text((636, 1035), "Screen", font=font(26, True), fill=INK)

    # Rotate as one object for a little motion.
    crop = phone_layer.crop((590, 285, 1050, 1110))
    crop = crop.rotate(2.5, resample=Image.Resampling.BICUBIC, expand=True)
    base.alpha_composite(crop, (590, 285))


def main() -> None:
    img = vertical_gradient("#ffffff", "#f7fbf5", (W, H))
    glow(img, (906, 156), 245, "#74d687", 80)
    glow(img, (110, 1180), 290, "#b37f12", 42)
    d = ImageDraw.Draw(img)

    paste_icon(img)
    d.text((204, 78), "Wealth Map", font=F["brand"], fill=INK)
    d.text((205, 128), "Finance app | Free", font=F["meta"], fill=MUTED)
    d.rounded_rectangle((752, 78, 1014, 136), radius=29, fill="#fffdf7", outline="#e5c57d", width=1)
    d.text((789, 95), "Available on App Store", font=F["badge"], fill="#704c05")

    d.rounded_rectangle((72, 332, 522, 402), radius=35, fill="#fff1c7", outline="#e9c979", width=1)
    d.ellipse((94, 364, 104, 374), fill=GOLD)
    draw_multiline(d, (118, 350), "Built for assets, debts, metals, and currencies", F["eyebrow"], "#6b4a05", 355, 2)

    y = 458
    y = draw_multiline(d, (72, y), "Map your true net worth.", F["h1"], INK, 510, 5)
    y += 20
    y = draw_multiline(d, (72, y), "Track what you own, what you owe, and how it changes across currencies in one focused app.", F["sub"], "#42504c", 500, 6)
    y += 22

    features = [
        "Assets and liabilities across global currencies",
        "Gold, silver, platinum, palladium, and rhodium spot prices",
        "Portfolio history, reminders, insights, rates, and widgets",
        "Clean, private, no account required; optional iCloud sync",
    ]
    for text in features:
        draw_check(d, 72, y + 5)
        y = draw_multiline(d, (124, y), text, F["feature"], "#22302c", 470, 3) + 13

    draw_phone(img)

    d.line((72, 1190, 1008, 1190), fill=(126, 142, 136, 70), width=1)
    draw_multiline(d, (72, 1218), "Download it, critique it, or share feedback.", F["footer"], INK, 510, 4)
    d.text((72, 1291), "Personal net worth tracking for iPhone and iPad.", font=F["footer_small"], fill=MUTED)
    d.text((755, 1226), "APP STORE", font=font(16, True), fill="#6a4a08")
    d.rounded_rectangle((618, 1256, 1008, 1308), radius=18, fill="#ffffff", outline=LINE, width=1)
    d.text((670, 1273), "Search: Wealth Map", font=F["url"], fill=INK)

    img.convert("RGB").save(PNG, quality=96)
    print(PNG)


if __name__ == "__main__":
    main()
