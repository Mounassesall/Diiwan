from typing import Any, Dict, List, Optional

from .analyseur import QueryIntent

INDICATOR_METADATA = {
    "taux_chomage_pct": {"label": "taux de chômage", "article": "le", "participe": "estimé", "preposition": "du"},
    "acces_internet_pct": {"label": "accès à Internet", "article": "l'", "participe": "estimé", "preposition": "de l'"},
    "population": {"label": "population", "article": "la", "participe": "estimée", "preposition": "de la"},
    "taux_pauvrete_pct": {"label": "taux de pauvreté", "article": "le", "participe": "estimé", "preposition": "du"},
    "taux_alphabetisation_pct": {"label": "taux d'alphabétisation", "article": "le", "participe": "estimé", "preposition": "du"},
    "taux_urbanisation_pct": {"label": "taux d'urbanisation", "article": "le", "participe": "estimé", "preposition": "du"},
    "taux_scolarisation_pct": {"label": "taux de scolarisation", "article": "le", "participe": "estimé", "preposition": "du"},
    "centres_sante": {"label": "nombre de centres de santé", "article": "le", "participe": "estimé", "preposition": "du"},
    "production_cerealiere_tonnes": {"label": "production céréalière", "article": "la", "participe": "estimée", "preposition": "de la"},
}


def _to_float(value: Any) -> float:
    if value is None:
        return 0.0
    return float(value)


def formater_valeur(value: Any, indicator: str) -> str:
    val = _to_float(value)
    if indicator == "population":
        return f"{int(val):,} habitants".replace(",", " ")
    if indicator == "production_cerealiere_tonnes":
        return f"{int(val):,} tonnes".replace(",", " ")
    if indicator == "centres_sante":
        return str(int(val))
    return f"{val:.1f} %"


def formater_table(data: List[dict], operation: str) -> List[dict]:
    if not data:
        return []

    if operation in ("compare", "ranking"):
        return [
            {"region": row["region"], "valeur": _to_float(row["value"])}
            for row in data
        ]

    if operation == "trend":
        return [
            {"annee": row["annee"], "valeur": _to_float(row["value"])}
            for row in data
        ]

    if operation in ("sum", "average", "value"):
        row = data[0]
        return [{"annee": row["annee"], "valeur": _to_float(row["value"])}]

    return [
        {"annee": row.get("annee"), "valeur": _to_float(row["value"])}
        for row in data
    ]


def formater_chart(
    data: List[dict],
    chart_type: Optional[str],
    indicator: str,
    operation: str,
    year: int,
) -> Optional[dict]:
    if not data or chart_type not in ("bar", "line"):
        return None

    meta = INDICATOR_METADATA.get(indicator, {"label": indicator})
    label = meta["label"].capitalize()

    if operation in ("compare", "ranking", "value", "sum", "average"):
        return {
            "type": "bar",
            "labels": [row["region"] for row in data],
            "datasets": [{
                "label": f"{label} ({year})",
                "data": [_to_float(row["value"]) for row in data],
            }],
        }

    if operation == "trend":
        return {
            "type": "line",
            "labels": [str(row["annee"]) for row in data],
            "datasets": [{
                "label": label,
                "data": [_to_float(row["value"]) for row in data],
            }],
        }

    return None


def formater_reponse(intent: QueryIntent, resultat_brut: dict) -> str:
    data = resultat_brut.get("data", [])
    if not data:
        return resultat_brut.get("title", "Aucune donnée disponible.")

    indicator = intent.indicator or ""
    meta = INDICATOR_METADATA.get(indicator, {
        "label": indicator,
        "article": "le/la",
        "participe": "estimé(e)",
        "preposition": "du/de la"
    })
    
    label = meta["label"]
    article = meta["article"]
    participe = meta["participe"]
    preposition = meta["preposition"]
    
    year = intent.start_year or intent.end_year or 2024

    if intent.operation == "value":
        region = intent.regions[0] if intent.regions else data[0].get("region", "")
        valeur = formater_valeur(data[0]["value"], indicator)
        return (
            f"En {year}, {article} {label} de la région de {region} "
            f"est {participe} à {valeur}."
        )

    if intent.operation == "compare":
        lignes = [
            f"{row['region']} ({formater_valeur(row['value'], indicator)})"
            for row in data
        ]
        details = "\n".join(f"{idx + 1}. {ligne}" for idx, ligne in enumerate(lignes))
        return f"Comparaison pour {article} {label} en {year} :\n{details}"

    if intent.operation == "trend":
        region = intent.regions[0] if intent.regions else data[0].get("region", "")
        debut = formater_valeur(data[0]["value"], indicator)
        fin = formater_valeur(data[-1]["value"], indicator)
        start_year = intent.start_year or data[0]["annee"]
        end_year = intent.end_year or data[-1]["annee"]
        # Capitalize the article for the beginning of the sentence
        article_cap = article.capitalize() if article.endswith("'") else article.capitalize()
        # Handle "L'accès à Internet est passé de..." vs "La population est passée de..."
        passe = "passé" if participe == "estimé" else "passée"
        
        return (
            f"Évolution {preposition} {label} pour la région de {region} entre {start_year} et {end_year} :\n"
            f"{article_cap} {label} est {passe} de {debut} en {start_year} à {fin} en {end_year}."
        )

    if intent.operation == "ranking":
        limit = intent.limit or len(data)
        lignes = [
            f"{row['region']} ({formater_valeur(row['value'], indicator)})"
            for row in data
        ]
        details = "\n".join(f"{idx + 1}. {ligne}" for idx, ligne in enumerate(lignes))
        # Determine if it's "top" or "bottom" based on the sorted data?
        # In Django, ranking is usually ordered descending (top) by default, or ascending if explicitly requested.
        # Let's assume standard top ranking text for now.
        return f"Classement des {limit} régions pour {article} {label} en {year} :\n{details}"

    if intent.operation == "sum":
        return (
            f"La somme totale estimée {preposition} {label} pour l'ensemble du Sénégal en {year} est de "
            f"{formater_valeur(data[0]['value'], indicator)} (basé sur les 14 régions)."
        )

    if intent.operation == "average":
        return (
            f"La moyenne régionale estimée {preposition} {label} pour l'ensemble du Sénégal en {year} est de "
            f"{formater_valeur(data[0]['value'], indicator)} (basé sur les 14 régions)."
        )

    return resultat_brut.get("title", "Voici les résultats demandés.")

    return resultat_brut.get("title", "Voici les résultats demandés.")


def reponse_clarification(message: str) -> dict:
    return {
        "answer": message,
        "table": [],
        "chart": None,
        "metadata": {
            "fictitious": True,
            "rows_used": 0,
            "needs_clarification": True,
        },
    }


def reponse_hors_perimetre(message: str) -> dict:
    return {
        "answer": message,
        "table": [],
        "chart": None,
        "metadata": {
            "fictitious": True,
            "rows_used": 0,
        },
    }


def construire_reponse(intent: QueryIntent, resultat_brut: dict) -> dict:
    data = resultat_brut.get("data", [])
    rows_used = len(data)
    year = intent.start_year or intent.end_year or 2024

    chart_type = resultat_brut.get("chart_type")

    table = formater_table(data, intent.operation)
    chart = formater_chart(data, chart_type, intent.indicator or "", intent.operation, year)
    answer = formater_reponse(intent, resultat_brut)

    return {
        "answer": answer,
        "table": table,
        "chart": chart,
        "metadata": {
            "fictitious": True,
            "rows_used": rows_used,
        },
    }
