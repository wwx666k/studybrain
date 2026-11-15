import os
from PIL import Image, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "17.png")).convert("L")
w, h = im.size
crop = im.crop((int(w*0.605), int(h*0.272), int(w*0.735), int(h*0.305)))
crop = crop.resize((crop.width*28, crop.height*28), Image.LANCZOS)
crop = crop.filter(ImageFilter.UnsharpMask(radius=6, percent=200))
crop.save(os.path.join(OUT, "17_sec4.png"))
print(crop.size)
