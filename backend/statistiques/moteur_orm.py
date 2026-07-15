from django.db.models import Sum, Avg
from .models import StatistiqueRegionale
from .analyseur import QueryIntent

def generer_donnees(intent: QueryIntent) -> dict:
    if intent.is_out_of_scope:
        return {
            "error": intent.clarification_message,
            "is_out_of_scope": True,
            "needs_clarification": True
        }
        
    if intent.needs_clarification:
        return {
            "error": intent.clarification_message,
            "needs_clarification": True
        }

    indicator = intent.indicator
    start_year = intent.start_year or 2024
    end_year = intent.end_year or 2024
    regions = intent.regions
    
    data = []
    title = ""
    chart_type = intent.chart_type or "bar"
    
    # Mapping strict des champs autorisés pour la sécurité (évite les injections dans order_by ou aggregate)
    SAFE_INDICATORS = {
        "taux_chomage_pct": "taux_chomage_pct",
        "acces_internet_pct": "acces_internet_pct",
        "population": "population",
        "taux_pauvrete_pct": "taux_pauvrete_pct",
        "taux_alphabetisation_pct": "taux_alphabetisation_pct",
        "taux_urbanisation_pct": "taux_urbanisation_pct",
        "taux_scolarisation_pct": "taux_scolarisation_pct",
        "centres_sante": "centres_sante",
        "production_cerealiere_tonnes": "production_cerealiere_tonnes"
    }

    if indicator not in SAFE_INDICATORS:
        raise ValueError(f"Indicateur non autorisé : {indicator}")
    safe_indicator = SAFE_INDICATORS[indicator]
    
    # Mapping des noms d'indicateurs pour un titre lisible
    noms_indicateurs = {
        "taux_chomage_pct": "Taux de chômage (%)",
        "acces_internet_pct": "Accès à internet (%)",
        "population": "Population",
        "taux_pauvrete_pct": "Taux de pauvreté (%)",
        "taux_alphabetisation_pct": "Taux d'alphabétisation (%)",
        "taux_urbanisation_pct": "Taux d'urbanisation (%)",
        "taux_scolarisation_pct": "Taux de scolarisation (%)",
        "centres_sante": "Nombre de centres de santé",
        "production_cerealiere_tonnes": "Production céréalière (tonnes)"
    }
    ind_label = noms_indicateurs.get(indicator, indicator)

    try:
        if intent.operation == "trend":
            qs = StatistiqueRegionale.objects.filter(annee__gte=start_year, annee__lte=end_year)
            if regions:
                qs = qs.filter(region__in=regions)
            qs = qs.order_by('annee')
            
            for item in qs:
                data.append({
                    "region": item.region,
                    "annee": item.annee,
                    "value": getattr(item, indicator)
                })
            regs = ", ".join(regions) if regions else "le Sénégal"
            title = f"Évolution : {ind_label} ({regs})"
            chart_type = "line"
            
        elif intent.operation == "compare":
            qs = StatistiqueRegionale.objects.filter(annee=start_year, region__in=regions)
            for item in qs:
                data.append({
                    "region": item.region,
                    "annee": item.annee,
                    "value": getattr(item, indicator)
                })
            title = f"Comparaison : {ind_label} en {start_year}"
            chart_type = "bar"
            
        elif intent.operation == "ranking":
            limit = intent.limit or 5
            qs = StatistiqueRegionale.objects.filter(annee=start_year).order_by(f"-{safe_indicator}")[:limit]
            for item in qs:
                data.append({
                    "region": item.region,
                    "annee": item.annee,
                    "value": getattr(item, safe_indicator)
                })
            title = f"Top {limit} : {ind_label} en {start_year}"
            chart_type = "bar"
            
        elif intent.operation == "sum":
            res = StatistiqueRegionale.objects.filter(annee=start_year).aggregate(total=Sum(safe_indicator))
            data.append({
                "region": "National",
                "annee": start_year,
                "value": res['total']
            })
            title = f"Total national : {ind_label} en {start_year}"
            chart_type = "bar" # Pas très utile, mais valeur par défaut

        elif intent.operation == "average":
            res = StatistiqueRegionale.objects.filter(annee=start_year).aggregate(moyenne=Avg(safe_indicator))
            data.append({
                "region": "National",
                "annee": start_year,
                "value": round(res['moyenne'], 2) if res['moyenne'] else 0
            })
            title = f"Moyenne nationale : {ind_label} en {start_year}"
            chart_type = "bar"
            
        else: # "value"
            qs = StatistiqueRegionale.objects.filter(annee=start_year)
            if regions:
                qs = qs.filter(region__in=regions)
            for item in qs:
                data.append({
                    "region": item.region,
                    "annee": item.annee,
                    "value": getattr(item, indicator)
                })
            regs = ", ".join(regions) if regions else "le Sénégal"
            title = f"{ind_label} : {regs} ({start_year})"
            
        return {
            "title": title,
            "data": data,
            "chart_type": chart_type,
            "source": "Données fictives - Projet Diiwan"
        }
    except Exception as e:
        return {
            "error": f"Erreur lors de la récupération des données : {str(e)}",
            "needs_clarification": True
        }
