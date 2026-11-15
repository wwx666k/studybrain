import os
from PIL import Image, ImageEnhance
SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices3"
regions = {
    "15_a": ("15", 0.48, 0.33, 1.00, 0.50),   # 【72】4、5
    "15_b": ("15", 0.48, 0.83, 1.00, 1.00),   # 【74】4
    "15_c": ("15", 0.02, 0.28, 0.53, 0.45),   # 【69】2 手写遮挡区
}
for name, (n, a, b, c, d) in regions.items():
    im = Image.open(os.path.join(SRC, f"{n}.png")).convert("L")
    w, h = im.size
    crop = im.crop((int(w*a), int(h*b), int(w*c), int(h*d)))
    crop = crop.resize((crop.width*8, crop.height*8), Image.LANCZOS)
    crop = ImageEnhance.Contrast(crop).enhance(1.8)
    crop.save(os.path.join(OUT, f"{name}.png"))
print("ok")
