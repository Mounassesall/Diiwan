import json
from django.core.management.base import BaseCommand, CommandError
from django.contrib.gis.geos import GEOSGeometry, MultiPolygon, Polygon
from statistiques.models import RegionGeometrie

class Command(BaseCommand):
    help = 'Importe les données géospatiales des régions depuis un fichier GeoJSON'

    def add_arguments(self, parser):
        parser.add_argument('geojson_path', type=str, help='Le chemin vers le fichier GeoJSON')

    def handle(self, *args, **kwargs):
        geojson_path = kwargs['geojson_path']

        try:
            with open(geojson_path, mode='r', encoding='utf-8-sig') as f:
                data = json.load(f)

            if 'features' not in data:
                raise CommandError("Le fichier GeoJSON ne contient pas de 'features'.")

            created_count = 0
            updated_count = 0

            for feature in data['features']:
                props = feature.get('properties', {})
                region_name = props.get('NAME_1') or props.get('name') or props.get('ADM1_FR') or props.get('NAME')
                
                if not region_name:
                    continue 

                geom_str = json.dumps(feature['geometry'])
                geom = GEOSGeometry(geom_str)
                
                if isinstance(geom, Polygon):
                    geom = MultiPolygon(geom)

                obj, created = RegionGeometrie.objects.update_or_create(
                    region=region_name,
                    defaults={'geom': geom}
                )

                if created:
                    created_count += 1
                else:
                    updated_count += 1

        except FileNotFoundError:
            raise CommandError(f"Le fichier {geojson_path} est introuvable.")
        except Exception as e:
            raise CommandError(f"Erreur lors de l'importation : {str(e)}")

        self.stdout.write(self.style.SUCCESS(f"Importation géographique terminée !"))
        self.stdout.write(f"Régions créées : {created_count}")
        self.stdout.write(f"Régions mises à jour : {updated_count}")
