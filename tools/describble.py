import sys, os
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

SRC = r"D:\StudyBrain\tools\_src"
OUT = r"D:\StudyBrain\tools\_slices"
os.makedirs(OUT, exist_ok=True)


def clean(arr, thr=6, strength=2.6):
    """Suppress magenta/purple scribble: pixels where (R+B)/2 - G > thr get pushed toward white."""
    a = arr.astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    magenta = (r + b) / 2.0 - g
    w = np.clip((magenta - thr) / 12.0, 0, 1) * np.clip((255 - g) / 255.0 + 0.35, 0, 1)
    w = np.clip(w * strength, 0, 1)
    out = a.copy()
    for i in range(3):
        out[..., i] = a[..., i] * (1 - w) + 255 * w
    return out


def main():
    name = sys.argv[1]
    x0, y0, x1, y1 = (float(v) for v in sys.argv[2:6])
    scale = float(sys.argv[6]) if len(sys.argv) > 6 else 6.0
    thr = float(sys.argv[7]) if len(sys.argv) > 7 else 6
    contrast = float(sys.argv[8]) if len(sys.argv) > 8 else 1.4

    im = Image.open(os.path.join(SRC, name)).convert("RGB")
    W, H = im.size
    box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H))
    arr = np.array(im.crop(box))
    arr = clean(arr, thr=thr)
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert("L")
    img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
    img = ImageEnhance.Contrast(img).enhance(contrast)
    img = img.filter(ImageFilter.UnsharpMask(radius=2, percent=150, threshold=2))
    fp = os.path.join(OUT, f"{os.path.splitext(name)[0]}_cl_{box[0]}_{box[1]}_{box[2]}_{box[3]}.png")
    img.save(fp)
    print(fp, img.size)


main()
