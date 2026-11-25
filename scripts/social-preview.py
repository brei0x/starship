#!/usr/bin/env python3
"""Composes the 1280x640 GitHub social preview from two terminal SVGs made by prompt-svg.py.

Usage: social-preview.py --font "JetBrainsMono Nerd Font" MACOS.svg WINDOWS.svg > social.svg
"""
import argparse
import re
from xml.sax.saxutils import escape

WIDTH, HEIGHT = 1280, 640
RADIUS = WIDTH // 40  # rounded transparent corners, 2.5 % of the width
TITLE_SIZE = 46
TITLE_TRACKING = -0.02 * TITLE_SIZE  # display size wants negative tracking
SCALE = 1.22  # terminal windows, so the prompt stays legible when the card is shown at half size
GRADIENT = ("#4668a6", "#2a3550")  # palette blue to a darker navy
TITLE, SUBTITLE = "Brei0x Starship Theme", "A Powerlevel10k-style prompt for every shell"
BADGES = (("", "macOS"), ("", "Linux"), ("\U000f0372", "Windows"))
INK, SOFT_INK, PILL = "#ffffff", "#c9d3e6", "#28324a"
SIZE = re.compile(r'<svg [^>]*width="(\d+)" height="(\d+)"[^>]*>')


def load(path: str) -> tuple[str, int, int]:
    """A prompt-svg.py document and its native size."""
    with open(path, encoding="utf-8") as file:
        svg = file.read()
    match = SIZE.search(svg)
    if match is None:
        raise SystemExit("%s: not a prompt-svg.py document" % path)
    return svg, int(match.group(1)), int(match.group(2))


def nest(svg: str, w: int, h: int, x: float, y: float) -> str:
    """Places a prompt-svg.py document at (x, y), scaled by SCALE."""
    head = '<svg x="%.1f" y="%.1f" width="%.1f" height="%.1f" viewBox="0 0 %d %d">' % (x, y, w * SCALE, h * SCALE, w, h)
    return SIZE.sub(head, svg, count=1)


def badge_width(label: str) -> int:
    return 44 + 13 * len(label)


def badges(font: str, x: int, y: int) -> str:
    parts = []
    for glyph, label in BADGES:
        width = badge_width(label)
        parts.append('<rect x="%d" y="%d" width="%d" height="36" rx="18" fill="%s"/>' % (x, y, width, PILL))
        parts.append('<text x="%d" y="%d" font-family="%s" font-size="20" fill="%s">%s</text>'
                     % (x + 16, y + 25, escape(font), INK, glyph))
        parts.append('<text x="%d" y="%d" font-family="%s" font-size="19" fill="%s">%s</text>'
                     % (x + 42, y + 25, escape(font), INK, escape(label)))
        x += width + 12
    return "".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", required=True)
    parser.add_argument("macos")
    parser.add_argument("windows")
    args = parser.parse_args()
    font = escape(args.font)
    mac = nest(*load(args.macos), 6, 130)  
    win_svg, win_w, win_h = load(args.windows)
    windows = nest(win_svg, win_w, win_h, WIDTH - win_w * SCALE - 6, HEIGHT - win_h * SCALE + 22)
    print('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (WIDTH, HEIGHT, WIDTH, HEIGHT))
    print('<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
          '<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % GRADIENT
          + '<clipPath id="card"><rect width="%d" height="%d" rx="%d"/></clipPath></defs>' % (WIDTH, HEIGHT, RADIUS))
    print('<g clip-path="url(#card)">')
    print('<rect width="%d" height="%d" fill="url(#bg)"/>' % (WIDTH, HEIGHT))
    print('<text x="48" y="84" font-family="%s" font-size="%d" font-weight="700" letter-spacing="%.2f" fill="%s">%s</text>'
          % (font, TITLE_SIZE, TITLE_TRACKING, INK, escape(TITLE)))
    print('<text x="50" y="124" font-family="%s" font-size="22" fill="%s">%s</text>' % (font, SOFT_INK, escape(SUBTITLE)))
    print(badges(args.font, WIDTH - 48 - sum(badge_width(label) + 12 for _, label in BADGES) + 12, 56))
    print(mac)
    print(windows)
    print("</g></svg>")


if __name__ == "__main__":
    main()
