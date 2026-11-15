import sys, os
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

SRC = r"D:\StudyBrain\tools\_src"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)

# usage: flatten.py name x0 y0 x1 y1 scale radius [gamma]
name = sys.argv[1]
x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
scale = float(sys.argv[6]) if len(sys.argv) > 6 else 6.0
radius = float(sys.argv[7]) if len(sys.argv) > 7 else 8
gamma = float(sys.argv[8]) if len(sys.argv) > 8 else 1.0

im = Image.open(os.path.join(SRC, name)).convert("L")
W, H = im.size
box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H))
c = im.crop(box)
arr = np.array(c).astype(np.float32)
bg = np.array(c.filter(ImageFilter.MedianFilter(size=5)).filter(ImageFilter.GaussianBlur(radius=radius))).astype(np.float32)
bg = np.maximum(bg, 1)
norm = np.clip(arr / bg * 200.0, 0, 255)
norm = 255 * np.power(norm / 255.0, gamma)
img = Image.fromarray(norm.astype(np.uint8))
img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
img = ImageEnhance.Contrast(img).enhance(1.5)
img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=140, threshold=1))
fp = os.path.join(OUT, f"{os.path.splitext(name)[0]}_fl_{box[0]}_{box[1]}_{box[2]}_{box[3]}.png")
img.save(fp)
print(fp, img.size)
