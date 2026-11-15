import sys, os
from PIL import Image, ImageEnhance, ImageFilter

SRC = r"D:\StudyBrain\tools\_src"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)

# usage: bands.py name [scale]
name = sys.argv[1]
scale = float(sys.argv[2]) if len(sys.argv) > 2 else 6.0

im = Image.open(os.path.join(SRC, name)).convert("L")
W, H = im.size
tag = os.path.splitext(name)[0]
cols = [(0.0, 0.58), (0.42, 1.0)]
bands = [(0.0, 0.38), (0.31, 0.69), (0.62, 1.0)]
for ci, (cx0, cx1) in enumerate(cols):
    for bi, (by0, by1) in enumerate(bands):
        box = (int(W * cx0), int(H * by0), int(W * cx1), int(H * by1))
        c = im.crop(box)
        c = c.resize((int(c.width * scale), int(c.height * scale)), Image.LANCZOS)
        c = ImageEnhance.Contrast(c).enhance(1.55)
        c = c.filter(ImageFilter.UnsharpMask(radius=2, percent=130, threshold=2))
        fp = os.path.join(OUT, f"{tag}_b{ci}{bi}.png")
        c.save(fp)
        print(fp, c.size)
