#!/usr/bin/env python3
"""Draw the launcher icon and splash mark for ذكر المسلم."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "brand"
FONT = ROOT / "assets" / "fonts" / "Amiri-Bold.ttf"

GREEN_DEEP = "#06261E"
GREEN = "#0E6B4F"
GOLD = "#D4B06A"
GOLD_DEEP = "#B08948"
CREAM = "#F6F1E7"


def draw_mark(canvas, cx, cy, radius):
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=GREEN)
    outer = max(4, int(radius * 0.045))
    inset = int(radius * 0.07)
    draw.ellipse(
        (
            cx - radius + inset,
            cy - radius + inset,
            cx + radius - inset,
            cy + radius - inset,
        ),
        outline=GOLD,
        width=outer,
    )
    inner = int(radius * 0.15)
    draw.ellipse(
        (
            cx - radius + inner,
            cy - radius + inner,
            cx + radius - inner,
            cy + radius - inner,
        ),
        outline=GOLD_DEEP,
        width=max(2, outer // 2),
    )
    font = ImageFont.truetype(str(FONT), int(radius * 0.72))
    text = "ذكر"
    bbox = draw.textbbox((0, 0), text, font=font, direction="rtl", language="ar")
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    draw.text(
        (cx - width / 2 - bbox[0], cy - height / 2 - bbox[1] - radius * 0.04),
        text,
        font=font,
        fill=CREAM,
        direction="rtl",
        language="ar",
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)

    icon = Image.new("RGB", (1024, 1024), GREEN_DEEP)
    draw_mark(icon, 512, 512, 390)
    icon.save(OUT / "icon.png", optimize=True)

    foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw_mark(foreground, 512, 512, 300)
    foreground.save(OUT / "icon_foreground.png")

    splash = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    draw_mark(splash, 384, 384, 280)
    splash.save(OUT / "splash_logo.png")

    android12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
    draw_mark(android12, 480, 480, 300)
    android12.save(OUT / "splash_android12.png")
    print(f"wrote brand images in {OUT}")


if __name__ == "__main__":
    main()
