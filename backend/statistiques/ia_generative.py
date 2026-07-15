import os
import google.generativeai as genai
from django.conf import settings

def generer_analyse_ia(question: str, donnees: dict) -> str:
    if not getattr(settings, 'USE_GENERATIVE_AI', False):
        return "L'IA générative est désactivée."

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key or api_key == "ta_vraie_cle_api_ici":
        return "Clé API Gemini non configurée."

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')

    prompt = f"""
Tu es un expert en données régionales du Sénégal pour le projet Diiwan.
L'utilisateur a posé la question suivante : "{question}"

Voici les données statistiques trouvées par le système :
{donnees}

Ton rôle : Rédige une analyse claire, concise et professionnelle (en français) 
répondant à la question à partir de ces données. 
- Ne mentionne pas le format JSON ni que tu es une IA.
- Si le système a retourné une erreur ou un besoin de clarification, reformule-le poliment.
- Sois direct et précis, et utilise un ton pédagogique.
"""
    
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        return f"Erreur lors de l'appel à l'IA : {str(e)}"
