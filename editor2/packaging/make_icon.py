"""make_icon.py — draws the DWM1 Editor icon (S171): a pixel-art monster egg, cracked,
on a rounded square. Writes editor2/app/icon.png (1024 px, the windows' icon) and
editor2/packaging/AppIcon.icns (the macOS app). Original art; no game graphics.

    python3 editor2/packaging/make_icon.py
"""
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# 24 x 24 egg: . empty, o outline, c cream, h highlight, s shade, g spot, d spot dark, k crack
EGG = [
    "........................",
    "..........oooo..........",
    "........oohhccoo........",
    ".......ohhccccccoo......",
    "......ohhcccggccsso.....",
    ".....ohhccccggdccsso....",
    ".....ohcccccccccccso....",
    "....ohccggcccccccccso...",
    "....ohcgggdccckcccsso...",
    "...ohcccgdcccckkccccso..",
    "...ohccccccccckcckccso..",
    "...ohcccccckkkkcccccsso.",
    "...occcccckcccccggccsso.",
    "...occcccccccccggdcccso.",
    "...occggcccccccccccccso.",
    "...occgddcccccccccccsso.",
    "...osccccccccccccccssso.",
    "....osccccccgcccccsssso.",
    "....ossccccgddccccsssoo.",
    ".....osscccccccccsssso..",
    "......osssccccccsssoo...",
    ".......oossssssssoo.....",
    ".........oooooooo.......",
    "........................",
]
COL = {'o': (40, 28, 52), 'c': (250, 240, 214), 'h': (255, 255, 246), 's': (214, 196, 162),
       'g': (84, 178, 104), 'd': (46, 120, 70), 'k': (90, 60, 50)}


def draw(size=1024):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    # rounded square, vertical gradient (macOS icon grid: 824 px body in 1024)
    body = int(size * 824 / 1024)
    off = (size - body) // 2
    grad = Image.new('RGBA', (body, body))
    gd = ImageDraw.Draw(grad)
    top, bot = (54, 84, 160), (26, 32, 74)
    for y in range(body):
        t = y / (body - 1)
        gd.line([(0, y), (body, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,))
    mask = Image.new('L', (body, body), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, body - 1, body - 1], radius=int(body * 0.225), fill=255)
    img.paste(grad, (off, off), mask)
    # a soft ground ellipse
    d = ImageDraw.Draw(img)
    cx = size // 2
    d.ellipse([cx - body * 0.30, off + body * 0.78, cx + body * 0.30, off + body * 0.88],
              fill=(14, 18, 44, 150))
    # the egg, pixel by pixel
    px = body * 0.80 / 24
    ex = cx - 12 * px
    ey = off + body * 0.06
    rows = [list(r.replace('k', 'c')) for r in EGG]
    # the crack: a zigzag across the shell's upper half (the egg is about to hatch)
    for c, r in ((4, 10), (5, 9), (6, 10), (7, 11), (8, 10), (9, 9), (10, 10), (11, 11),
                 (12, 10), (13, 9), (14, 10), (15, 11), (16, 10), (17, 9), (18, 10), (19, 11)):
        if rows[r][c] in 'chsgd':
            rows[r][c] = 'k'
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch in COL:
                d.rectangle([ex + c * px, ey + r * px, ex + (c + 1) * px - 1, ey + (r + 1) * px - 1],
                            fill=COL[ch] + (255,))
    return img


def main():
    big = draw(1024)
    big.save(os.path.join(ROOT, 'app', 'icon.png'))
    big.save(os.path.join(HERE, 'AppIcon.icns'),
             sizes=[(16, 16), (32, 32), (64, 64), (128, 128), (256, 256), (512, 512), (1024, 1024)])
    print('wrote editor2/app/icon.png and editor2/packaging/AppIcon.icns')


if __name__ == '__main__':
    main()
