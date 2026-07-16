import re
import unicodedata
from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class QueryIntent:
    indicator: Optional[str] = None
    regions: List[str] = field(default_factory=list)
    start_year: Optional[int] = None
    end_year: Optional[int] = None
    operation: str = "value"
    limit: Optional[int] = None
    chart_type: Optional[str] = None
    needs_clarification: bool = False
    clarification_message: Optional[str] = None
    is_out_of_scope: bool = False

REGIONS_SENEGAL = [
    "Dakar", "Diourbel", "Fatick", "Kaffrine", "Kaolack", "Kédougou",
    "Kolda", "Louga", "Matam", "Saint-Louis", "Sédhiou", "Tambacounda",
    "Thiès", "Ziguinchor"
]

ALIAS_INDICATEURS = {
    "chômage": "taux_chomage_pct",
    "chomage": "taux_chomage_pct",
    "internet": "acces_internet_pct",
    "population": "population",
    "habitants": "population",
    "peuplees": "population",
    "peuplee": "population",
    "pauvreté": "taux_pauvrete_pct",
    "pauvrete": "taux_pauvrete_pct",
    "alphabétisation": "taux_alphabetisation_pct",
    "alphabetisation": "taux_alphabetisation_pct",
    "urbanisation": "taux_urbanisation_pct",
    "scolarisation": "taux_scolarisation_pct",
    "santé": "centres_sante",
    "sante": "centres_sante",
    "centres de santé": "centres_sante",
    "centres de sante": "centres_sante",
    "céréales": "production_cerealiere_tonnes",
    "cereales": "production_cerealiere_tonnes",
    "production": "production_cerealiere_tonnes"
}

def normaliser_texte(texte: str) -> str:
    texte = unicodedata.normalize('NFD', texte).encode('ascii', 'ignore').decode('utf-8')
    return texte.lower()

def analyser_question(question: str) -> QueryIntent:
    intent = QueryIntent()
    q_norm = normaliser_texte(question)
    
    # Hors sujet brutal
    mots_hors_sujet = ["recette", "meteo", "blague", "bonjour", "film", "musique"]
    if any(m in q_norm for m in mots_hors_sujet) and not any(a in q_norm for a in ALIAS_INDICATEURS.keys()):
        intent.is_out_of_scope = True
        intent.needs_clarification = True
        intent.clarification_message = "Désolé, je ne réponds qu'aux questions sur les statistiques régionales du Sénégal."
        return intent

    # 1. Détection de l'indicateur
    for alias, champ in ALIAS_INDICATEURS.items():
        if normaliser_texte(alias) in q_norm:
            intent.indicator = champ
            break
            
    # 2. Détection des régions
    # 2.1. Recherche exacte d'abord (y compris les espaces comme Saint-Louis)
    for reg in REGIONS_SENEGAL:
        reg_norm = normaliser_texte(reg)
        if re.search(r'\b' + re.escape(reg_norm) + r'\b', q_norm) or re.search(r'\b' + re.escape(reg_norm.replace('-', ' ')) + r'\b', q_norm):
            if reg not in intent.regions:
                intent.regions.append(reg)

    # 2.2. Recherche approximative mot par mot si aucune région trouvée
    if not intent.regions:
        import difflib
        mots = re.findall(r'\b\w{3,}\b', q_norm) # Mots de 3 lettres ou plus
        aliases = {
            "dackar": "Dakar", "dakare": "Dakar",
            "djourbel": "Diourbel", "diourbele": "Diourbel",
            "fatique": "Fatick", "fatike": "Fatick",
            "kafrine": "Kaffrine",
            "kaolac": "Kaolack",
            "kedugu": "Kédougou",
            "st louis": "Saint-Louis", "saint louis": "Saint-Louis", "ndar": "Saint-Louis",
            "sejiou": "Sédhiou",
            "tamba": "Tambacounda",
            "ties": "Thiès",
            "ziguinshor": "Ziguinchor", "zig": "Ziguinchor"
        }
        for mot in mots:
            if mot in aliases:
                reg = aliases[mot]
                if reg not in intent.regions:
                    intent.regions.append(reg)
                continue
            close_matches = difflib.get_close_matches(mot, [r.lower() for r in REGIONS_SENEGAL], n=1, cutoff=0.75)
            if close_matches:
                matched_lower = close_matches[0]
                for reg in REGIONS_SENEGAL:
                    if reg.lower() == matched_lower:
                        if reg not in intent.regions:
                            intent.regions.append(reg)
            
    # 3. Extraction des années
    annees = [int(a) for a in re.findall(r'\b(202[0-4])\b', q_norm)]
    if annees:
        annees.sort()
        if len(annees) == 1:
            intent.start_year = annees[0]
            intent.end_year = annees[0]
        else:
            intent.start_year = annees[0]
            intent.end_year = annees[-1]
            
    # 4. Détermination de l'opération
    if any(mot in q_norm for mot in ["plus", "top", "classement", "cinq", "trois", "dix", "meilleur", "pire"]):
        intent.operation = "ranking"
        if "cinq" in q_norm or "5" in q_norm: intent.limit = 5
        elif "trois" in q_norm or "3" in q_norm: intent.limit = 3
        elif "dix" in q_norm or "10" in q_norm: intent.limit = 10
        else: intent.limit = 5
        intent.chart_type = "bar"
    elif any(mot in q_norm for mot in ["total", "somme"]):
        intent.operation = "sum"
    elif "moyenne" in q_norm:
        intent.operation = "average"
    elif any(mot in q_norm for mot in ["evolution", "evolue", "tendance"]):
        intent.operation = "trend"
        intent.chart_type = "line"
    elif "compare" in q_norm or "comparer" in q_norm or len(intent.regions) > 1:
        intent.operation = "compare"
        intent.chart_type = "bar"
    else:
        if intent.start_year != intent.end_year and intent.start_year is not None:
            intent.operation = "trend"
            intent.chart_type = "line"
        else:
            intent.operation = "value"
            
    # 5. Clarification
    if not intent.indicator and not intent.regions and not annees:
        intent.is_out_of_scope = True
        intent.needs_clarification = True
        intent.clarification_message = "Désolé, je ne réponds qu'aux questions sur les statistiques régionales du Sénégal."
        return intent

    if not intent.indicator:
        intent.needs_clarification = True
        intent.clarification_message = "Je n'ai pas compris quel indicateur vous souhaitez (ex: population, chômage, santé...)."
        return intent

    if intent.operation in ["value", "compare", "trend"] and not intent.regions:
        intent.needs_clarification = True
        intent.clarification_message = "De quelle(s) région(s) parlez-vous ?"
        return intent
            
    return intent
