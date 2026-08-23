"""Generates the N'Ko Kalan app icon (background + foreground + flattened) using Pillow.
Run: python generate_icon.py
Outputs: icon_bg.png, icon_fg.png, icon.png (all 1024x1024) in this directory.
"""
from PIL import Image, ImageDraw
import math
import os

SS = 4  # supersampling factor
SIZE = 1024
BIG = SIZE * SS

INDIGO = (44, 58, 99, 255)      # 0xFF2C3A63
INDIGO_DARK = (30, 42, 72, 255) # 0xFF1E2A48
GOLD = (199, 154, 62, 255)      # 0xFFC79A3E
GOLD_LIGHT = (222, 184, 108, 255)
CLAY = (156, 66, 34, 255)       # 0xFF9C4222
CREAM = (255, 251, 241, 255)    # 0xFFFFFBF1


def cubic_bezier(p0, p1, p2, p3, steps=60):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        mt = 1 - t
        x = (mt**3) * p0[0] + 3 * (mt**2) * t * p1[0] + 3 * mt * (t**2) * p2[0] + (t**3) * p3[0]
        y = (mt**3) * p0[1] + 3 * (mt**2) * t * p1[1] + 3 * mt * (t**2) * p2[1] + (t**3) * p3[1]
        pts.append((x, y))
    return pts


def make_background():
    img = Image.new("RGBA", (BIG, BIG), INDIGO)
    draw = ImageDraw.Draw(img)
    # subtle radial-ish vignette using concentric circles from dark to light indigo
    cx, cy = BIG / 2, BIG * 0.42
    max_r = BIG * 0.95
    steps = 60
    for i in range(steps, 0, -1):
        t = i / steps
        r = max_r * t
        col = tuple(
            int(INDIGO_DARK[c] + (INDIGO[c] - INDIGO_DARK[c]) * (1 - t))
            for c in range(3)
        ) + (255,)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    return img


def tapered_stroke(draw, centerline, widths, fill):
    """Builds a variable-width ribbon polygon along a centerline and fills it."""
    n = len(centerline)
    left_side = []
    right_side = []
    for i in range(n):
        x, y = centerline[i]
        if i == 0:
            dx, dy = centerline[i + 1][0] - x, centerline[i + 1][1] - y
        elif i == n - 1:
            dx, dy = x - centerline[i - 1][0], y - centerline[i - 1][1]
        else:
            dx = centerline[i + 1][0] - centerline[i - 1][0]
            dy = centerline[i + 1][1] - centerline[i - 1][1]
        length = math.hypot(dx, dy) or 1
        nx, ny = -dy / length, dx / length
        w = widths[i] / 2
        left_side.append((x + nx * w, y + ny * w))
        right_side.append((x - nx * w, y - ny * w))
    poly = left_side + right_side[::-1]
    draw.polygon(poly, fill=fill)


def make_foreground():
    img = Image.new("RGBA", (BIG, BIG), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = BIG / 2, BIG / 2

    # Scale: safe zone ~66% of icon size for adaptive icons
    s = BIG * 0.34  # base unit

    # --- Calligraphic hook stroke, evoking N'Ko's flowing script and
    # its distinctive dotted diacritics, without depicting a specific letter.
    p0 = (cx - s * 0.05, cy + s * 0.68)
    p1 = (cx - s * 0.55, cy + s * 0.55)
    p2 = (cx - s * 0.62, cy - s * 0.05)
    p3 = (cx - s * 0.10, cy - s * 0.10)
    lower = cubic_bezier(p0, p1, p2, p3, 60)

    q0 = p3
    q1 = (cx + s * 0.30, cy - s * 0.14)
    q2 = (cx + s * 0.55, cy - s * 0.55)
    q3 = (cx + s * 0.40, cy - s * 0.78)
    upper = cubic_bezier(q0, q1, q2, q3, 60)

    centerline = lower + upper[1:]

    dot_r = s * 0.125
    dot_c = (q3[0] + s * 0.09, q3[1] - s * 0.30)

    # Recenter the whole mark (stroke + dot) on the canvas so its visual
    # centroid sits in the middle of the safe zone.
    all_x = [p[0] for p in centerline] + [dot_c[0] - dot_r, dot_c[0] + dot_r]
    all_y = [p[1] for p in centerline] + [dot_c[1] - dot_r, dot_c[1] + dot_r]
    min_x, max_x = min(all_x), max(all_x)
    min_y, max_y = min(all_y), max(all_y)
    mid_x, mid_y = (min_x + max_x) / 2, (min_y + max_y) / 2
    off_x, off_y = cx - mid_x, cy - mid_y
    centerline = [(x + off_x, y + off_y) for x, y in centerline]
    dot_c = (dot_c[0] + off_x, dot_c[1] + off_y)

    n = len(centerline)
    widths = []
    for i in range(n):
        t = i / (n - 1)
        # thick through the belly of the hook, tapering to fine points at both ends
        base = math.sin(t * math.pi) ** 1.15
        widths.append(s * (0.02 + 0.34 * base))

    # Badge ring framing the mark
    ring_r = s * 1.28
    ring_w = s * 0.045
    draw.ellipse(
        [cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r],
        outline=GOLD,
        width=int(ring_w),
    )

    tapered_stroke(draw, centerline, widths, GOLD)

    # Subtle lighter core along the stroke for depth
    inner_widths = [w * 0.45 for w in widths]
    tapered_stroke(draw, centerline, inner_widths, GOLD_LIGHT)

    # Dot accent above the hook's upper tip, echoing N'Ko's circular
    # diacritic marks (e.g. the nasalisation dot).
    draw.ellipse(
        [dot_c[0] - dot_r, dot_c[1] - dot_r, dot_c[0] + dot_r, dot_c[1] + dot_r],
        fill=CLAY,
    )

    return img


def flatten(bg, fg):
    out = bg.copy()
    out.alpha_composite(fg)
    return out


def downsample(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    bg = make_background()
    fg = make_foreground()
    flat = flatten(bg, fg)

    downsample(bg).convert("RGBA").save(os.path.join(out_dir, "icon_bg.png"))
    downsample(fg).save(os.path.join(out_dir, "icon_fg.png"))
    downsample(flat).convert("RGB").save(os.path.join(out_dir, "icon.png"))
    print("Icon assets written to", out_dir)


if __name__ == "__main__":
    main()
