import os
from PIL import Image, ImageEnhance

SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"

# (name, x0,y0,x1,y1) 比例
regions = {
    "14_stamp": (0.02, 0.30, 0.60, 0.55),
    "14_radon": (0.50, 0.36, 1.00, 0.62),
    "14_bottomright": (0.50, 0.75, 1.00, 1.00),
}
for n in [14]:
    im = Image.open(os.path.join(SRC, f"{n}.png")).convert("L")
    w, h = im.size
    for name, (a, b, c, d) in regions.items():
        crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
        crop = crop.resize((crop.width*7, crop.height*7), Image.LANCZOS)
        crop = ImageEnhance.Contrast(crop).enhance(1.7)
        crop.save(os.path.join(OUT, f"{name}.png"))
print("ok")
