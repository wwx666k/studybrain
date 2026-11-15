import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
def f(n, name, box, zoom=9):
    im = Image.open(os.path.join(SRC, f"{n}.png")).convert("L")
    w, h = im.size
    a,b,c,d = box
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*zoom, crop.height*zoom), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop = crop.filter(ImageFilter.UnsharpMask(radius=3, percent=150))
    crop.save(os.path.join(OUT, name+".png"))
f(17, "17_lb1", (0.02, 0.72, 0.55, 0.85))
f(17, "17_lb2", (0.02, 0.84, 0.55, 0.97))
print("ok")
