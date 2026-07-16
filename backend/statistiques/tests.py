from django.test import TestCase
from django.core.management import call_command
from django.core.management.base import CommandError
from io import StringIO
import os
import tempfile

from .models import StatistiqueRegionale

class ImporterStatistiquesCommandTest(TestCase):
    def setUp(self):
        self.valid_csv = tempfile.NamedTemporaryFile(delete=False, mode='w', encoding='utf-8-sig', newline='')
        self.valid_csv.write("region,annee,population,taux_urbanisation_pct,taux_alphabetisation_pct,taux_chomage_pct,taux_pauvrete_pct,acces_internet_pct,centres_sante,taux_scolarisation_pct,production_cerealiere_tonnes\n")
        self.valid_csv.write("Dakar,2024,3000000,95.0,85.0,15.0,20.0,90.0,100,98.0,5000\n")
        self.valid_csv.write("Thiès,2024,2000000,50.0,60.0,10.0,30.0,50.0,50,70.0,150000\n")
        self.valid_csv.close()

        self.invalid_csv = tempfile.NamedTemporaryFile(delete=False, mode='w', encoding='utf-8-sig', newline='')
        self.invalid_csv.write("region,annee,population,taux_urbanisation_pct,taux_alphabetisation_pct,taux_chomage_pct,taux_pauvrete_pct,acces_internet_pct,centres_sante,taux_scolarisation_pct,production_cerealiere_tonnes\n")
        self.invalid_csv.write("Fatick,2024,1000000,105.0,60.0,10.0,30.0,50.0,50,70.0,150000\n") 
        self.invalid_csv.close()

    def tearDown(self):
        os.unlink(self.valid_csv.name)
        os.unlink(self.invalid_csv.name)

    def test_import_initial(self):
        out = StringIO()
        call_command('importer_statistiques', self.valid_csv.name, stdout=out)
        self.assertIn('Lignes créées : 2', out.getvalue())
        self.assertEqual(StatistiqueRegionale.objects.count(), 2)

    def test_reimport_sans_doublon(self):
        out1 = StringIO()
        call_command('importer_statistiques', self.valid_csv.name, stdout=out1)
        self.assertEqual(StatistiqueRegionale.objects.count(), 2)

        out2 = StringIO()
        call_command('importer_statistiques', self.valid_csv.name, stdout=out2)
        self.assertIn('Lignes mises à jour : 2', out2.getvalue())
        self.assertEqual(StatistiqueRegionale.objects.count(), 2)

    def test_rejet_ligne_invalide(self):
        out = StringIO()
        call_command('importer_statistiques', self.invalid_csv.name, stdout=out)
        self.assertIn('Lignes rejetées : 1', out.getvalue())
        self.assertEqual(StatistiqueRegionale.objects.count(), 0)

    def test_import_csv_complet_70_lignes(self):
        csv_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "data",
            "donnees_statistiques_senegal_fictives.csv",
        )
        if not os.path.exists(csv_path):
            self.skipTest("Fichier CSV de démonstration introuvable.")

        StatistiqueRegionale.objects.all().delete()
        out = StringIO()
        call_command('importer_statistiques', csv_path, stdout=out)
        self.assertIn('Lignes créées : 70', out.getvalue())
        self.assertEqual(StatistiqueRegionale.objects.count(), 70)

from .analyseur import analyser_question

class TestAnalyseur(TestCase):
    def test_question_simple(self):
        intent = analyser_question("Quelle est la population de Thiès en 2024 ?")
        self.assertEqual(intent.indicator, "population")
        self.assertIn("Thiès", intent.regions)
        self.assertEqual(intent.start_year, 2024)
        self.assertEqual(intent.operation, "value")
        self.assertFalse(intent.needs_clarification)

    def test_comparaison(self):
        intent = analyser_question("Compare le chômage à Dakar et Thiès en 2023.")
        self.assertEqual(intent.indicator, "taux_chomage_pct")
        self.assertIn("Dakar", intent.regions)
        self.assertIn("Thiès", intent.regions)
        self.assertEqual(intent.operation, "compare")

    def test_evolution(self):
        intent = analyser_question("Montre l'évolution de l'accès à internet à Louga entre 2020 et 2024.")
        self.assertEqual(intent.indicator, "acces_internet_pct")
        self.assertIn("Louga", intent.regions)
        self.assertEqual(intent.start_year, 2020)
        self.assertEqual(intent.end_year, 2024)
        self.assertEqual(intent.operation, "trend")

    def test_classement(self):
        intent = analyser_question("Top 3 des régions les plus peuplées")
        self.assertEqual(intent.indicator, "population")
        self.assertEqual(intent.operation, "ranking")
        self.assertEqual(intent.limit, 3)

    def test_agregation(self):
        intent = analyser_question("Population totale du Sénégal en 2024")
        self.assertEqual(intent.indicator, "population")
        self.assertEqual(intent.operation, "sum")

    def test_ambigue(self):
        intent = analyser_question("Quel est le taux de Kolda ?")
        self.assertTrue(intent.needs_clarification)
        self.assertFalse(intent.is_out_of_scope)

    def test_region_inconnue(self):
        intent = analyser_question("Population de Paris")
        # Il trouvera population, mais pas de région. Opération "value" attend une région.
        self.assertTrue(intent.needs_clarification)
        self.assertFalse(intent.is_out_of_scope)

    def test_hors_sujet(self):
        intent = analyser_question("Donne moi la recette du thiéboudienne")
        self.assertTrue(intent.is_out_of_scope)
        self.assertTrue(intent.needs_clarification)

