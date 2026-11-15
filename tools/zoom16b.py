import os
from PIL import Image, ImageEnhance, ImageOps
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "16.png")).convert("L")
w, h = im.size
for tag, (b, d) in {"x": (0.878, 0.900), "y": (0.893, 0.915), "z": (0.905, 0.928)}.items():
    crop = im.crop((int(w*0.46), int(h*b), int(w*1.0), int(h*d)))
    crop = crop.resize((crop.width*12, crop.height*12), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop.save(os.path.join(OUT, f"16_line_{tag}.png"))
print("ok")
