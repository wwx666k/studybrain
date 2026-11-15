import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "14.png")).convert("L")
w, h = im.size
for tag,(b,d) in {"g1":(0.430,0.462),"g2":(0.455,0.487)}.items():
    crop = im.crop((int(w*0.03), int(h*b), int(w*0.40), int(h*d)))
    crop = crop.resize((crop.width*14, crop.height*14), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop.save(os.path.join(OUT, f"14_{tag}.png"))
print("ok")
