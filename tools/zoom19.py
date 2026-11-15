import os
from PIL import Image, ImageOps, ImageFilter
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "19.png")).convert("L")
w, h = im.size
crops = {"a": (0.47, 0.845, 1.0, 0.875), "b": (0.47, 0.865, 1.0, 0.895)}
for name,(a,b,c,d) in crops.items():
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*12, crop.height*12), Image.LANCZOS)
    crop = ImageOps.autocontrast(crop)
    crop = crop.filter(ImageFilter.UnsharpMask(radius=4, percent=180))
    crop.save(os.path.join(OUT, f"19_{name}.png"))
print("ok")
