import os
from PIL import Image, ImageEnhance

SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
os.makedirs(OUT, exist_ok=True)

for n in [14, 15, 16, 17, 18, 19]:
    p = os.path.join(SRC, f"{n}.png")
    im = Image.open(p).convert("L")
    w, h = im.size
    # 上下两半，各自再左右两栏，各留重叠
    rows = [(0, int(h * 0.53)), (int(h * 0.47), h)]
    cols = [(0, int(w * 0.56)), (int(w * 0.44), w)]
    for ri, (y0, y1) in enumerate(rows):
        for ci, (x0, x1) in enumerate(cols):
            crop = im.crop((x0, y0, x1, y1))
            crop = crop.resize((crop.width * 4, crop.height * 4), Image.LANCZOS)
            crop = ImageEnhance.Contrast(crop).enhance(1.6)
            crop.save(os.path.join(OUT, f"{n}_r{ri}c{ci}.png"))
print("done")
