import os
import sys
import time
from io import BytesIO
from PIL import Image
from google import genai
from google.genai import types

api_key = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

prompts = [
    {
        "filename": "modena_devfest_poster_1_classic_matz.png",
        "prompt": "Vertical vintage 1960s Italian cinema film poster for a tech event in Modena, Italy. Big painted Italian typography: 'RAILS 8 SU GOOGLE CLOUD' and 'MODENA DEVFEST - OTTOBRE 2026'. In the center, Yukihiro Matsumoto (Matz) smiling warmly with round spectacles, holding a glowing vibrant red ruby gemstone. In the background, Modena's famous Ghirlandina bell tower and Piazza Grande under Italian sky with modernist clouds in Google Cloud colors (blue, red, yellow, green). A retro steam train running along rails. Screenprint texture, authentic Italian movie studio credits layout at the bottom. Elegant, cinematic retro masterpiece."
    },
    {
        "filename": "modena_devfest_poster_2_spaghetti_western.png",
        "prompt": "Vertical dramatic 1960s Italian cinema poster, Sergio Leone style, for 'MODENA DEVFEST: PER UN PUGNO DI GEMME'. Huge typography in distressed vintage woodblock font: 'RAILS 8 SU GOOGLE CLOUD'. At the center, a cinematic heroic programmer portrait reminiscent of Matz holding a glowing crimson Ruby crystal. In the backdrop, Modena cathedral bell tower (Torre Ghirlandina) surrounded by stylized clouds in primary Google Cloud colors (blue, red, yellow, green). 1960s Technicolor aesthetic, Cinecitta movie poster layout."
    },
    {
        "filename": "modena_devfest_poster_3_fellini_dolcevita.png",
        "prompt": "Vertical 1960s Federico Fellini Dolce Vita style painted poster for 'MODENA DEVFEST - SABATO 3 OTTOBRE 2026'. Hand-painted gouache vintage illustration with title 'LA DOLCE VITA DI RAILS 8'. Features Yukihiro Matsumoto (Matz) surrounded by vintage Italian Vespa carrying a giant glowing red ruby, Modena architecture with Ghirlandina tower, and modernist clouds in Google Cloud colors (vibrant blue, red, yellow, green). Warm Mediterranean tones, authentic distressed lithograph poster texture with Italian movie credits."
    }
]

output_dir = os.path.dirname(os.path.abspath(__file__))

for p in prompts:
    filepath = os.path.join(output_dir, p["filename"])
    if os.path.exists(filepath):
        print(f"Skipping {p['filename']} (already exists)")
        continue

    print(f"\n🎨 Generating {p['filename']} using gemini-2.5-flash-image...")
    success = False
    for model_name in ["gemini-2.5-flash-image", "gemini-3.1-flash-image", "gemini-3-pro-image-preview"]:
        try:
            print(f"   Trying model {model_name}...")
            response = client.models.generate_content(
                model=model_name,
                contents=p["prompt"],
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"]
                )
            )
            if response.parts:
                for part in response.parts:
                    if part.inline_data:
                        data = part.inline_data.data
                        img = Image.open(BytesIO(data))
                        img.save(filepath, "PNG")
                        print(f"✅ Saved: {filepath} ({img.size}) via {model_name}")
                        success = True
                        break
            if success:
                break
        except Exception as e:
            print(f"   ⚠️ {model_name} failed: {e}")
            time.sleep(2)
            
    if not success:
        print(f"❌ Could not generate {p['filename']}")
    time.sleep(3)

print("\n🎉 Done generating posters!")
