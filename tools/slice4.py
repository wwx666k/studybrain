import os
from PIL import Image, ImageEnhance
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
for n in [16, 17, 18, 19]:
    im = Image.open(os.path.join(SRC, f"{n}.png")).convert("L")
    w, h = im.size
    cols = {"L": (0.0, 0.55), "R": (0.45, 1.0)}
    rows = [(0.0, 0.37), (0.33, 0.70), (0.66, 1.0)]
    for ctag, (a, c) in cols.items():
        for ri, (b, d) in enumerate(rows):
            crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
            crop = crop.resize((crop.width*6, crop.height*6), Image.LANCZOS)
            crop = ImageEnhance.Contrast(crop).enhance(1.7)
            crop.save(os.path.join(OUT, f"{n}_{ctag}{ri}.png"))
print("ok")
