import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "16.png")).convert("L")
w, h = im.size
crop = im.crop((int(w*0.02), int(h*0.44), int(w*0.55), int(h*0.56)))
crop = crop.resize((crop.width*7, crop.height*7), Image.LANCZOS)
crop = ImageOps.autocontrast(crop)
crop.save(os.path.join(OUT, "16_78zone.png"))
print("ok")
