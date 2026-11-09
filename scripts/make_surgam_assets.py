from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "assets" / "images"
OUT.mkdir(parents=True, exist_ok=True)

green = (20, 125, 107, 255)
cream = (246, 248, 245, 255)
mint = (232, 246, 239, 255)
white = (255, 255, 255, 255)

def make(size, background, transparent=False):
    img = Image.new("RGBA", (size, size), (0,0,0,0) if transparent else background)
    draw = ImageDraw.Draw(img)
    pad = int(size * 0.18)
    if not transparent:
        draw.rounded_rectangle((pad, pad, size-pad, size-pad), radius=int(size*0.18), fill=green)
    cx = size // 2
    cy = size // 2
    # leaf/S mark, drawn as two tapered strokes with a small stem
    stroke = max(10, int(size * 0.085))
    draw.arc((cx-int(size*.24), cy-int(size*.27), cx+int(size*.19), cy+int(size*.05)), 205, 355, fill=white, width=stroke)
    draw.arc((cx-int(size*.19), cy-int(size*.05), cx+int(size*.24), cy+int(size*.27)), 25, 175, fill=white, width=stroke)
    draw.line((cx+int(size*.03), cy-int(size*.22), cx+int(size*.18), cy-int(size*.35)), fill=white, width=max(5, int(size*.035)))
    return img

make(1024, cream).save(OUT / "icon.png")
make(1024, cream).save(OUT / "splash-icon.png")
make(512, mint).save(OUT / "favicon.png")
make(512, None, transparent=True).save(OUT / "android-icon-foreground.png")
Image.new("RGBA", (512, 512), mint).save(OUT / "android-icon-background.png")
make(432, None, transparent=True).convert("L").save(OUT / "android-icon-monochrome.png")
print(f"created Surgam assets in {OUT}")
