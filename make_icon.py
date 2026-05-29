#!/usr/bin/env python3
"""Generate DiskLeaner.icns from a programmatic 1024x1024 source image."""

import math, os, shutil, subprocess
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def make_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size

    # ── Background: deep blue-to-purple radial-ish gradient via layered circles ──
    for i in range(s // 2, 0, -1):
        t = i / (s / 2)
        r = int(30 + t * (15 - 30))
        g = int(120 + t * (60 - 120))
        b = int(240 + t * (180 - 240))
        alpha = 255
        offset = (s // 2) - i
        d.ellipse([offset, offset, s - offset, s - offset], fill=(r, g, b, alpha))

    # Rounded rect mask (macOS icon shape ~22% corner radius)
    mask = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(mask)
    r_corner = int(s * 0.225)
    md.rounded_rectangle([0, 0, s - 1, s - 1], radius=r_corner, fill=255)
    img.putalpha(mask)

    # ── Hard-drive platter: two concentric rings ──
    cx, cy = s / 2, s / 2
    outer_r = s * 0.30
    inner_r = s * 0.10
    ring_w  = s * 0.045

    # Outer ring
    d.ellipse(
        [cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
        outline=(255, 255, 255, 200), width=int(ring_w)
    )
    # Inner ring
    d.ellipse(
        [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
        outline=(255, 255, 255, 160), width=int(ring_w * 0.7)
    )
    # Centre dot
    dot_r = s * 0.045
    d.ellipse(
        [cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r],
        fill=(255, 255, 255, 220)
    )

    # ── Sparkle / clean indicator (top-right quadrant) ──
    # Four-pointed star
    sx, sy = cx + s * 0.19, cy - s * 0.19
    star_r_long = s * 0.115
    star_r_short = s * 0.038
    points = []
    for i in range(8):
        angle = math.radians(i * 45 - 90)
        r = star_r_long if i % 2 == 0 else star_r_short
        points.append((sx + r * math.cos(angle), sy + r * math.sin(angle)))
    d.polygon(points, fill=(255, 255, 180, 240))

    # Small dot accents around the star
    for angle_deg, dist, dot_size in [(45, 0.16, 0.018), (10, 0.22, 0.012), (80, 0.20, 0.010)]:
        angle = math.radians(angle_deg)
        px = cx + s * dist * math.cos(angle)
        py = cy - s * dist * math.sin(angle)
        dr = s * dot_size
        d.ellipse([px - dr, py - dr, px + dr, py + dr], fill=(255, 255, 200, 200))

    # Slight glow around star
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gr = star_r_long * 1.4
    gd.ellipse([sx - gr, sy - gr, sx + gr, sy + gr], fill=(255, 240, 100, 60))
    img = Image.alpha_composite(img, glow)

    # Re-apply rounded rect mask after compositing
    img.putalpha(mask)

    return img


def build_iconset(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    specs = [
        ("icon_16x16.png",       16),
        ("icon_16x16@2x.png",    32),
        ("icon_32x32.png",       32),
        ("icon_32x32@2x.png",    64),
        ("icon_128x128.png",    128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png",    256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png",    512),
        ("icon_512x512@2x.png",1024),
    ]
    base = make_icon(1024)
    for filename, size in specs:
        resized = base.resize((size, size), Image.LANCZOS)
        resized.save(os.path.join(out_dir, filename))
        print(f"  {filename}")


if __name__ == "__main__":
    iconset_dir = "/Users/jophie/Dev/repo/diskleaner/DiskLeaner.iconset"
    icns_path   = "/Users/jophie/Dev/repo/diskleaner/Sources/DiskLeaner/Resources/AppIcon.icns"

    os.makedirs(os.path.dirname(icns_path), exist_ok=True)

    print("Generating icon sizes…")
    build_iconset(iconset_dir)

    print("Packaging into .icns…")
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)

    shutil.rmtree(iconset_dir)
    print(f"Done → {icns_path}")
