import csv
from django.core.management.base import BaseCommand, CommandError
from statistiques.models import StatistiqueRegionale

class Command(BaseCommand):
    help = 'Importe les données statistiques depuis un fichier CSV'

    def add_arguments(self, parser):
        parser.add_argument('csv_path', type=str, help='Le chemin vers le fichier CSV')

    def handle(self, *args, **kwargs):
        csv_path = kwargs['csv_path']
        
        required_columns = {
            'region', 'annee', 'population', 'taux_urbanisation_pct',
            'taux_alphabetisation_pct', 'taux_chomage_pct', 'taux_pauvrete_pct',
            'acces_internet_pct', 'centres_sante', 'taux_scolarisation_pct',
            'production_cerealiere_tonnes'
        }

        created_count = 0
        updated_count = 0
        rejected_count = 0
        rejection_reasons = []

        try:
            with open(csv_path, mode='r', encoding='utf-8-sig') as file:
                reader = csv.DictReader(file)
                
                if not reader.fieldnames or not required_columns.issubset(set(reader.fieldnames)):
                    missing = required_columns - set(reader.fieldnames or [])
                    raise CommandError(f"Colonnes manquantes dans le CSV : {', '.join(missing)}")

                for row_num, row in enumerate(reader, start=2):
                    try:
                        annee = int(row['annee'])
                        if not (2020 <= annee <= 2024):
                            raise ValueError(f"L'année doit être entre 2020 et 2024 (valeur: {annee})")

                        pct_fields = [
                            'taux_urbanisation_pct', 'taux_alphabetisation_pct',
                            'taux_chomage_pct', 'taux_pauvrete_pct',
                            'acces_internet_pct', 'taux_scolarisation_pct'
                        ]
                        for field in pct_fields:
                            val = float(row[field])
                            if not (0 <= val <= 100):
                                raise ValueError(f"Le champ {field} doit être entre 0 et 100 (valeur: {val})")

                        defaults = {
                            'population': int(row['population']),
                            'taux_urbanisation_pct': float(row['taux_urbanisation_pct']),
                            'taux_alphabetisation_pct': float(row['taux_alphabetisation_pct']),
                            'taux_chomage_pct': float(row['taux_chomage_pct']),
                            'taux_pauvrete_pct': float(row['taux_pauvrete_pct']),
                            'acces_internet_pct': float(row['acces_internet_pct']),
                            'centres_sante': int(row['centres_sante']),
                            'taux_scolarisation_pct': float(row['taux_scolarisation_pct']),
                            'production_cerealiere_tonnes': int(row['production_cerealiere_tonnes']),
                        }

                        obj, created = StatistiqueRegionale.objects.update_or_create(
                            region=row['region'],
                            annee=annee,
                            defaults=defaults
                        )

                        if created:
                            created_count += 1
                        else:
                            updated_count += 1

                    except Exception as e:
                        rejected_count += 1
                        rejection_reasons.append(f"Ligne {row_num}: {str(e)}")

        except FileNotFoundError:
            raise CommandError(f"Le fichier {csv_path} est introuvable.")
        
        self.stdout.write(self.style.SUCCESS(f"Import terminé !"))
        self.stdout.write(f"Lignes créées : {created_count}")
        self.stdout.write(f"Lignes mises à jour : {updated_count}")
        self.stdout.write(self.style.ERROR(f"Lignes rejetées : {rejected_count}"))
        
        for reason in rejection_reasons:
            self.stdout.write(self.style.WARNING(f" - {reason}"))
