#!/usr/bin/env bash
# build.sh — Script de déploiement Render
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate

# Charger les données fictives au premier déploiement
python manage.py loaddata statistiques/fixtures/initial_data.json 2>/dev/null || echo "Fixtures déjà chargées ou absentes — OK"
