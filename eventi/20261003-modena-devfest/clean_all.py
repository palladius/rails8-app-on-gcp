import os
from PIL import Image, ImageDraw, ImageFont

img_configs = [
    ("eventi/20261003-modena-devfest/modena_devfest_poster_1_cinema_paradiso.png", "modena_devfest_poster_1_cinema_paradiso"),
    ("eventi/20261003-modena-devfest/modena_devfest_poster_2_spaghetti_western.png", "modena_devfest_poster_2_spaghetti_western"),
    ("eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_dolcevita.png", "modena_devfest_poster_3_fellini_dolcevita"),
]

font_bold_path = "/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF/Roboto-Bold.ttf"
font_regular_path = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

for src_path, name in img_configs:
    if not os.path.exists(src_path):
        continue
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    # 1. PURE ART (100% untouched artwork, zero banner)
    pure_art_path = f"eventi/20261003-modena-devfest/{name}_pure_art.png"
    img.convert("RGB").save(pure_art_path, "PNG")
    print(f"✅ Saved pure art: {pure_art_path}")

    # 2. CLEAN BOTTOM OVERLAY (No top banner! Only bottom info badge)
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    bar_height = int(h * 0.12)
    bar_y = h - bar_height - int(h * 0.015)

    # Dark translucent slate plate with vintage gold outline
    draw.rectangle([int(w * 0.04), bar_y, int(w * 0.96), bar_y + bar_height], fill=(15, 23, 42, 230))
    draw.rectangle([int(w * 0.04), bar_y, int(w * 0.96), bar_y + bar_height], outline=(245, 158, 11, 255), width=3)

    font_date = ImageFont.truetype(font_bold_path, size=int(w * 0.038))
    font_title = ImageFont.truetype(font_bold_path, size=int(w * 0.046))
    font_sub = ImageFont.truetype(font_regular_path, size=int(w * 0.030))

    line1 = "📍 MODENA • SABATO 3 OTTOBRE 2026 • ORE 14:30"
    line2 = "Deploy di Applicazioni Moderne Rails 8 su Google Cloud"
    line3 = "Da Zero a Serverless con AI & Antigravity • Con Riccardo ed Emiliano"

    def draw_text_centered(y, text, font, color):
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        x = (w - text_w) // 2
        draw.text((x + 1, y + 1), text, font=font, fill=(0, 0, 0, 220))
        draw.text((x, y), text, font=font, fill=color)

    draw_text_centered(bar_y + int(bar_height * 0.12), line1, font_date, (251, 191, 36, 255))
    draw_text_centered(bar_y + int(bar_height * 0.40), line2, font_title, (255, 255, 255, 255))
    draw_text_centered(bar_y + int(bar_height * 0.72), line3, font_sub, (203, 213, 225, 255))

    final_img = Image.alpha_composite(img, overlay).convert("RGB")
    clean_bottom_path = f"eventi/20261003-modena-devfest/{name}_clean_bottom.png"
    final_img.save(clean_bottom_path, "PNG")
    print(f"✅ Saved clean bottom: {clean_bottom_path}")

