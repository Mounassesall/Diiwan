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

def valider_intention(intent) -> List[str]:
    erreurs = []
    if intent.indicator and intent.indicator not in FIELDS_WHITELIST:
        erreurs.append(f"Indicateur non autorisé : {intent.indicator}")
    
    for r in intent.regions:
        if r not in REGIONS_WHITELIST:
            erreurs.append(f"Région non autorisée : {r}")
            
    if intent.operation and intent.operation not in OPERATIONS_WHITELIST:
        erreurs.append(f"Opération non autorisée : {intent.operation}")
        
    return erreurs
