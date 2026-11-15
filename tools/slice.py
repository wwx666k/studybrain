import sys, os
from PIL import Image, ImageEnhance, ImageFilter

SRC = r"D:\StudyBrain\锐阅读八年级答案"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)


def slice_img(name, rows=2, cols=2, scale=3.5, overlap=0.08, gray=True):
    path = os.path.join(SRC, name)
    im = Image.open(path).convert("L" if gray else "RGB")
    W, H = im.size
    tag = os.path.splitext(name)[0]
    made = []
    for r in range(rows):
        for c in range(cols):
            x0 = max(0, int(W * (c / cols - overlap)))
            x1 = min(W, int(W * ((c + 1) / cols + overlap)))
            y0 = max(0, int(H * (r / rows - overlap)))
            y1 = min(H, int(H * ((r + 1) / rows + overlap)))
            box = (x0, y0, x1, y1)
            crop = im.crop(box)
            nw, nh = int(crop.width * scale), int(crop.height * scale)
            crop = crop.resize((nw, nh), Image.LANCZOS)
            crop = ImageEnhance.Contrast(crop).enhance(1.6)
            crop = crop.filter(ImageFilter.UnsharpMask(radius=2, percent=140, threshold=2))
            fp = os.path.join(OUT, f"{tag}_r{r}c{c}.png")
            crop.save(fp)
            made.append((fp, box, (nw, nh)))
    for m in made:
        print(m)


if __name__ == "__main__":
    name = sys.argv[1]
    rows = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    cols = int(sys.argv[3]) if len(sys.argv) > 3 else 2
    scale = float(sys.argv[4]) if len(sys.argv) > 4 else 3.5
    slice_img(name, rows, cols, scale)