from .moteur_orm import generer_donnees
from django.core.management import call_command

class TestMoteurORM(TestCase):
    @classmethod
    def setUpTestData(cls):
        # On va créer quelques données manuellement plutôt que par CSV pour éviter de dépendre du fichier
        StatistiqueRegionale.objects.create(
            region="Dakar", annee=2024, population=3000000,
            taux_urbanisation_pct=95.0, taux_alphabetisation_pct=85.0,
            taux_chomage_pct=15.0, taux_pauvrete_pct=20.0,
            acces_internet_pct=90.0, centres_sante=100,
            taux_scolarisation_pct=98.0, production_cerealiere_tonnes=5000
        )
        StatistiqueRegionale.objects.create(
            region="Thiès", annee=2024, population=2000000,
            taux_urbanisation_pct=50.0, taux_alphabetisation_pct=60.0,
            taux_chomage_pct=10.0, taux_pauvrete_pct=30.0,
            acces_internet_pct=50.0, centres_sante=50,
            taux_scolarisation_pct=70.0, production_cerealiere_tonnes=150000
        )

    def test_generer_donnees_value(self):
        intent = analyser_question("Population de Dakar en 2024")
        res = generer_donnees(intent)
        self.assertIsNone(res["chart_type"])
        self.assertEqual(len(res["data"]), 1)
        self.assertEqual(res["data"][0]["value"], 3000000)

    def test_generer_donnees_compare(self):
        intent = analyser_question("Compare la population de Dakar et Thiès en 2024")
        res = generer_donnees(intent)
        self.assertEqual(res["chart_type"], "bar")
        self.assertEqual(len(res["data"]), 2)

    def test_generer_donnees_ranking(self):
        intent = analyser_question("Top 2 des régions les plus peuplées en 2024")
        res = generer_donnees(intent)
        self.assertEqual(res["chart_type"], "bar")
        self.assertEqual(len(res["data"]), 2)
        self.assertEqual(res["data"][0]["region"], "Dakar")

    def test_generer_donnees_sum(self):
        intent = analyser_question("Population totale au Sénégal en 2024")
        res = generer_donnees(intent)
        self.assertEqual(res["data"][0]["value"], 5000000)

    def test_generer_donnees_hors_sujet(self):
        intent = analyser_question("Recette de cuisine")
        res = generer_donnees(intent)
        self.assertTrue(res.get("needs_clarification"))
        self.assertIn("error", res)

    def test_generer_donnees_faille_get(self):
        intent = QueryIntent(indicator="champ_inexistant_xyz", regions=["Dakar"], operation="value")
        with self.assertRaises(ValueError) as context:
            generer_donnees(intent)
        self.assertTrue("Indicateur non autorisé : champ_inexistant_xyz" in str(context.exception))

from .validateur import valider_intention
from .analyseur import QueryIntent

class TestValidateur(TestCase):
    def test_valider_intention_succes(self):
        intent = QueryIntent(indicator="population", regions=["Dakar"], operation="value")
        erreurs = valider_intention(intent)
        self.assertEqual(len(erreurs), 0)

    def test_valider_intention_echec(self):
        intent = QueryIntent(indicator="champ_hack", regions=["Paris"], operation="delete")
        erreurs = valider_intention(intent)
        self.assertEqual(len(erreurs), 3)
        self.assertIn("Indicateur non autorisé : champ_hack", erreurs)

    def test_valider_annees(self):
        intent = QueryIntent(
            indicator="population",
            regions=["Dakar"],
            operation="value",
            start_year=2019,
            end_year=2025,
        )
        erreurs = valider_intention(intent)
        self.assertEqual(len(erreurs), 2)

from rest_framework.test import APITestCase
from django.urls import reverse

