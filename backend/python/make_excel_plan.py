"""
Floor plan built from the client's BOQ Excel wall/opening set.
NOTE: OCR reads integer door/window sizes and derives wall lengths from
geometry, so fractional Excel values (5.5, 4.5, 2.75) are rounded for the
drawing. For penny-exact Excel matching, type the exact values in the
Plan Result room editor.

Excel headline dims used:
  Ext walls 9", Height 8.5 ft, building 15 x 12.5 ft
  Windows: W1 5.5x4.5, W2 3.5x4.5, W3 2.5x4.5   (rounded 5x4 / 3x4 / 2x4)
  Doors:   MD1 4.5x8, D1 3x8, D2 2.75x8         (rounded 4x7 / 3x7 / 3x7)
Output: excel_floor_plan.png
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1500, 1050
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

def font(sz):
    for p in ["/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/System/Library/Fonts/Supplemental/Arial.ttf"]:
        try: return ImageFont.truetype(p, sz)
        except Exception: continue
    return ImageFont.load_default()

F_BIG, F_MED, F_SM = font(34), font(26), font(22)

def text(xy, s, f=F_MED, fill="black", anchor="mm"):
    d.text(xy, s, font=f, fill=fill, anchor=anchor)

WALLT = 14
ox0, oy0, ox1, oy1 = 130, 150, 1370, 900
d.rectangle([ox0, oy0, ox1, oy1], outline="black", width=WALLT)

# internal partition (vertical) 6 ft wall
px = 820
d.line([(px, oy0), (px, oy1)], fill="black", width=8)

# Zones (sizes in feet-inches so OCR parses them)
text(((ox0+px)//2, (oy0+oy1)//2 - 40), "ZONE1", F_BIG)
text(((ox0+px)//2, (oy0+oy1)//2 + 6),  "HALL", F_SM, fill="#555")
text(((ox0+px)//2, (oy0+oy1)//2 + 46), "15'0\"x12'6\"", F_MED)

text(((px+ox1)//2, (oy0+oy1)//2 - 40), "ZONE2", F_BIG)
text(((px+ox1)//2, (oy0+oy1)//2 + 6),  "ROOM", F_SM, fill="#555")
text(((px+ox1)//2, (oy0+oy1)//2 + 46), "12'6\"x10'0\"", F_MED)

# External wall labels (9" / H=8) on each side
text(((ox0+ox1)//2, oy0 - 42), "EW T=9 H=8", F_SM, fill="#1565C0")
text(((ox0+ox1)//2, oy1 + 42), "EW T=9 H=8", F_SM, fill="#1565C0")
text((ox0 + 95, oy0 + 200), "EW T=9 H=8", F_SM, fill="#1565C0")
text((ox1 - 95, oy0 + 200), "EW T=9 H=8", F_SM, fill="#1565C0")

# Internal wall label (9" partition like the Excel WALL1)
text((px - 100, (oy0+oy1)//2 + 150), "IW T=9 H=8", F_SM, fill="#2E7D32")

# Windows (rounded from Excel W1/W2/W3)
text((330, oy0 + 40), "W=5x4", F_SM, fill="#6A1B9A")
text((640, oy0 + 40), "W=3x4", F_SM, fill="#6A1B9A")
text((ox1 - 95, oy0 + 470), "W=2x4", F_SM, fill="#6A1B9A")

# Doors (rounded from Excel MD1/D1/D2) — gaps + labels
def gap_h(xmid, y, half=48): d.line([(xmid-half, y), (xmid+half, y)], fill="white", width=18)
def gap_v(x, ymid, half=48): d.line([(x, ymid-half), (x, ymid+half)], fill="white", width=12)

gap_h(420, oy1); text((420, oy1 - 34), "D=4x7", F_SM, fill="#C62828")   # MD1 main door
gap_v(px, 360);  text((px + 75, 360), "D=3x7", F_SM, fill="#C62828")    # D1
gap_h(1080, oy1); text((1080, oy1 - 34), "D=3x7", F_SM, fill="#C62828") # D2

# Title
text((W//2, 55), "EXCEL TEST FLOOR PLAN  —  ArchiQuant", F_BIG, fill="#0F172A")
text((W//2, 970), "Ext walls 9\" · Int wall 9\" · Height 8.5 ft  (from BOQ Excel)", F_SM, fill="#64748B")

out = "/Users/impacgo/Downloads/archiquant_dashboard 2/excel_floor_plan.png"
img.save(out, "PNG")
print("Saved:", out)
