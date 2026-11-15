import sys, os
import numpy as np
from PIL import Image

SRC = r"D:\StudyBrain\tools\_src"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)

# usage: thresh.py name x0 y0 x1 y1 scale thresh
name = sys.argv[1]
x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
scale = float(sys.argv[6]) if len(sys.argv) > 6 else 6.0
thr = float(sys.argv[7]) if len(sys.argv) > 7 else 110

im = Image.open(os.path.join(SRC, name)).convert("L")
W, H = im.size
box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H))
c = im.crop(box)
arr = np.array(c)
bw = np.where(arr < thr, 0, 255).astype(np.uint8)
img = Image.fromarray(bw).resize((int(c.width * scale), int(c.height * scale)), Image.LANCZOS)
fp = os.path.join(OUT, f"{os.path.splitext(name)[0]}_bw{int(thr)}_{box[0]}_{box[1]}_{box[2]}_{box[3]}.png")
img.save(fp)
print(fp, img.size)