class TestQuestionView(APITestCase):
    @classmethod
    def setUpTestData(cls):
        StatistiqueRegionale.objects.create(
            region="Dakar", annee=2024, population=3000000,
            taux_urbanisation_pct=95.0, taux_alphabetisation_pct=85.0,
            taux_chomage_pct=15.0, taux_pauvrete_pct=20.0,
            acces_internet_pct=90.0, centres_sante=100,
            taux_scolarisation_pct=98.0, production_cerealiere_tonnes=5000
        )
        StatistiqueRegionale.objects.create(
            region="Thiès", annee=2024, population=2000000,
            taux_urbanisation_pct=50.0, taux_alphabetisation_pct=60.0,
            taux_chomage_pct=10.0, taux_pauvrete_pct=30.0,
            acces_internet_pct=50.0, centres_sante=50,
            taux_scolarisation_pct=70.0, production_cerealiere_tonnes=150000
        )
        StatistiqueRegionale.objects.create(
            region="Saint-Louis", annee=2024, population=1000000,
            taux_urbanisation_pct=40.0, taux_alphabetisation_pct=55.0,
            taux_chomage_pct=12.0, taux_pauvrete_pct=35.0,
            acces_internet_pct=40.0, centres_sante=30,
            taux_scolarisation_pct=65.0, production_cerealiere_tonnes=80000
        )

    def test_post_valid_question(self):
        url = reverse('question')
        response = self.client.post(url, {"question": "Quelle est la population de Dakar en 2024 ?"}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn("answer", response.data)
        self.assertIn("table", response.data)
        self.assertIn("chart", response.data)
        self.assertIn("metadata", response.data)
        self.assertTrue(response.data["metadata"]["fictitious"])
        self.assertEqual(response.data["metadata"]["rows_used"], 1)
        self.assertIsNone(response.data["chart"])

    def test_post_comparaison_graphique(self):
        url = reverse('question')
        response = self.client.post(
            url,
            {"question": "Compare le chômage à Dakar, Thiès et Saint-Louis en 2024."},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["chart"]["type"], "bar")
        self.assertEqual(len(response.data["chart"]["labels"]), 3)
        self.assertEqual(len(response.data["chart"]["datasets"][0]["data"]), 3)

    def test_post_ambigue(self):
        url = reverse('question')
        response = self.client.post(url, {"question": "Quel est le taux de Kolda ?"}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["metadata"]["needs_clarification"])
        self.assertEqual(response.data["table"], [])
        self.assertIsNone(response.data["chart"])

    def test_post_missing_question(self):
        url = reverse('question')
        response = self.client.post(url, {}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.data)

    def test_post_out_of_scope(self):
        url = reverse('question')
        response = self.client.post(url, {"question": "recette de cuisine"}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn("answer", response.data)
        self.assertEqual(response.data["answer"], "Désolé, je ne réponds qu'aux questions sur les statistiques régionales du Sénégal.")
        self.assertTrue(response.data["metadata"]["fictitious"])

    def test_get_not_allowed(self):
        url = reverse('question')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 405)


DEMO_QUESTIONS = [
    ("Quelle est la population de Thiès en 2024 ?", "value"),
    ("Compare le chômage à Dakar, Thiès et Saint-Louis en 2024.", "compare"),
    ("Montre l'évolution de l'accès à Internet à Kaolack entre 2020 et 2024.", "trend"),
    ("Quelles sont les cinq régions les plus peuplées en 2024 ?", "ranking"),
    ("Quelle est la population totale estimée du Sénégal en 2024 ?", "sum"),
]


class TestDemoQuestions(APITestCase):
    @classmethod
    def setUpTestData(cls):
        csv_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "data",
            "donnees_statistiques_senegal_fictives.csv",
        )
        if os.path.exists(csv_path):
            call_command('importer_statistiques', csv_path, stdout=StringIO())

    def test_cinq_questions_demonstration(self):
        url = reverse('question')
        for question, operation_attendue in DEMO_QUESTIONS:
            with self.subTest(question=question):
                response = self.client.post(url, {"question": question}, format='json')
                self.assertEqual(response.status_code, 200, msg=question)
                self.assertIn("answer", response.data)
                self.assertTrue(response.data["metadata"]["fictitious"])
                if operation_attendue in ("compare", "trend", "ranking"):
                    self.assertIsNotNone(response.data["chart"], msg=question)
                    self.assertEqual(response.data["chart"]["type"], "bar" if operation_attendue != "trend" else "line")


class TestRegionGeoJSONView(APITestCase):
    @classmethod
    def setUpTestData(cls):
        StatistiqueRegionale.objects.create(
            region="Dakar", annee=2024, population=3000000,
            taux_urbanisation_pct=95.0, taux_alphabetisation_pct=85.0,
            taux_chomage_pct=15.0, taux_pauvrete_pct=20.0,
            acces_internet_pct=90.0, centres_sante=100,
            taux_scolarisation_pct=98.0, production_cerealiere_tonnes=5000
        )

    def test_geojson_avec_indicateur(self):
        url = reverse('regions_geojson')
        response = self.client.get(url, {"indicator": "population", "annee": 2024})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["type"], "FeatureCollection")

    def test_geojson_indicateur_invalide(self):
        url = reverse('regions_geojson')
        response = self.client.get(url, {"indicator": "hack_field", "annee": 2024})
        self.assertEqual(response.status_code, 400)
