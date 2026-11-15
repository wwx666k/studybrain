import sys, os
from PIL import Image, ImageEnhance, ImageFilter

SRC = r"D:\StudyBrain\tools\_src"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)

# usage: crop.py name x0 y0 x1 y1 scale [contrast]
name = sys.argv[1]
x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
scale = float(sys.argv[6]) if len(sys.argv) > 6 else 6.0
contrast = float(sys.argv[7]) if len(sys.argv) > 7 else 1.8

im = Image.open(os.path.join(SRC, name)).convert("L")
W, H = im.size
box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H))
c = im.crop(box)
c = c.resize((int(c.width * scale), int(c.height * scale)), Image.LANCZOS)
c = ImageEnhance.Contrast(c).enhance(contrast)
c = c.filter(ImageFilter.UnsharpMask(radius=2, percent=160, threshold=2))
fp = os.path.join(OUT, f"{os.path.splitext(name)[0]}_{box[0]}_{box[1]}_{box[2]}_{box[3]}.png")
c.save(fp)
print(fp, c.size)
