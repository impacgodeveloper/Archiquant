"""
Generates a clean, OCR-friendly sample floor plan for ArchiQuant testing.
Uses the exact label conventions easyocr_reader.py parses:
  Zones   : ZONE1 + size  15'0"x12'0"
  Ext wall: EW T=9 H=8      (9" thick, 8.5ft -> use 8/9 integer the parser reads T=/H=)
  Int wall: IW T=4 H=8
  Doors   : D=3x7
  Windows : W=4x4
Output: sample_floor_plan.png (1400x1000)
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1400, 1000
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

def font(sz, bold=True):
    paths = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            continue
    return ImageFont.load_default()

F_BIG = font(34)
F_MED = font(26)
F_SM  = font(22)

def text(xy, s, f=F_MED, fill="black", anchor="mm"):
    d.text(xy, s, font=f, fill=fill, anchor=anchor)

# ── Outer building outline (thick = external walls) ──────────────
WALL = 14
ox0, oy0, ox1, oy1 = 120, 120, 1280, 880
d.rectangle([ox0, oy0, ox1, oy1], outline="black", width=WALL)

# Internal partition wall (vertical) splitting Living | Bedroom
px = 760
d.line([(px, oy0), (px, oy1)], fill="black", width=8)
# Internal partition (horizontal) splitting Bedroom / Bath
py = 520
d.line([(px, py), (ox1, py)], fill="black", width=8)

# ── Zone labels + sizes ──────────────────────────────────────────
text(((ox0+px)//2, (oy0+oy1)//2 - 40), "ZONE1", F_BIG)
text(((ox0+px)//2, (oy0+oy1)//2 + 10), "LIVING", F_SM, fill="#555")
text(((ox0+px)//2, (oy0+oy1)//2 + 50), "15'0\"x12'0\"", F_MED)

text(((px+ox1)//2, (oy0+py)//2 - 30), "ZONE2", F_BIG)
text(((px+ox1)//2, (oy0+py)//2 + 10), "BEDROOM", F_SM, fill="#555")
text(((px+ox1)//2, (oy0+py)//2 + 50), "12'0\"x10'0\"", F_MED)

text(((px+ox1)//2, (py+oy1)//2 - 30), "ZONE3", F_BIG)
text(((px+ox1)//2, (py+oy1)//2 + 10), "BATH", F_SM, fill="#555")
text(((px+ox1)//2, (py+oy1)//2 + 50), "6'0\"x8'0\"", F_MED)

# ── External wall labels (near each outer wall) ──────────────────
text(((ox0+ox1)//2, oy0 - 40), "EW T=9 H=8", F_SM, fill="#1565C0")     # top
text(((ox0+ox1)//2, oy1 + 40), "EW T=9 H=8", F_SM, fill="#1565C0")     # bottom
text((ox0 + 95, oy0 + 230), "EW T=9 H=8", F_SM, fill="#1565C0", anchor="mm")  # left (inside)
text((ox1 - 95, oy0 + 620), "EW T=9 H=8", F_SM, fill="#1565C0", anchor="mm")  # right (inside)

# ── Internal wall labels ─────────────────────────────────────────
text((px - 95, (oy0+oy1)//2 + 130), "IW T=4 H=8", F_SM, fill="#2E7D32")  # vertical partition
text((px + 150, py + 35), "IW T=4 H=8", F_SM, fill="#2E7D32")            # horizontal partition

# ── Doors (gap in wall + label) ──────────────────────────────────
def door_gap_v(x, ymid, half=45):
    d.line([(x, ymid-half), (x, ymid+half)], fill="white", width=12)
def door_gap_h(xmid, y, half=45):
    d.line([(xmid-half, y), (xmid+half, y)], fill="white", width=18)

# main entry door (bottom external wall)
door_gap_h(360, oy1)
text((360, oy1 - 35), "D=3x7", F_SM, fill="#C62828")
# living -> bedroom door (internal vertical wall)
door_gap_v(px, 300)
text((px + 70, 300), "D=3x7", F_SM, fill="#C62828")
# bedroom -> bath door
door_gap_h(1080, py)
text((1080, py - 32), "D=3x7", F_SM, fill="#C62828")

# ── Windows (label on external walls) ────────────────────────────
text((300, oy0 + 40), "W=4x4", F_SM, fill="#6A1B9A")     # living top window
text((ox1 - 90, 300), "W=4x4", F_SM, fill="#6A1B9A")     # bedroom right window
text((ox1 - 90, 700), "W=3x3", F_SM, fill="#6A1B9A")     # bath right window

# ── Title block ──────────────────────────────────────────────────
text((W//2, 50), "SAMPLE FLOOR PLAN  —  ArchiQuant Test", F_BIG, fill="#0F172A")
text((W//2, 950), "Ext walls 9\" / Int walls 4\" / Height 8.5 ft", F_SM, fill="#64748B")

out = "/Users/impacgo/Downloads/archiquant_dashboard 2/sample_floor_plan.png"
img.save(out, "PNG")
print("Saved:", out)
