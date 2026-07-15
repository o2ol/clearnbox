#!/usr/bin/env python3
"""Generate CleanBox app icons: teal broom/spark on dark rounded square."""
from __future__ import annotations
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Resources"
RES.mkdir(exist_ok=True)

def png_chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

def write_png(path: Path, rgba: list[tuple[int, int, int, int]], w: int, h: int) -> None:
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            r, g, b, a = rgba[y * w + x]
            raw.extend((r, g, b, a))
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    data = b"".join([
        b"\x89PNG\r\n\x1a\n",
        png_chunk(b"IHDR", ihdr),
        png_chunk(b"IDAT", zlib.compress(bytes(raw), 9)),
        png_chunk(b"IEND", b""),
    ])
    path.write_bytes(data)

def lerp(a, b, t):
    return a + (b - a) * t

def pix(x, y, size):
    # normalized -1..1
    nx = (x + 0.5) / size * 2 - 1
    ny = (y + 0.5) / size * 2 - 1
    # rounded rect mask
    ax, ay = abs(nx), abs(ny)
    # squircle-ish
    corner = 0.78
    inside = (ax ** 4 + ay ** 4) <= (corner ** 4) * 1.15
    if not inside:
        # soft edge
        d = (ax ** 4 + ay ** 4) ** 0.25 - corner
        if d > 0.08:
            return (0, 0, 0, 0)
        alpha = int(max(0, 1 - d / 0.08) * 255)
    else:
        alpha = 255

    # background gradient teal
    t = (ny + 1) * 0.5
    r = int(lerp(18, 10, t))
    g = int(lerp(120, 90, t))
    b = int(lerp(140, 110, t))
    # brighter center
    dist = math.sqrt(nx * nx + ny * ny)
    glow = max(0, 1 - dist * 1.2)
    r = min(255, int(r + 40 * glow))
    g = min(255, int(g + 70 * glow))
    b = min(255, int(b + 50 * glow))

    # broom body (vertical rounded rect)
    if abs(nx + 0.05) < 0.07 and -0.55 < ny < 0.25:
        r, g, b = 240, 248, 255
    # broom head (horizontal ellipse-ish)
    if (nx + 0.05) ** 2 / 0.28 ** 2 + (ny - 0.35) ** 2 / 0.14 ** 2 <= 1:
        r, g, b = 120, 255, 210
    # bristle lines
    if abs(ny - 0.35) < 0.12 and abs(nx + 0.05) < 0.26:
        if int((nx + 1) * 40) % 3 == 0:
            r, g, b = 40, 180, 150
    # sparkles
    for sx, sy, rad in [(-0.45, -0.4, 0.05), (0.4, -0.25, 0.04), (0.35, 0.45, 0.035)]:
        if (nx - sx) ** 2 + (ny - sy) ** 2 <= rad ** 2:
            r, g, b = 255, 255, 200
    return (r, g, b, alpha)

def render(size: int):
    return [pix(x, y, size) for y in range(size) for x in range(size)]

def main():
    master = render(1024)
    write_png(ROOT / "icon_master_1024.png", master, 1024, 1024)
    sizes = {
        "AppIcon29x29.png": 29,
        "AppIcon29x29@2x.png": 58,
        "AppIcon29x29@3x.png": 87,
        "AppIcon40x40.png": 40,
        "AppIcon40x40@2x.png": 80,
        "AppIcon40x40@3x.png": 120,
        "AppIcon50x50.png": 50,
        "AppIcon50x50@2x.png": 100,
        "AppIcon57x57.png": 57,
        "AppIcon57x57@2x.png": 114,
        "AppIcon57x57@3x.png": 171,
        "AppIcon60x60.png": 60,
        "AppIcon60x60@2x.png": 120,
        "AppIcon60x60@3x.png": 180,
        "AppIcon72x72.png": 72,
        "AppIcon72x72@2x.png": 144,
        "AppIcon76x76.png": 76,
        "AppIcon76x76@2x.png": 152,
    }
    for name, s in sizes.items():
        write_png(RES / name, render(s), s, s)
        print("wrote", name, s)
    print("done")

if __name__ == "__main__":
    main()
