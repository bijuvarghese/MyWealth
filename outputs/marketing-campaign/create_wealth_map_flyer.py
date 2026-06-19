from pathlib import Path
import textwrap

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/bijuvarghese/Projects/MyWealth-101/iOS/MyWealth")
OUT = ROOT / "outputs" / "marketing-campaign"
DESKTOP = Path("/Users/bijuvarghese/Desktop")

SCREENSHOTS = {
    "briefing": DESKTOP / "Simulator Screenshot - iPhone 17 Pro - 2026-06-12 at 00.52.27.png",
    "rates": DESKTOP / "Simulator Screenshot - iPhone 17 Pro - 2026-06-12 at 00.52.35.png",
    "global_net_worth": DESKTOP / "Simulator Screenshot - iPhone 17 Pro - 2026-06-12 at 00.52.42.png",
    "dashboard": DESKTOP / "Simulator Screenshot - iPhone 17 Pro - 2026-06-12 at 00.56.10.png",
    "fire": DESKTOP / "Simulator Screenshot - iPhone 17 Pro - 2026-06-12 at 00.56.16.png",
}

FONT_DIR = Path("/System/Library/Fonts/Supplemental")
FONT_BOLD = FONT_DIR / "Arial Bold.ttf"
FONT_REG = FONT_DIR / "Arial.ttf"


