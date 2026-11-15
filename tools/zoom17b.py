import os
from PIL import Image, ImageOps
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "17.png")).convert("L")
w, h = im.size
a,b,c,d = (0.45, 0.270, 1.0, 0.315)
crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
crop = crop.resize((crop.width*11, crop.height*11), Image.LANCZOS)
crop = ImageOps.autocontrast(crop)
crop.save(os.path.join(OUT, "17_sec2.png"))
print(crop.size)
