from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.serializers import serialize
from django.http import HttpResponse
from .models import RegionGeometrie
from .analyseur import analyser_question
from .moteur_orm import generer_donnees
from .ia_generative import generer_analyse_ia
from .validateur import valider_intention

class QuestionView(APIView):
    def post(self, request):
        try:
            question = request.data.get("question")
            if not question:
                return Response({"error": "La clé 'question' est requise."}, status=status.HTTP_400_BAD_REQUEST)

            intent = analyser_question(question)
            
            # Validation stricte des attributs extraits
            erreurs_validation = valider_intention(intent)
            if erreurs_validation:
                return Response({
                    "answer": "Votre requête contient des paramètres non autorisés.",
                    "needs_clarification": True,
                    "erreurs": erreurs_validation
                }, status=status.HTTP_400_BAD_REQUEST)
        
            # 2. Exécution de la requête en base de données
            resultat_brut = generer_donnees(intent)
            
            # Gestion des cas hors périmètre ou ambigus
            if resultat_brut.get("is_out_of_scope"):
                return Response({
                    "answer": resultat_brut.get("error")
                }, status=status.HTTP_200_OK)

            if resultat_brut.get("needs_clarification"):
                return Response({
                    "needs_clarification": True,
                    "clarification_message": resultat_brut.get("error")
                }, status=status.HTTP_200_OK)
                
            # 3. Interprétation par l'IA Générative
            analyse = generer_analyse_ia(question, resultat_brut)
            
            # 4. Format JSON exact demandé (answer/table/chart/metadata)
            return Response({
                "answer": analyse,
                "table": resultat_brut.get("data", []),
                "chart": {
                    "type": resultat_brut.get("chart_type"),
                    "data": resultat_brut.get("data", [])
                },
                "metadata": {
                    "source": resultat_brut.get("source", "Données fictives - Projet Diiwan"),
                    "title": resultat_brut.get("title", ""),
                    "intent": {
                        "indicator": intent.indicator,
                        "regions": intent.regions,
                        "operation": intent.operation
                    }
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            # Sécurité: masquer la trace technique à l'utilisateur
            return Response({"error": "Une erreur interne est survenue. Veuillez réessayer."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class RegionGeoJSONView(APIView):
    def get(self, request):
        qs = RegionGeometrie.objects.all()
        geojson_data = serialize('geojson', qs, geometry_field='geom', fields=('region',))
        return HttpResponse(geojson_data, content_type="application/json")
