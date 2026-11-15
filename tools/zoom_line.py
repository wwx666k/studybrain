import os
from PIL import Image, ImageEnhance
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
im = Image.open(os.path.join(SRC, "14.png")).convert("L")
w, h = im.size
for tag, (b, d) in {"a": (0.435, 0.470), "b": (0.455, 0.492)}.items():
    crop = im.crop((int(w*0.03), int(h*b), int(w*0.52), int(h*d)))
    crop = crop.resize((crop.width*10, crop.height*10), Image.LANCZOS)
    crop = ImageEnhance.Contrast(crop).enhance(2.0)
    crop.save(os.path.join(OUT, f"14_line_{tag}.png"))
print("ok")
