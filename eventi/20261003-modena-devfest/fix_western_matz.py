import os
import sys
import time
from io import BytesIO
from PIL import Image
from google import genai
from google.genai import types

api_key = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

prompt = (
    "Vertical dramatic 1960s Italian cinema poster, Sergio Leone spaghetti western style, for tech event in Modena. "
    "Title in huge distressed vintage woodblock font: 'PER UN PUGNO DI GEMME - RAILS 8 SU GOOGLE CLOUD'. "
    "In the center, an authentic, accurate portrait of Yukihiro Matsumoto (Matz): middle-aged Japanese software engineer, "
    "wearing his iconic distinctive round black eyeglasses, with a gentle wise smile, beard stubble, wearing a vintage western poncho or duster coat. "
    "He holds a glowing crystalline crimson red Ruby gemstone in his weathered hand. "
    "In the dramatic backdrop: the Ghirlandina bell tower of Modena surrounded by dusty desert sun and stylized clouds in primary Google Cloud colors (blue, red, yellow, green). "
    "1960s Technicolor cinematic lighting, authentic vintage Cinecitta movie poster layout, textured film grain. Masterpiece."
)

output_path = "eventi/20261003-modena-devfest/modena_devfest_poster_2_spaghetti_western_matz_accurate.png"
print("🎨 Generating accurate Matz Spaghetti Western poster...")

try:
    response = client.models.generate_content(
        model="gemini-2.5-flash-image",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"]
        )
    )
    if response.parts:
        for part in response.parts:
            if part.inline_data:
                data = part.inline_data.data
                img = Image.open(BytesIO(data))
                img.save(output_path, "PNG")
                print(f"✅ Saved accurate Matz western: {output_path} ({img.size})")
                break
    else:
        print("❌ No parts returned")
except Exception as e:
    print(f"❌ Error: {e}")
