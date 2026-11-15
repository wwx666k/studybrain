import os
from PIL import Image, ImageEnhance
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "16.png")).convert("L")
w, h = im.size
crops = {
 "16_w1": (0.45, 0.80, 1.00, 0.93),
 "16_w2": (0.45, 0.90, 1.00, 1.00),
 "16_num": (0.45, 0.34, 1.00, 0.42),
}
for name,(a,b,c,d) in crops.items():
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*9, crop.height*9), Image.LANCZOS)
    crop = ImageEnhance.Contrast(crop).enhance(1.9)
    crop.save(os.path.join(OUT, name+".png"))
print("ok")
