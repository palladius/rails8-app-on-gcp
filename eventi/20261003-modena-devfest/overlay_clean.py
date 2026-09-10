import os
from PIL import Image, ImageDraw, ImageFont

# Image 3 (Fellini Dolce Vita) is the clear winner!
img_path = "eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_dolcevita.png"
img = Image.open(img_path).convert("RGBA")
w, h = img.size

# We overlay ONLY at the very bottom in the credits area or cleanly integrate without covering "LA DOLCE VITA DI RAILS 8"
# Let's see: the image has an authentic credits box at the bottom:
# "UNA PRODUCTIONE DI MODENA DEVFEST..."
# Let's put a clean retro typographic lower-third card or bottom subtitle that leaves the beautiful artwork 100% untouched!

overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
draw = ImageDraw.Draw(overlay)

# Subtitle banner at the bottom (over the bottom credits or just above them)
font_bold_path = "/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF/Roboto-Bold.ttf"
font_regular_path = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

font_date = ImageFont.truetype(font_bold_path, size=int(w * 0.038))
font_title = ImageFont.truetype(font_bold_path, size=int(w * 0.046))
font_sub = ImageFont.truetype(font_regular_path, size=int(w * 0.030))

# Bottom banner height and position
bar_height = int(h * 0.12)
bar_y = h - bar_height - int(h * 0.015)

# Elegant dark semi-transparent plate with gold borders
draw.rectangle([int(w * 0.04), bar_y, int(w * 0.96), bar_y + bar_height], fill=(15, 23, 42, 230))
# Thin vintage gold border
draw.rectangle([int(w * 0.04), bar_y, int(w * 0.96), bar_y + bar_height], outline=(245, 158, 11, 255), width=3)

line1 = "📍 MODENA • SABATO 3 OTTOBRE 2026 • ORE 14:30"
line2 = "Deploy di Applicazioni Moderne Rails 8 su Google Cloud"
line3 = "Da Zero a Serverless con AI & Antigravity • Con Riccardo ed Emiliano"

def draw_text_centered(y, text, font, color):
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = (w - text_w) // 2
    # subtle drop shadow
    draw.text((x + 1, y + 1), text, font=font, fill=(0, 0, 0, 220))
    draw.text((x, y), text, font=font, fill=color)

draw_text_centered(bar_y + int(bar_height * 0.12), line1, font_date, (251, 191, 36, 255)) # amber
draw_text_centered(bar_y + int(bar_height * 0.40), line2, font_title, (255, 255, 255, 255)) # white
draw_text_centered(bar_y + int(bar_height * 0.72), line3, font_sub, (203, 213, 225, 255)) # slate 300

final_img = Image.alpha_composite(img, overlay).convert("RGB")
out_path = "eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_clean_bottom.png"
final_img.save(out_path, "PNG")
print(f"✅ Saved clean bottom poster: {out_path}")

# Also let's create a 100% untouched version with NO OVERLAY at all (pure original artwork!)
untouched_path = "eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_pure_art.png"
img.convert("RGB").save(untouched_path, "PNG")
print(f"✅ Saved pure artwork: {untouched_path}")
