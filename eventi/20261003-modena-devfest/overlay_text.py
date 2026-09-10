import os
from PIL import Image, ImageDraw, ImageFont

img_paths = [
    "eventi/20261003-modena-devfest/modena_devfest_poster_1_cinema_paradiso.png",
    "eventi/20261003-modena-devfest/modena_devfest_poster_2_spaghetti_western.png",
    "eventi/20261003-modena-devfest/modena_devfest_poster_3_fellini_dolcevita.png"
]

font_bold_path = "/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF/Roboto-Bold.ttf"
font_regular_path = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

for p in img_paths:
    if not os.path.exists(p):
        continue
    img = Image.open(p).convert("RGBA")
    w, h = img.size

    # Create overlay
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Box dimensions
    box_height = int(h * 0.16)
    box_y = int(h * 0.04) # top banner

    # Semi-transparent dark vignette banner
    draw.rectangle([0, box_y, w, box_y + box_height], fill=(15, 23, 42, 220)) # rich slate dark
    # Gold retro border lines
    draw.line([0, box_y, w, box_y], fill=(245, 158, 11, 255), width=4) # Amber gold top
    draw.line([0, box_y + box_height, w, box_y + box_height], fill=(245, 158, 11, 255), width=4)

    # Fonts
    font_sub = ImageFont.truetype(font_bold_path, size=int(w * 0.040))
    font_main = ImageFont.truetype(font_bold_path, size=int(w * 0.052))
    font_presenters = ImageFont.truetype(font_regular_path, size=int(w * 0.032))

    line1 = "📍 MODENA • SABATO 3 OTTOBRE 2026 • ORE 14:30"
    line2 = "Deploy di Applicazioni Moderne Rails 8 su Google Cloud"
    line3 = "Da Zero a Produzione Serverless con AI & Google Antigravity • Con Riccardo ed Emiliano"

    # Draw centered text with shadow
    def draw_text_centered(y, text, font, color, shadow_color=(0, 0, 0, 200)):
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        x = (w - text_w) // 2
        # Shadow
        draw.text((x + 2, y + 2), text, font=font, fill=shadow_color)
        draw.text((x, y), text, font=font, fill=color)

    pad_y = box_y + int(box_height * 0.12)
    draw_text_centered(pad_y, line1, font_sub, (251, 191, 36, 255)) # Amber 400
    draw_text_centered(pad_y + int(box_height * 0.32), line2, font_main, (255, 255, 255, 255)) # White
    draw_text_centered(pad_y + int(box_height * 0.68), line3, font_presenters, (203, 213, 225, 255)) # Slate 300

    # Composite
    out = Image.alpha_composite(img, overlay).convert("RGB")
    out_filename = p.replace(".png", "_final_locandina.png")
    out.save(out_filename, "PNG")
    print(f"✅ Generated: {out_filename}")

