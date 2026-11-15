import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
def f(n, name, box, zoom=10):
    im = Image.open(os.path.join(SRC, f"{n}.png")).convert("L")
    w, h = im.size
    a,b,c,d = box
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*zoom, crop.height*zoom), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop = crop.filter(ImageFilter.UnsharpMask(radius=4, percent=160))
    crop.save(os.path.join(OUT, name+".png"))

f(18, "18_name", (0.03, 0.315, 0.53, 0.345), 10)
f(19, "19_t95", (0.05, 0.068, 0.53, 0.098), 10)
f(16, "16_t78", (0.03, 0.238, 0.53, 0.268), 10)
f(15, "15_t72", (0.48, 0.055, 1.0, 0.085), 10)
print("ok")
