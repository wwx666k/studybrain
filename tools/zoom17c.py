import os
from PIL import Image
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "17.png")).convert("L")
w, h = im.size
a,b,c,d = (0.56, 0.272, 0.82, 0.305)
crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
crop = crop.resize((crop.width*18, crop.height*18), Image.LANCZOS)
crop.save(os.path.join(OUT, "17_sec3.png"))
print(crop.size)