def font(size, bold=False):
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REG), size)


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def add_shadow(base, layer, xy, blur=40, offset=(0, 28), opacity=70):
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    alpha = layer.getchannel("A")
    shadow.putalpha(alpha.point(lambda p: int(p * opacity / 255)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow, (xy[0] + offset[0], xy[1] + offset[1]))
    base.alpha_composite(layer, xy)


def screen_card(path, width, radius=82, border=18):
    src = Image.open(path).convert("RGBA")
    height = round(src.height * width / src.width)
    screen = src.resize((width, height), Image.Resampling.LANCZOS)

    card = Image.new("RGBA", (width + border * 2, height + border * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle(
        (0, 0, card.width - 1, card.height - 1),
        radius=radius + border,
        fill=(18, 18, 18, 255),
    )
    inner = Image.new("RGBA", screen.size, (0, 0, 0, 0))
    inner.alpha_composite(screen)
    inner.putalpha(rounded_mask(screen.size, radius))
    card.alpha_composite(inner, (border, border))
    return card


def rotate_layer(layer, angle):
    return layer.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)


def draw_text_box(draw, xy, text, font_obj, fill, width_chars, line_gap=12):
    x, y = xy
    for line in textwrap.wrap(text, width=width_chars):
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += font_obj.getbbox(line)[3] - font_obj.getbbox(line)[1] + line_gap
    return y


def draw_pill(draw, xy, text, text_font, fill, outline, text_fill, pad_x=34, pad_y=18):
    x, y = xy
    bbox = draw.textbbox((0, 0), text, font=text_font)
    w = bbox[2] - bbox[0] + pad_x * 2
    h = bbox[3] - bbox[1] + pad_y * 2
    draw.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=fill, outline=outline, width=3)
    draw.text((x + pad_x, y + pad_y - 2), text, font=text_font, fill=text_fill)
    return (x + w, y + h)


def create_flyer():
    OUT.mkdir(parents=True, exist_ok=True)

    W, H = 2550, 3300
    bg = Image.new("RGBA", (W, H), (255, 252, 248, 255))
    draw = ImageDraw.Draw(bg)

    # Dotted map-like field, matching the app's visual language but quieter for print.
    dot_color = (176, 0, 155, 72)
    for y in range(28, H, 82):
        for x in range(22, W, 82):
            draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=dot_color)

    # Warm and clean editorial backdrop.
    draw.rounded_rectangle((132, 168, 2408, 3130), radius=110, fill=(255, 255, 255, 236))
    draw.rounded_rectangle((132, 168, 2408, 3130), radius=110, outline=(232, 214, 178, 150), width=4)
    draw.ellipse((1390, -360, 3100, 1120), fill=(255, 202, 62, 42))
    draw.ellipse((-380, 2160, 1060, 3680), fill=(255, 139, 38, 38))

    gold = (184, 132, 3, 255)
    orange = (255, 139, 38, 255)
    black = (7, 7, 8, 255)
    gray = (112, 112, 118, 255)

    # Header and campaign copy.
    draw_pill(
        draw,
        (255, 305),
        "MY WEALTH MAP",
        font(42, True),
        fill=(255, 246, 225, 255),
        outline=(222, 198, 150, 255),
        text_fill=gold,
        pad_x=42,
        pad_y=22,
    )
    draw.text((250, 475), "See your money", font=font(154, True), fill=black)
    draw.text((250, 635), "clearly", font=font(154, True), fill=black)
    draw_text_box(
        draw,
        (258, 850),
        "Track assets, global net worth, live rates, portfolio health, and FIRE goals in one focused wealth map.",
        font(54),
        fill=gray,
        width_chars=27,
        line_gap=18,
    )

    # CTA block.
    draw.rounded_rectangle((258, 1208, 1048, 1368), radius=80, fill=black)
    draw.text((325, 1251), "Build your map today", font=font(54, True), fill=(255, 255, 255, 255))
    draw_text_box(
        draw,
        (258, 1430),
        "Designed for investors who want context, not clutter.",
        font(39),
        fill=gray,
        width_chars=34,
        line_gap=10,
    )

    feature_y = 1598
    features = [
        ("Portfolio health", orange),
        ("Global comfort", (0, 143, 255, 255)),
        ("Transfer rates", gold),
        ("FIRE planning", (53, 199, 89, 255)),
    ]
    for label, color in features:
        draw.ellipse((270, feature_y + 12, 306, feature_y + 48), fill=color)
        draw.text((335, feature_y), label, font=font(44, True), fill=black)
        feature_y += 88

    # Screen collage.
    small_w = 450
    medium_w = 510
    hero_w = 760

    global_card = rotate_layer(screen_card(SCREENSHOTS["global_net_worth"], small_w), -9)
    rates_card = rotate_layer(screen_card(SCREENSHOTS["rates"], small_w), 8)
    briefing_card = rotate_layer(screen_card(SCREENSHOTS["briefing"], medium_w), -5)
    fire_card = rotate_layer(screen_card(SCREENSHOTS["fire"], small_w), 6)
    dashboard_card = screen_card(SCREENSHOTS["dashboard"], hero_w, radius=96, border=22)

    add_shadow(bg, global_card, (1410, 600), blur=34, offset=(0, 28), opacity=58)
    add_shadow(bg, rates_card, (1810, 760), blur=34, offset=(0, 28), opacity=55)
    add_shadow(bg, briefing_card, (880, 1480), blur=42, offset=(0, 32), opacity=58)
    add_shadow(bg, fire_card, (1830, 1775), blur=34, offset=(0, 28), opacity=54)
    add_shadow(bg, dashboard_card, (1085, 820), blur=58, offset=(0, 42), opacity=88)

    # Bottom strip.
    draw.rounded_rectangle((260, 2765, 2290, 2990), radius=72, fill=(255, 246, 225, 255))
    draw.text((340, 2820), "Dashboard + AI briefing + global rates + FIRE target", font=font(55, True), fill=black)
    draw.text((340, 2894), "A calmer command center for everyday wealth decisions.", font=font(42), fill=gray)

    # Small brand mark.
    draw.rounded_rectangle((1965, 2855, 2198, 2932), radius=38, fill=gold)
    draw.text((2015, 2872), "MWM", font=font(34, True), fill=(255, 255, 255, 255))

    png_path = OUT / "my-wealth-map-campaign-flyer.png"
    pdf_path = OUT / "my-wealth-map-campaign-flyer.pdf"
    bg.convert("RGB").save(png_path, quality=96)
    bg.convert("RGB").save(pdf_path, resolution=300.0)
    return png_path, pdf_path


if __name__ == "__main__":
    png, pdf = create_flyer()
    print(png)
    print(pdf)
