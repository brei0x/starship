#!/usr/bin/env python3
"""Renders ANSI truecolor text from stdin as an SVG terminal window on stdout, one cell per code point.

Usage: prompt-svg.py --font "JetBrainsMono Nerd Font" > out.svg
"""
import argparse
import re
import sys
from xml.sax.saxutils import escape

FONT_SIZE = 14
CELL_WIDTH = 0.6 * FONT_SIZE  # JetBrains Mono advance, icons included
LINE_PITCH = 1.32 * FONT_SIZE
GLYPH_ABOVE = 1.027 * FONT_SIZE  # powerline glyph box of the Nerd Font, yMax 1027 / yMin -307 per 1000 UPM
GLYPH_BELOW = 0.307 * FONT_SIZE
MARGIN, PADDING, TITLE_BAR = 30, 28, 40
BACKGROUND, FOREGROUND = "#282c34", "#abb2bf"
TRAFFIC_LIGHTS = ("#ff5f57", "#febc2e", "#28c840")
SGR = re.compile(r"\x1b\[([\d;]*)m")


def parse(text):
    """Yields (line_index, column, text, fg, bg, bold) runs."""
    fg, bg, bold = None, None, False
    for row, line in enumerate(text.split("\n")):
        col, pos = 0, 0
        for match in SGR.finditer(line):
            chunk = line[pos:match.start()]
            if chunk:
                yield row, col, chunk, fg, bg, bold
                col += len(chunk)
            pos = match.end()
            params = [int(p) for p in match.group(1).split(";") if p]
            while params:
                p = params.pop(0)
                if p == 0:
                    fg, bg, bold = None, None, False
                elif p == 1:
                    bold = True
                elif p == 22:
                    bold = False
                elif p == 39:
                    fg = None
                elif p == 49:
                    bg = None
                elif p in (38, 48) and params[:1] == [2]:
                    color = "#%02x%02x%02x" % tuple(params[1:4])
                    fg, bg = (color, bg) if p == 38 else (fg, color)
                    del params[:4]
        chunk = line[pos:]
        if chunk:
            yield row, col, chunk, fg, bg, bold


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", required=True)
    font = parser.parse_args().font
    text = sys.stdin.read().rstrip("\n")
    rows = text.count("\n") + 1
    x0 = MARGIN + PADDING
    baseline0 = MARGIN + TITLE_BAR + PADDING + GLYPH_ABOVE
    height = MARGIN + TITLE_BAR + PADDING + rows * LINE_PITCH + PADDING + MARGIN
    runs = list(parse(text))
    columns = max(col + len(chunk) for _, col, chunk, *_ in runs)
    window_width = round(2 * PADDING + columns * CELL_WIDTH)  # the window hugs the widest line
    rects, texts = [], []
    for row, col, chunk, fg, bg, bold in runs:
        x = x0 + col * CELL_WIDTH
        baseline = baseline0 + row * LINE_PITCH
        if bg:
            rects.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"/>'
                         % (x, baseline - GLYPH_ABOVE, len(chunk) * CELL_WIDTH, GLYPH_ABOVE + GLYPH_BELOW, bg))
        weight = ' font-weight="700"' if bold else ""
        texts.append('<text x="%.2f" y="%.2f" fill="%s"%s>%s</text>' % (x, baseline, fg or FOREGROUND, weight, escape(chunk)))
    lights = "".join('<circle cx="%d" cy="%d" r="6" fill="%s"/>' % (MARGIN + 20 + i * 20, MARGIN + 20, c)
                     for i, c in enumerate(TRAFFIC_LIGHTS))
    print('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%.0f" viewBox="0 0 %d %.0f">'
          % (window_width + 2 * MARGIN, height, window_width + 2 * MARGIN, height))
    print('<defs><filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">'
          '<feDropShadow dx="0" dy="12" stdDeviation="10" flood-opacity="0.45"/></filter></defs>')
    print('<rect x="%d" y="%d" width="%d" height="%.0f" rx="10" fill="%s" filter="url(#shadow)"/>'
          % (MARGIN, MARGIN, window_width, height - 2 * MARGIN, BACKGROUND))
    print(lights)
    print("\n".join(rects))
    print('<g font-family="%s" font-size="%d" xml:space="preserve">' % (escape(font), FONT_SIZE))
    print("\n".join(texts))
    print("</g></svg>")


if __name__ == "__main__":
    main()
