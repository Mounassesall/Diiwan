from typing import List

FIELDS_WHITELIST = [
    "taux_chomage_pct", "acces_internet_pct", "population",
    "taux_pauvrete_pct", "taux_alphabetisation_pct", "taux_urbanisation_pct",
    "taux_scolarisation_pct", "centres_sante", "production_cerealiere_tonnes"
]

REGIONS_WHITELIST = [
    "Dakar", "Diourbel", "Fatick", "Kaffrine", "Kaolack", "Kédougou",
    "Kolda", "Louga", "Matam", "Saint-Louis", "Sédhiou", "Tambacounda",
    "Thiès", "Ziguinchor"
]

OPERATIONS_WHITELIST = [
    "value", "compare", "trend", "ranking", "sum", "average"
]

ANNEES_VALIDES = range(2020, 2025)


import difflib

def corriger_region(nom: str) -> str:
    if not nom:
        return nom
    nom_lower = nom.strip().lower()
    for reg in REGIONS_WHITELIST:
        if reg.lower() == nom_lower:
            return reg
            
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
    if nom_lower in aliases:
        return aliases[nom_lower]
        
    close_matches = difflib.get_close_matches(nom_lower, [r.lower() for r in REGIONS_WHITELIST], n=1, cutoff=0.7)
    if close_matches:
        matched_lower = close_matches[0]
        for reg in REGIONS_WHITELIST:
            if reg.lower() == matched_lower:
                return reg
    return nom

def valider_intention(intent) -> List[str]:
    erreurs = []
    if intent.indicator and intent.indicator not in FIELDS_WHITELIST:
        erreurs.append(f"Indicateur non autorisé : {intent.indicator}")

    corrected_regions = []
    for r in intent.regions:
        corrected_regions.append(corriger_region(r))
    intent.regions = corrected_regions

    for r in intent.regions:
        if r not in REGIONS_WHITELIST:
            erreurs.append(f"Région non autorisée : {r}")

    if intent.operation and intent.operation not in OPERATIONS_WHITELIST:
        erreurs.append(f"Opération non autorisée : {intent.operation}")

    if intent.start_year is not None and intent.start_year not in ANNEES_VALIDES:
        erreurs.append(f"Année de début non autorisée : {intent.start_year}")

    if intent.end_year is not None and intent.end_year not in ANNEES_VALIDES:
        erreurs.append(f"Année de fin non autorisée : {intent.end_year}")

    if (
        intent.start_year is not None
        and intent.end_year is not None
        and intent.start_year > intent.end_year
    ):
        erreurs.append("L'année de début ne peut pas être postérieure à l'année de fin.")

    return erreurs
