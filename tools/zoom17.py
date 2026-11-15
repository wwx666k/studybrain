import os
from PIL import Image, ImageOps
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "17.png")).convert("L")
w, h = im.size
for tag, box in {"sec": (0.50, 0.53, 0.95, 0.58), "q4": (0.47, 0.28, 1.0, 0.36)}.items():
    a,b,c,d = box
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*10, crop.height*10), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop.save(os.path.join(OUT, f"17_{tag}.png"))
print("ok")
