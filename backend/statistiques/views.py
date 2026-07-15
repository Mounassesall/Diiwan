import json

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from .formatteur import construire_reponse, reponse_clarification, reponse_hors_perimetre
from .ia_generative import resoudre_intention
from .moteur_orm import generer_donnees
from .models import RegionGeometrie, StatistiqueRegionale
from .validateur import FIELDS_WHITELIST, valider_intention

ANNEES_VALIDES = range(2020, 2025)


class QuestionView(APIView):
    def post(self, request):
        try:
            question_brute = request.data.get("question")
            if not question_brute:
                return Response(
                    {"error": "La clé 'question' est requise."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            
            # Troncature de sécurité pour éviter les requêtes démesurées et les abus du LLM
            question = question_brute[:255]

            intent = resoudre_intention(question)

            erreurs_validation = valider_intention(intent)
            if erreurs_validation:
                return Response(
                    reponse_clarification(
                        "Votre requête contient des paramètres non autorisés."
                    ),
                    status=status.HTTP_200_OK,
                )

            resultat_brut = generer_donnees(intent)

            if resultat_brut.get("is_out_of_scope"):
                return Response(
                    reponse_hors_perimetre(resultat_brut.get("error", "")),
                    status=status.HTTP_200_OK,
                )

            if resultat_brut.get("needs_clarification"):
                return Response(
                    reponse_clarification(resultat_brut.get("error", "")),
                    status=status.HTTP_200_OK,
                )

            return Response(
                construire_reponse(intent, resultat_brut),
                status=status.HTTP_200_OK,
            )

        except Exception:
            return Response(
                {"error": "Une erreur interne est survenue. Veuillez réessayer."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def get(self, request):
        return Response(
            {"error": "Méthode non autorisée. Utilisez POST."},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )


class RegionGeoJSONView(APIView):
    def get(self, request):
        indicator = request.GET.get("indicator", "population")
        annee_param = request.GET.get("annee", "2024")

        if indicator not in FIELDS_WHITELIST:
            return Response(
                {"error": f"Indicateur non autorisé : {indicator}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            annee = int(annee_param)
        except (TypeError, ValueError):
            return Response(
                {"error": "Le paramètre annee doit être un entier."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if annee not in ANNEES_VALIDES:
            return Response(
                {"error": "L'année doit être entre 2020 et 2024."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        stats = {
            row.region: getattr(row, indicator)
            for row in StatistiqueRegionale.objects.filter(annee=annee)
        }

        features = []
        for region_geom in RegionGeometrie.objects.all():
            value = stats.get(region_geom.region)
            properties = {
                "region": region_geom.region,
                "value": float(value) if value is not None else None,
                indicator: float(value) if value is not None else None,
            }
            features.append({
                "type": "Feature",
                "properties": properties,
                "geometry": json.loads(region_geom.geom.geojson),
            })

        payload = {"type": "FeatureCollection", "features": features}
        return Response(payload, content_type="application/json")
