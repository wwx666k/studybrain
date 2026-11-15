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
    crop = crop.filter(ImageFilter.UnsharpMask(radius=3, percent=150))
    crop.save(os.path.join(OUT, name+".png"))

f(16, "16_t78b", (0.05, 0.470, 0.53, 0.500), 10)
f(16, "16_81a", (0.50, 0.630, 1.0, 0.675), 10)
f(16, "16_81b", (0.50, 0.670, 1.0, 0.715), 10)
print("ok")
