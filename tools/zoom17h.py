import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "17.png")).convert("L")
w, h = im.size
crop = im.crop((int(w*0.02), int(h*0.695), int(w*0.55), int(h*0.745)))
crop = crop.resize((crop.width*10, crop.height*10), Image.LANCZOS)
crop = ImageOps.autocontrast(crop)
crop = crop.filter(ImageFilter.UnsharpMask(radius=3, percent=150))
crop.save(os.path.join(OUT, "17_q5.png"))
print("ok")
