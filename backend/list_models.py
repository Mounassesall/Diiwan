import os
from google import genai

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    from dotenv import load_dotenv
    load_dotenv(r'C:\Users\pc\Documents\MES_COURS\IA Generative\Diiwan\backend\.env')
    api_key = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=api_key)
print("Available Models:")
for model in client.models.list():
    print(model.name)
